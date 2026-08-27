## Why

Rastreabilidade de seriais e OPs existe no SQLite (`test_results`, buffer de etiquetas), mas não há tela de consulta rápida. Supervisor e qualidade precisam buscar "este serial passou em qual OP?" ou listar testes de uma OP sem exportar CSV manualmente.

## What Changes

- Nova tela "Consulta" na navegação principal.
- Busca por serial (completo ou parcial) e por número OP.
- Resultado: lista de testes com veredito, potência, dispositivo, operador, timestamp.
- Ação "Reimprimir etiqueta" quando serial aprovado (reutiliza lógica de `label-printing`).
- Testes unitários de query SQLite.

## Capabilities

### New Capabilities

- `serial-op-lookup`: consulta e rastreabilidade por serial ou OP

### Modified Capabilities

- `serial-traceability`: exibição de histórico consultável
- `label-printing`: reimpressão a partir da consulta

## Impact

- **App Flutter**: nova tela, `database.dart` (queries), navegação em `app.dart`
- **Sem impacto** em firmware
