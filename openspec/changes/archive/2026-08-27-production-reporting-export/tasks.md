## 1. Módulo de exportação

- [ ] 1.1 Criar `report_export.dart` com `CsvReportBuilder` (resumo, testes, falhas)
- [ ] 1.2 Testes unitários de formatação CSV (separador `;`, encoding UTF-8 BOM)

## 2. Queries SQLite

- [ ] 2.1 Método `getTestResultsForPeriod` se não existir para exportação detalhada
- [ ] 2.2 Reutilizar agregações existentes do dashboard para resumo

## 3. UI Painel

- [ ] 3.1 Adicionar menu ou botões "Exportar resumo / testes / falhas" em `dashboard_screen.dart`
- [ ] 3.2 Integrar `file_selector` para salvar no Windows

## 4. Verificação

- [ ] 4.1 `flutter test` passando
- [ ] 4.2 Smoke manual: abrir CSV no Excel com acentuação correta
