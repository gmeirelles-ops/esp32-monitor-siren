## Why

O app companion já funciona em desktop (Windows/Linux) com `NavigationRail` e tema escuro Diponto, mas formulários e botões esticam em largura total nas telas Lote, Configurações e Admin — o que cansa a leitura e passa sensação de interface inacabada. Empty states mínimos (texto centralizado) e navegação lateral pouco destacada reforçam essa impressão. Refinar o layout desktop melhora produtividade do operador na linha sem alterar fluxos MQTT, SQLite ou Firestore.

## What Changes

- Limitar largura máxima de formulários desktop (~600 px) com `Center` + `ConstrainedBox`, evitando campos e botões full-width.
- Agrupar seções de Configurações (Broker MQTT, Impressora Zebra, Nuvem) em `Card`s com fundo elevado (`#1E1E1E` sobre `#121212` / surface atual).
- Usar grids horizontais em desktop: IP + Porta na mesma linha (70/30); Ano + Quantidade + Próximo sequencial na tela Lote.
- Melhorar empty states em Dispositivos, Etiquetas e Produtos: ícone grande, texto orientativo e `CircularProgressIndicator` quando o app aguarda MQTT.
- Refinar `NavigationRail`: largura maior, item selecionado com fundo amber ~15% opacidade e bordas arredondadas.
- Hierarquia de botões: ações primárias em `ElevatedButton` amber; secundárias/destrutivas em `OutlinedButton` (vermelho ou cinza).
- Ajustar contraste de `InputDecoration` (bordas mais visíveis no tema escuro).
- Extrair widgets reutilizáveis (`FormSectionCard`, `DesktopFormLayout`, `EmptyStateView`) em `shared/widgets/`.

## Capabilities

### New Capabilities

- `desktop-ui-layout`: Largura máxima de formulários, cards de seção, grids de campos e empty states enriquecidos em telas desktop.

### Modified Capabilities

- `flutter-app-shell`: Refinamento visual do `NavigationRail` (largura, indicador de seleção) e hierarquia de botões/contraste no tema global.

## Impact

- **App Flutter** (`sirene_app/`): `diponto_theme.dart`, `app.dart`, telas `batch_screen`, `settings_screen`, `admin_screen`, `devices_screen`, `labels_screen`, `products_screen`, `product_form_screen`; novos widgets em `shared/widgets/`.
- **Firmware / MQTT / Firestore**: nenhuma alteração funcional.
- **Mobile** (< 900 px): layouts compactos preservados; melhorias de empty state e tema aplicam-se também.
