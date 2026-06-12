## 1. Setup do Projeto Flutter

- [x] 1.1 Criar projeto Flutter em `sirene_app/` com suporte Android (minSdk 21+)
- [x] 1.2 Adicionar dependências: `flutter_riverpod`, `mqtt_client`, `drift`, `webview_flutter`, `shared_preferences`
- [x] 1.3 Configurar estrutura de pastas conforme design (`core/`, `features/`, `shared/`)
- [x] 1.4 Adicionar assets: logo Diponto (SVG/PNG) e fonte legível

## 2. Tema e Shell do App

- [x] 2.1 Implementar `diponto_theme.dart` com paleta amber (`#FFB300`, `#FF8F00`, `#FFD54F`, surface `#1A1A1A`)
- [x] 2.2 Criar `MaterialApp` com tema dark Material 3 e logo na AppBar
- [x] 2.3 Implementar navegação bottom bar: Dispositivos, Lote, Etiquetas, Configurações, Admin
- [x] 2.4 Tela de Configurações: broker MQTT (host/porta) e impressora (IP/porta 9100) com persistência

## 3. Cliente MQTT

- [x] 3.1 Implementar `MqttService` com conexão, subscribe wildcard e reconexão com backoff
- [x] 3.2 Criar models Dart para heartbeat, status (teste/rejeicao/ota), calibracao, alerta, presenca
- [x] 3.3 Implementar parser JSON com tratamento de payloads malformados
- [x] 3.4 Implementar `publishCommand(deviceId, payload)` com QoS 1
- [x] 3.5 Provider Riverpod para status de conexão MQTT (conectado/desconectado/reconectando)

## 4. Monitoramento de Dispositivos

- [x] 4.1 Implementar descoberta automática via `sirene/+/heartbeat` e `sirene/+/presenca`
- [x] 4.2 Tela lista de dispositivos com badge online/offline e estado FSM
- [x] 4.3 Tela detalhe: RSSI, uptime, fila offline, firmware_version, último heartbeat
- [x] 4.4 Exibir alertas de hardware (`alerta`) com destaque visual vermelho
- [x] 4.5 Persistir resultados de teste em SQLite (drift) com timestamp

## 5. Fluxo de Lote (Operador)

- [x] 5.1 Formulário SET_BATCH com validação de campos obrigatórios
- [x] 5.2 Envio SET_BATCH + aguardar heartbeat `BATCH_READY` (timeout 10s, retry)
- [x] 5.3 Botão END_BATCH com confirmação e aguardar heartbeat `IDLE`
- [x] 5.4 Indicador "Pressione o botão" quando estado `BATCH_READY`
- [x] 5.5 Spinner amber durante estado `TESTING`
- [x] 5.6 Cards de resultado em tempo real (aprovado verde / reprovado vermelho)
- [x] 5.7 Barra de progresso `aprovados_no_lote` / `quantidade_total` com alerta ao atingir meta
- [x] 5.8 Exibir rejeições de comando (`tipo: "rejeicao"`) como snackbar

## 6. Serial e Etiquetas

- [x] 6.1 Implementar algoritmo ITF 2 de 5 em Dart (portar lógica de `pure_logic`)
- [x] 6.2 Gerar serial 10 dígitos automaticamente em cada aprovação
- [x] 6.3 Buffer local de seriais com contador visível na aba Etiquetas
- [x] 6.4 Gerador ZPL para etiquetas 10x30mm (3 colunas) com código de barras ITF
- [x] 6.5 Envio ZPL via socket TCP (porta 9100) ao atingir múltiplo de 3
- [x] 6.6 Botão "Imprimir pendentes" para órfãs (1-2 seriais)
- [x] 6.7 Badge persistente de etiquetas pendentes no fechamento de lote

## 7. Provisionamento Wi-Fi

- [x] 7.1 Assistente passo-a-passo com instruções numeradas (AP SireneValidator → 192.168.4.1)
- [x] 7.2 WebView integrada para portal embarcado
- [x] 7.3 Badge "Provisionando" quando heartbeat indica `PROVISIONING`
- [x] 7.4 Link para configurações Wi-Fi do Android (intent)

## 8. Admin (Calibração e OTA)

- [x] 8.1 Botão START_CALIBRATION (habilitado apenas em `IDLE`)
- [x] 8.2 Exibir resultado de calibração (potencia_media) ao receber em `calibracao`
- [x] 8.3 Formulário OTA_UPDATE com campo URL e confirmação
- [x] 8.4 Monitorar eventos `tipo: "ota"` (inicio/sucesso/falha) com feedback visual

## 9. Testes e Validação

- [x] 9.1 Testes unitários: ITF 2 de 5, parser JSON MQTT, geração ZPL
- [ ] 9.2 Teste de integração com broker Mosquitto local e firmware em bancada
- [ ] 9.3 Validar fluxo completo: SET_BATCH → botão → aprovação → serial → impressão
- [ ] 9.4 Validar reconexão MQTT e sincronização de fila offline do dispositivo
- [ ] 9.5 Build Windows release (`flutter build windows --release`) para distribuição interna
