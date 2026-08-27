## 1. App — remover Zebra / laser-only

- [x] 1.1 Remover `MarkingMode.labels`, setters/prefs de impressora Zebra e ramos `if (markingMode == …)` — laser é o único caminho
- [x] 1.2 Remover arquivos ZPL/transporte: `zpl_generator.dart`, `tcp_label_printer.dart`, `windows_raw_label_printer.dart`, `label_printer*.dart`, `label_buffer_grouping.dart`, `label_print_logic.dart` (e exports mortos)
- [x] 1.3 Simplificar `labels_screen` / remark / MQTT (`mqtt_providers`) para só MarkQueue; apagar `_maybePrintLabels` e buffer
- [x] 1.4 Limpar `settings_screen`: só config laser + diagnóstico; sem seletor Etiquetas/Zebra
- [x] 1.5 Drift: parar writes em `LabelBufferEntries`; schema bump para dropar tabela **ou** deixar órfã documentada
- [x] 1.6 Atualizar `portuguese_labels`, shells de falha de impressão Zebra, e copy “Reimprimir” → só “Regravar”
- [x] 1.7 Remover/adaptar testes: `zpl_*`, `label_buffer_*`, `label_printer_*`; manter/ajustar laser + remark + mqtt approval

## 2. Documentação

- [x] 2.1 `sirene-validator/docs/GUIA_COMPLETO.md`: versão **1.8.10**, heartbeat **10 s**, diagramas/fluxo sem Zebra (laser)
- [x] 2.2 `sirene-validator/docs/DEPLOY_PRODUCTION.md` (+ TESTING se citar versão): ≥ **1.8.10**
- [x] 2.3 `docs/PRODUCAO.md`: checklist laser-only; remover passos Zebra como fluxo ativo; versões corretas
- [x] 2.4 `README.md` (raiz) e `sirene_app/README.md`: arquitetura e pré-requisitos sem Zebra
- [x] 2.5 `docs/label-reference/README.md`: marcar obsoleto (produto = laser) com link para `docs/laser-reference/`

## 3. Specs main (na archive / sync)

- [x] 3.1 Ao concluir implementação, sync desta change: atualizar `openspec/specs/*` conforme deltas; remover ou esvaziar capabilities Zebra removidas
- [x] 3.2 Garantir `diatom-laser-marking` (ou nome alinhado Diatu) presente em `openspec/specs/`

## 4. Verificação

- [x] 4.1 `cd sirene_app && flutter test` (ou subset CI) verde
- [x] 4.2 Grep residual: sem referências ativas a Zebra/ZPL no código de produção (`lib/`) e docs operacionais (exceto pasta histórica marcada obsoleta)
