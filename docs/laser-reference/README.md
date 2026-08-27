# Gravação laser Diatu — referência

Substitui etiquetas Zebra por gravação permanente do serial ITF na carcaça da sirene.

No **posto de produção** o gatilho físico é o **pedal** (não a tecla F2). O software do laser pode mapear o pedal ao mesmo ciclo de gravação; a UI do app orienta o operador a acionar o pedal.

## Glossário

| Nome | Significado |
|------|-------------|
| **Diaotu** | Marca/modelo do laser (ex. B3 fibra). Menus do equipamento (“Marca de controlo TCP”) usam este nome. |
| **DiatuCAD** | Software de job no PC; cliente TCP que pede o serial ao app (no posto o gatilho é o **pedal**). |
| **Diatu*** (app) | Classes/APIs no `sirene_app` (`DiatuLaserTcpServer`, etc.) e capability OpenSpec `diatu-laser-marking`. |

Não confundir Diaotu (hardware) com Diatu/DiatuCAD (software/API): não é typo.

## Documentos

| Arquivo | Conteúdo |
|---------|----------|
| [diatu-tcp.md](./diatu-tcp.md) | Protocolo TCP servidor/cliente com DiatuCAD |

## Homologação (operador)

### 0.1 Equipamento confirmado

- Laser **Diaotu B3** (fibra)
- Software **DiatuCAD1** com menu **Controlo TCP(T)**
- Placa de controle conectada via USB (sair do modo demonstração)

### 0.2 Template de gravação

1. Criar job com **DataMatrix** alimentado por TCP (`TCP: Give me string`) — ver [diatu-tcp.md](./diatu-tcp.md#job-com-datamatrix--texto-do-modelo).
2. Adicionar **texto do modelo** com TCP (`TCP: model`) se quiser nome dinâmico do produto.
3. Validar que dois objetos TCP com comandos distintos funcionam no mesmo job (F2).
4. Ajustar tamanho do DataMatrix e fonte do texto para legibilidade na carcaça ABS.

### 0.3 Validação física

- Gravar serial de teste (`0000000000` via Configurações).
- Verificar contraste e leitura visual a 30 cm.
- Documentar potência/velocidade finais no job salvo.

## Troubleshooting

Sintomas comuns e soluções: [diatu-tcp.md](./diatu-tcp.md#troubleshooting).

Resumo:
- `ERROR:BADCMD` → comando TCP diferente entre app e DiatuCAD
- Porta em uso → desativar **Marca de controlo TCP** no Diaotu
- Use o painel **Diagnóstico laser** em Configurações (log + Simular serial / Simular modelo)

## Posto

Fluxo padrão: app enfileira serial na `mark_queue` → DiatuCAD solicita via TCP → operador aciona **F2**.

Referência histórica de etiquetas Zebra (obsoleta): [`docs/label-reference/`](../label-reference/README.md).
