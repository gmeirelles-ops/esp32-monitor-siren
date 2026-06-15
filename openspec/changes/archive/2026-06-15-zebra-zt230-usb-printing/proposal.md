## Why

A Zebra ZT230 do posto não possui interface de rede (apenas USB/série), mas o app Flutter envia ZPL exclusivamente via TCP (IP:9100). Isso impede impressão em produção sem hardware extra (print server) ou rede inexistente. O rolo físico tem 3 etiquetas por linha (~10×30 mm cada); o ZPL já está correto em layout, falta o canal de envio adequado ao Windows desktop onde o app roda.

## What Changes

- Novo modo de impressão **USB local (Windows)**: envio de ZPL em bruto para impressora instalada no sistema operacional (driver Zebra), sem depender de IP.
- Modo **rede (TCP:9100)** mantido como opção para postos com cartão de rede ou print server.
- Tela de Configurações: seletor de modo (USB / Rede), lista de impressoras Windows instaladas (USB) ou host/porta (rede).
- Abstração `LabelPrinter` com implementações `TcpLabelPrinter` e `WindowsRawLabelPrinter`; fluxo de buffer, múltiplos de 3 e export ZPL em dev permanecem iguais.
- Documentação de instalação: driver Zebra, nome da impressora, cabo USB no mesmo PC do app.
- Calibração ZPL documentada para rolo 3-across (10×30 mm); ajuste fino de `^PW`/`^LL`/`^FO` se necessário após teste físico.

## Capabilities

### New Capabilities

- `windows-raw-label-printing`: envio de ZPL via spooler Windows (RAW) para impressora USB local

### Modified Capabilities

- `label-printing`: transporte de ZPL suporta USB local além de TCP; mensagens de erro distinguem modos
- `serial-and-labels`: configuração da impressora inclui modo e nome da impressora Windows
- `desktop-ui-layout`: formulário de impressora com seletor de modo e picker de impressoras
- `dev-label-file-export`: reforço de que export ZPL é alternativa de teste quando USB ainda não configurado

## Impact

- **App Flutter (Windows)**: `label_printer.dart`, `app_config.dart`, `settings_screen.dart`, injeção em `mqtt_providers.dart` e `labels_screen.dart`
- **Dependência**: pacote `win32` (ou channel nativo mínimo) para `OpenPrinter` / `WritePrinter` com datatype RAW
- **Linux/macOS**: modo USB não suportado nesta fase; rede TCP e export ZPL continuam disponíveis
- **Hardware**: ZT230 via USB no PC do posto; driver Zebra Designer ou Zebra Setup Utilities
- **ZPL**: `zpl_generator.dart` — possível ajuste de coordenadas após validação física do rolo 3×10×30 mm
- **Testes**: unitários da abstração; mock do transporte; smoke manual com impressora real
