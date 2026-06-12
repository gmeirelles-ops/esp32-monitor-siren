## Why

O Painel já calcula yield, throughput e falhas de hardware a partir do SQLite local, mas o supervisor não consegue exportar esses dados para qualidade, ERP ou e-mail. Relatórios manuais (copiar tela) são lentos e propensos a erro.

## What Changes

- Exportação CSV do resumo de produção e throughput do período selecionado.
- Exportação CSV da lista de testes do período (serial, OP, veredito, potência, operador, timestamp).
- Exportação CSV de falhas de hardware do período.
- Botões "Exportar" na tela Painel com diálogo de destino (salvar arquivo no Windows).
- Testes unitários para formatação CSV (sem UI).

## Capabilities

### New Capabilities

- `production-reporting`: exportação de relatórios de produção em CSV

### Modified Capabilities

- `production-dashboard`: ações de exportação na tela Painel

## Impact

- **App Flutter**: `dashboard_screen.dart`, novo módulo `report_export.dart`, dependência opcional `file_picker` ou `path_provider` + `share_plus`
- **Sem impacto** em firmware ou Firestore
