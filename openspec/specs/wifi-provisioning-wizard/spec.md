# wifi-provisioning-wizard Specification

## Purpose
TBD - created by archiving change flutter-companion-app. Update Purpose after archive.
## Requirements
### Requirement: Guia de provisionamento Wi-Fi
O app SHALL oferecer assistente passo-a-passo para provisionar um dispositivo ESP32 via captive portal.

#### Scenario: Instruções exibidas
- **WHEN** o operador inicia o assistente de provisionamento
- **THEN** o app exibe passos numerados: conectar ao AP `SireneValidator`, abrir `http://192.168.4.1`, selecionar rede e salvar

### Requirement: WebView do portal embarcado
O app SHALL oferecer WebView integrada para acessar o portal `http://192.168.4.1` quando o dispositivo estiver no AP de provisionamento.

#### Scenario: Portal carregado
- **WHEN** o operador está conectado ao AP `SireneValidator` e abre a WebView
- **THEN** o app carrega o formulário HTML do captive portal em `192.168.4.1`

### Requirement: Indicação de provisionamento ativo
O app SHALL informar quando um dispositivo está em estado `PROVISIONING` (detectado via heartbeat).

#### Scenario: Dispositivo em provisionamento
- **WHEN** o heartbeat de um dispositivo indica `estado: "PROVISIONING"`
- **THEN** o app exibe badge "Provisionando" e sugere iniciar o assistente Wi-Fi

