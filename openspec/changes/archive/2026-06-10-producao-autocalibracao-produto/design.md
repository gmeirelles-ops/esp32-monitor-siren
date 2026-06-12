## Context

O ecossistema Diponto Sirene Validator está em v1.1.1 com firmware endurecido (OTA, telemetria, offline, TWDT) e app Flutter companion funcional. O fluxo de lote exige que o operador digite manualmente `potencia_min` e `potencia_max` — valores que deveriam vir do cadastro técnico de cada SKU.

O firmware já implementa `START_CALIBRATION`: aciona o relé por 5 s, mede via PZEM e publica apenas a **média final** em `sirene/<id>/calibracao`. O app expõe isso na tela Admin, desconectado de qualquer cadastro. Não existe tabela de produtos no SQLite.

A spec original (`calibration-mode`) previa calibração "pela interface de cadastro de produtos", mas essa interface nunca foi implementada.

## Goals / Non-Goals

**Goals:**

- Colocar o sistema em produção com fluxo operacional completo: cadastrar produto → autocalibrar → configurar lote → testar → etiquetar.
- Cadastro de produto com autocalibração: medir peça padrão, ver leituras ao vivo, calcular min/max automaticamente.
- Reutilizar limites cadastrados em todo `SET_BATCH` sem redigitação.
- Manter firmware como fonte única de medição (PZEM); app apenas orquestra e persiste.

**Non-Goals:**

- Sincronização do catálogo com Firebase (fase 2).
- Calibração multi-amostra estatística (média de N peças) — uma medição por cadastro é suficiente na v1.
- Alterar contrato `SET_BATCH` no firmware.
- TLS/auth MQTT nesta change.

## Decisions

### 1. Catálogo local em SQLite (Drift)

Tabela `products`:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id_produto` | TEXT PK | 3 dígitos, zero-padded |
| `nome` | TEXT | Nome legível (ex.: "Sirene 12V modelo X") |
| `potencia_ref` | REAL | Média da autocalibração (W) |
| `potencia_min` | REAL | Limite inferior derivado |
| `potencia_max` | REAL | Limite superior derivado |
| `tolerancia_pct` | REAL | Tolerância usada no cálculo (padrão 10%) |
| `tempo_teste_sec` | INT | Duração do ciclo (padrão 5) |
| `calibrado_em` | DATETIME | Timestamp da última calibração |
| `calibrado_device_id` | TEXT | Dispositivo usado na medição |

**Rationale:** SQLite já existe no app; offline-first na fábrica; sem dependência de nuvem.

### 2. Fórmula de min/max a partir da referência

```
potencia_min = potencia_ref × (1 − tolerancia_pct / 100)
potencia_max = potencia_ref × (1 + tolerancia_pct / 100)
```

Arredondamento: 2 casas decimais. Tolerância padrão **10%**, editável pelo operador antes de salvar (ex.: 20,0 W ±10% → min 18,0 / max 22,0).

**Alternativa descartada:** tolerância absoluta em watts (±2 W) — menos intuitiva para produtos com potências muito diferentes.

O operador pode ajustar manualmente min/max após o cálculo automático antes de confirmar o cadastro.

### 3. Amostras de calibração em tempo real (firmware)

Durante `START_CALIBRATION`, o firmware publica a cada **500 ms** (após descarte de inrush):

```json
{"tipo":"calibracao_amostra","potencia_w":20.1,"elapsed_ms":1500}
```

Ao final, mantém a mensagem existente:

```json
{"tipo":"calibracao","potencia_media":20.15}
```

Implementação: refatorar `pzem_measure_cycle` para aceitar callback de amostra, ou loop dedicado em `handle_start_calibration` com `mqtt_bridge_publish("calibracao", ...)`.

**Alternativa descartada:** novo tópico `calibracao_stream` — reutilizar `calibracao` com campo `tipo` mantém subscribe existente.

### 4. UI de cadastro de produto

Nova tela **Produtos** na navegação principal (entre Lote e Etiquetas):

1. Formulário: id_produto (3 dígitos), nome, tolerância %, tempo de teste
2. Seletor de dispositivo (deve estar `IDLE`)
3. Botão **"Medir peça padrão"** → envia `START_CALIBRATION`
4. Painel ao vivo: última amostra, gráfico sparkline das amostras, barra de progresso 5 s
5. Ao receber `calibracao` final: preenche ref/min/max, operador confirma e salva

Re-calibrar produto existente: botão "Recalibrar" sobrescreve `potencia_ref` e limites.

### 5. Integração com lote

`batch_screen.dart`:

- Dropdown de produtos cadastrados (substitui campos manuais de id, min, max, tempo)
- Campos manuais de min/max ficam **somente leitura** (preenchidos pelo produto)
- Operador informa: dispositivo, OP, ano, quantidade, sequencial
- `SET_BATCH` montado a partir do produto selecionado

### 6. Admin sem calibração

Remover seção de calibração de `admin_screen.dart`. Admin fica apenas com OTA.

Atualizar spec `calibration-and-ota`: calibração no cadastro de produtos; OTA no Admin.

### 7. Versão firmware 1.2.0

Bump `FIRMWARE_VERSION` para refletir novo contrato de amostras de calibração. Compatível com app antigo (mensagem final inalterada).

### 8. Checklist de produção

Documentar em `docs/PRODUCAO.md`:

1. Compilar firmware com `MQTT_BROKER_URI` correto para a rede da fábrica
2. Flash inicial por cabo (layout OTA)
3. Provisionar Wi-Fi de cada bancada
4. Instalar Mosquitto no servidor LAN
5. Build Windows do app (`flutter build windows --release`)
6. Cadastrar cada SKU com peça padrão na bancada
7. Validar ciclo completo: lote → teste → serial → etiqueta
8. Scripts de bancada (`bench_*.sh`) como smoke test

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Amostras MQTT aumentam tráfego durante calibração (~10 msgs/5s) | Aceitável em LAN; QoS 0 para amostras, QoS 1 para média final |
| Uma única medição pode não representar variação do SKU | Operador pode recalibrar; tolerância % ajustável |
| Dispositivo em `BATCH_READY` bloqueia calibração | Cadastro exige `IDLE`; instruir encerrar lote antes |
| App Windows não builda no Linux | CI ou máquina Windows no posto (já documentado) |
| Produto cadastrado em bancada A, lote em bancada B | Limites são do produto, não do dispositivo — OK se PZEMs calibrados |

## Migration Plan

1. **Firmware:** gravar v1.2.0 em todas as bancadas (cabo ou OTA a partir de v1.1.1).
2. **App:** instalar nova versão Windows; migração SQLite v1→v2 adiciona tabela `products` sem perder dados existentes.
3. **Operação:** cadastrar todos os SKUs ativos antes de iniciar produção; lotes antigos em andamento não são afetados.
4. **Rollback:** firmware 1.1.1 ignora amostras desconhecidas; app antigo ainda funciona com min/max manual.

## Open Questions

- ~~Tolerância padrão de 10%~~ **Confirmado:** 10% é o padrão para todos os SKUs Diponto; permanece editável por produto no cadastro.
- Cadastro de produto deve exigir confirmação de administrador ou qualquer operador pode cadastrar? (Resposta provisória: qualquer operador — sem auth nesta fase.)
