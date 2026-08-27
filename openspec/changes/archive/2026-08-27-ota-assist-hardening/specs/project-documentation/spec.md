## MODIFIED Requirements

### Requirement: OTA e USB documentados pelo app
`docs/PRODUCAO.md` (e referências no guia) SHALL descrever OTA via tela Firmware do app e flash USB pelo app (Windows) como caminhos padrão; `python -m http.server` / `idf.py flash` permanecem como fallback/recovery.

#### Scenario: Checklist produção
- **WHEN** o supervisor abre a seção OTA/atualização em PRODUCAO
- **THEN** encontra passos do app antes de comandos manuais de terminal
