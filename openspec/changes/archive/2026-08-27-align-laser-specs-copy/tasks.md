## 1. Specs OpenSpec (laser)

- [x] 1.1 Atualizar `serial-and-labels`, `serial-traceability`, `siren-traceability-report` (sem buffer ZPL; Regravar)
- [x] 1.2 Atualizar `batch-live-dashboard`, `batch-test-execution`, `batch-retest-mode`
- [x] 1.3 Atualizar `mqtt-client`, `operator-traceability`, `serial-counter`, `device-monitoring`
- [x] 1.4 Atualizar `flutter-app-shell`, `desktop-ui-layout` (Configurações laser-only)
- [x] 1.5 Adicionar glossário em `diatu-laser-marking` + `project-documentation`
- [x] 1.6 Retirar `dev-label-file-export` (Purpose RETIRED)

## 2. Copy app + docs

- [x] 2.1 `LookupScreen` subtitle → testes + Regravar (não “reimprimir etiquetas”)
- [x] 2.2 `firebase_bootstrap` e outros textos operador com “etiquetas” → laser/gravação
- [x] 2.3 Glossário Diaotu vs DiatuCAD em `docs/laser-reference/README.md`
- [x] 2.4 Ajustar descrições de testes unitários que afirmam “etiqueta” no sentido Zebra (só texto)

## 3. Verificação

- [x] 3.1 Grep em `openspec/specs/` e `sirene_app/lib/` (fora comentários históricos inevitáveis): sem “reimprimir etiqueta” / “Impressora Zebra” ativos na UI
- [x] 3.2 `flutter test` no `sirene_app`
