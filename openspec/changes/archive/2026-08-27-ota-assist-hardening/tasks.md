## 1. Serve + pré-voo

- [x] 1.1 Inverter preferência: Dart HttpServer primeiro; Python só fallback no Windows
- [x] 1.2 Função de pré-voo (bin válido, IP, serve, smoke GET/HEAD) com mensagens PT acionáveis
- [x] 1.3 Integrar pré-voo em `FirmwareUpdateScreen` / Admin antes de `OTA_UPDATE`

## 2. UI operacional

- [x] 2.1 Exibir URL, IP e porta enquanto serve; checklist curto (rede / firewall / bancada)
- [x] 2.2 Melhorar copy de erro de porta/firewall (sem jargão desnecessário)

## 3. Docs

- [x] 3.1 Atualizar `docs/PRODUCAO.md` § OTA/USB para fluxo do app
- [x] 3.2 Ajustar trechos do guia firmware que mandam só `python -m http.server` como passo principal

## 4. Testes

- [x] 4.1 Unit tests da lógica de pré-voo / ordem Dart-first
- [x] 4.2 `flutter test`
