## Why

Na bancada, seriais gravados pelo laser **permanecem na tela Gravação** após o F2. A confirmação da fila (`delivered`) hoje depende do ciclo TCP completo: serial → modelo → **manual** (se o produto tiver o campo preenchido). Se o job DiatuCAD só pede serial (ou não pede a última variável), a peça é marcada fisicamente, mas o item fica `in_progress` e reaparece como `pending` após timeout.

O campo **Manual do produto** e o comando TCP `TCP: manual` não serão usados no posto no momento — complicam o ciclo sem benefício operacional.

## What Changes

- **Confirmar gravação no pedido do serial (opção B):** ao atender `TCP: Give me string`, marcar a entrada como `delivered` imediatamente e removê-la da UI da fila.
- Pedido de **modelo** (`TCP: model`) continua respondendo com `Products.nome`, mas **não** controla o status da fila.
- **Remover** do fluxo operacional o campo `Products.manual`, o comando TCP de manual, a rota `DiatuTcpRoute.manual` e a UI/config correspondente.
- Manter coluna SQLite / campo Firestore legado como string vazia (sem migration destrutiva obrigatória) para não quebrar sync/instaladores antigos.
- **Não** remover “Gerar serial manualmente” (`+` na Gravação) — feature distinta.
- Atualizar testes e `docs/laser-reference/diatu-tcp.md`.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `diatom-laser-marking`: confirmação da fila no serve do serial; modelo só lê nome; sem rota/comando manual.
- `marking-mode-selection`: Configurações sem comando TCP do manual; textos de ajuda alinhados ao ciclo serial+modelo.
- `product-catalog`: formulário de produto sem campo “Manual do produto”.

## Impact

- `sirene_app/lib/features/labels/mark_queue_processor.dart`
- `sirene_app/lib/features/labels/diatu_laser_tcp_server.dart`
- `sirene_app/lib/features/labels/serial_marking_backend.dart`
- `sirene_app/lib/core/config/app_config.dart`
- `sirene_app/lib/features/settings/settings_screen.dart`
- `sirene_app/lib/features/products/product_form_screen.dart`
- `sirene_app/test/mark_queue_processor_test.dart`
- `sirene_app/test/diatu_laser_tcp_server_test.dart`
- `docs/laser-reference/diatu-tcp.md`
- Sync/Firestore: `manual` continua mapeado como `''` (legado)
