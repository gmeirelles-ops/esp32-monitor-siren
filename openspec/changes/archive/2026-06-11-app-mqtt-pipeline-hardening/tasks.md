## 1. MqttService — ciclo de vida da conexão

- [x] 1.1 Guardar `StreamSubscription` do `updates` e cancelar antes de re-assinar em `_onConnected`
- [x] 1.2 Limpar callbacks (`onConnected`/`onDisconnected`) e cancelar assinatura do cliente antigo em `_doConnect`
- [x] 1.3 Cancelar assinatura em `disconnect()` e `dispose()`

## 2. DevicesNotifier — processamento serializado

- [x] 2.1 Encadear `_handleMessage` em fila FIFO de futures no listener
- [x] 2.2 Try/catch por mensagem para a cadeia nunca quebrar

## 3. Buffer de etiquetas

- [x] 3.1 `_printPending` opera por entradas e remove do buffer apenas ids impressos
- [x] 3.2 Falha parcial preserva blocos não enviados

## 4. Falha de impressão visível

- [x] 4.1 `printFailureProvider` (StateProvider<String?>) setado no catch do auto-print e da impressão manual
- [x] 4.2 Snackbar no BatchScreen ao registrar falha
- [x] 4.3 Banner de falha na LabelsScreen; limpar em impressão bem-sucedida

## 5. Bootstrap do MQTT

- [x] 5.1 `ref.read(devicesProvider)` no initState do app shell

## 6. Testes e validação

- [x] 6.1 Teste: processamento serializado preserva ordem e isola erros
- [x] 6.2 Teste: remoção por id mantém entradas adicionadas durante a impressão
- [x] 6.3 `flutter analyze` e `flutter test` passando
