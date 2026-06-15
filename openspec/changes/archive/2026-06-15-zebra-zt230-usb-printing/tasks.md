## 1. Dependências e abstração de transporte

- [x] 1.1 Adicionar `win32` ao `pubspec.yaml` (somente uso em `dart:io` + `Platform.isWindows`)
- [x] 1.2 Criar interface `LabelPrinterTransport` com `sendZpl(String)` e fábrica `createLabelPrinter(AppConfig)`
- [x] 1.3 Renomear/refatorar `LabelPrinter` TCP atual para `TcpLabelPrinter`
- [x] 1.4 Implementar `WindowsRawLabelPrinter` com `OpenPrinter` / `WritePrinter` (datatype RAW)
- [x] 1.5 Implementar `listWindowsPrinters()` via API do spooler

## 2. Configuração persistida

- [x] 2.1 Estender `AppConfig` com `printerMode` (`usb`|`network`), `printerWindowsName` e defaults (USB em Windows)
- [x] 2.2 Migrar pontos de uso (`mqtt_providers`, `labels_screen`, `batch_report_detail_screen`) para a fábrica

## 3. UI de Configurações

- [x] 3.1 Adicionar seletor segmentado USB / Rede no card Impressora Zebra
- [x] 3.2 Modo USB: dropdown de impressoras + botão atualizar lista
- [x] 3.3 Modo Rede: manter IP + porta 70/30 (comportamento atual)
- [x] 3.4 Botão **Testar impressão** com ZPL mínimo e feedback em português
- [x] 3.5 Mensagens de erro distinguindo modo USB vs rede

## 4. ZPL e documentação

- [x] 4.1 Centralizar constantes de layout (`^PW`, `^LL`, posições) em `zpl_generator.dart` para rolo confirmado 3×10×30 mm
- [x] 4.4 Reimpressão avulsa: `generateZplReprintRow(serial)` com linha completa (col 1 = serial, cols 2–3 vazias) + aviso na UI
- [x] 4.2 Atualizar `docs/PRODUCAO.md` e `scripts/windows-portable/LEIA-ME.txt` com instalação driver USB e calibração
- [x] 4.3 Texto de ajuda no export ZPL em dev (alternativa sem hardware)

## 5. Testes

- [x] 5.1 Testes unitários da fábrica de transporte (mock USB vs TCP conforme `printerMode`)
- [x] 5.2 Testes existentes de ZPL e `printLabelBatches` permanecem verdes
- [x] 5.3 Teste unitário de `generateZplReprintRow` (linha 3 posições, 2 vazias)
- [x] 5.4 Smoke na instalação do posto: USB, linha de 3, órfãs manuais, reimpressão com aviso (checklist em `docs/PRODUCAO.md` e `LEIA-ME.txt`)

## 6. Validação física (na instalação do posto)

- [x] 6.1 Quem instalar o posto imprime amostra 10×30 mm; ajustar coordenadas ZPL se necessário (procedimento documentado; calibração no hardware pelo operador)
