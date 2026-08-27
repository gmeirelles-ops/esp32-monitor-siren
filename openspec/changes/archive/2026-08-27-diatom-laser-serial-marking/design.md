## Context

Fluxo atual após aprovação MQTT:

```
teste APROVADO → generateFullSerial() → buffer SQLite → ZPL Zebra (×3) → operador cola etiqueta
```

O laser Diatom grava direto no plástico/metal da sirene. Equipamentos similares no mercado brasileiro (EzCad, Horus, PRO Marking) expõem **TCP/IP** ou RS-232 para campos variáveis. O protocolo exato da Diatom deve ser confirmado com manual/placa do equipamento — a arquitetura abstrai o transporte.

**Restrições existentes:**
- Serial ITF 10 dígitos permanece (produto+ano+seq+DV).
- SQLite continua source of truth; Firestore sync inalterado.
- Windows desktop no posto.
- Um posto = um modo de marcação (não misturar Zebra e laser no mesmo fluxo automático).

## Goals / Non-Goals

**Goals:**

- Gravar serial aprovado no laser **automaticamente** após geração (ou enfileirar se offline).
- Configurar host/porta/comando TCP nas Configurações.
- Teste de gravação com serial fictício.
- Regravação manual de serial do histórico.
- Modo etiqueta Zebra preservado como opção.

**Non-Goals:**

- Substituir software de layout do laser (EzCad/Diatom) — template criado uma vez no PC do laser.
- Controle de eixo/portal automático ou I/O de segurança NR-12.
- Gravação de código de barras 2D na v1 (opcional futuro se template suportar).
- Marcação durante reteste (reteste não gera serial — comportamento atual mantido).

## Decisions

### 1. Modo de marcação por posto

```dart
enum MarkingMode { labels, laser }
```

Persistido em `SharedPreferences`. Quando `laser`, pipeline ZPL (`_maybePrintLabels`, buffer múltiplo de 3) **não** é acionado.

**Alternativa:** usar Zebra e laser em paralelo — rejeitada (operador confuso, dupla marcação).

### 2. Abstração de backend

```
SerialMarkingBackend
├── ZplLabelBackend      (existente: USB RAW / TCP 9100)
└── DiatomLaserBackend   (novo: TCP cliente)
```

Factory `createSerialMarkingBackend(AppConfig)` espelha `createLabelPrinterTransport`.

### 3. Integração TCP Diatom (v1)

**Decisão:** cliente TCP configurável enviando payload ASCII/JSON conforme template documentado em `docs/laser-reference/diatom-tcp.md`.

Fluxo típico (a validar com manual):

1. App conecta `laser_host:laser_port` (ex.: IP do PC controlador ou controlador embarcado).
2. Envia comando com serial: ex. `MARK;SERIAL=1232600018\n` ou JSON `{"serial":"1232600018"}`.
3. Controlador atualiza campo variável do job `.ezd`/`.dat` e dispara gravação (ou aguarda botão físico do operador).

**Alternativa:** arquivo CSV drop na pasta compartilhada — rejeitada para v1 (frágil, race conditions).

**Alternativa:** simular teclado (keyboard wedge) — rejeitada (não confiável em produção).

### 4. Fila de gravação local

Tabela `mark_queue` (ou reutilizar `label_buffer_entries` renomeada — **decisão:** nova tabela `mark_queue` para clareza):

| Campo | Descrição |
|-------|-----------|
| serial | ITF completo |
| numero_op | OP |
| status | pending / sent / failed |
| attempts | retries |
| last_error | nullable |
| created_at | timestamp |

Worker processa pendentes ao aprovar e periodicamente (timer 10 s).

### 5. Fluxo operacional no posto

```
[Bancada teste]  operador pressiona botão → aprovação MQTT
       ↓
[App] gera serial → enfileira gravação → envia TCP ao laser
       ↓
[Estação laser] operador posiciona sirene → aciona gravação (app ou botão máquina)
       ↓
[App] marca fila como concluída; falha mantém retry
```

Se laser fica ao lado da bancada, operador pode gravar imediatamente após teste.

### 6. UI

- **Configurações:** seção "Gravação laser" — modo, IP, porta, botão "Testar gravação".
- **Gravação** (renomear/duplicar Etiquetas quando modo laser): fila pendente, histórico recente, regravação.
- Badge de falha similar a `printFailureProvider`.

### 7. Homologação física (fase 0)

Antes de codificar protocolo final:

1. Obter manual Diatom / contato suporte.
2. Criar template com campo `serial` (fonte legível, tamanho fixo).
3. Testar gravação manual + TCP com serial variável.
4. Documentar comando exato em `docs/laser-reference/`.

## Risks / Trade-offs

- **[Protocolo desconhecido]** → fase 0 de homologação; backend com `commandTemplate` configurável.
- **[Material da sirene]** → plástico ABS pode exigir potência/velocidade diferentes; fora do app.
- **[Ciclo mais lento que etiqueta]** → uma peça por vez; aceitável se elimina colagem.
- **[Laser offline]** → fila local; operador vê pendências.

## Migration Plan

1. Homologar TCP com laser Diatom (fase 0, sem app).
2. Implementar backend + modo config (feature flag implícita via MarkingMode).
3. Piloto em um posto; Zebra permanece em outros.
4. Rollback: voltar MarkingMode para `labels` nas Configurações.

## Open Questions

- Modelo exato Diatom e software (EzCad? proprietário?) — **obter do usuário**.
- IP/porta e formato de comando TCP oficiais.
- Gravação dispara automaticamente via TCP ou só carrega serial e operador aperta pedal?
- Incluir código Data Matrix/QR além do serial legível?
- Posição fixa da gravação na carcaça (fixture) — impacto no template, não no app.
