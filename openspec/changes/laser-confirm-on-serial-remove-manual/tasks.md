## 1. Processador da fila

- [x] 1.1 Em `_serveNextSerial`, marcar entrada como `delivered` imediatamente após servir o serial
- [x] 1.2 Remover `_serveManual`, `simulateDiatuManualClient` e confirmação condicionada a `product.manual`
- [x] 1.3 `_serveModel` apenas resolve e devolve `Products.nome` (sem `_confirmActiveMark`)
- [x] 1.4 Atualizar `mark_queue_processor_test.dart` para o novo ciclo (confirm no serial; sem testes de manual)

## 2. Servidor TCP e config

- [x] 2.1 Remover rota/handler `manual` de `diatu_laser_tcp_server.dart` e `serial_marking_backend.dart`
- [x] 2.2 Remover `laserManualCommand` / defaults / prefs de `app_config.dart`
- [x] 2.3 Atualizar `diatu_laser_tcp_server_test.dart` (só serial + model)

## 3. UI

- [x] 3.1 Remover campo e validações do comando TCP manual em `settings_screen.dart`
- [x] 3.2 Remover botão/simulação de manual no diagnóstico laser (se existir)
- [x] 3.3 Remover campo “Manual do produto” de `product_form_screen.dart` (save com `manual: ''`)

## 4. Sync e docs

- [x] 4.1 Garantir mappers/upsert não dependem de UI de manual (legado → `''`)
- [x] 4.2 Atualizar `docs/laser-reference/diatu-tcp.md` — ciclo serial→delivered; sem objeto manual
- [x] 4.3 Rodar `flutter test` nos testes afetados
