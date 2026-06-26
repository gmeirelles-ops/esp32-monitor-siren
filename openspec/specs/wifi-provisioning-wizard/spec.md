# wifi-provisioning-wizard Specification

## Purpose
Assistente de provisionamento no app Flutter: guia o operador para conectar dispositivos ESP32 ao Wi-Fi e broker MQTT via portal embarcado.
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

### Requirement: Estado de Wi-Fi provisionado persistido
O app SHALL persistir flag `wifi_provisioned` indicando que o posto já passou pelo assistente de provisionamento Wi-Fi com sucesso.

#### Scenario: Marcar como provisionado
- **WHEN** o operador conclui o assistente de provisionamento Wi-Fi (ou confirma manualmente que a rede está configurada)
- **THEN** `wifi_provisioned` é definido como verdadeiro em `AppConfig`

#### Scenario: Indicação em Configurações
- **WHEN** `wifi_provisioned` é verdadeiro
- **THEN** Configurações exibe status "Wi-Fi provisionado" e permite reabrir o assistente para reconfigurar

#### Scenario: Wi-Fi não provisionado
- **WHEN** `wifi_provisioned` é falso
- **THEN** Configurações sugere iniciar o assistente de provisionamento Wi-Fi

### Requirement: Reset de provisionamento Wi-Fi
O reset geral do posto SHALL definir `wifi_provisioned` como falso.

#### Scenario: Após reset geral
- **WHEN** o operador conclui reset geral do posto
- **THEN** `wifi_provisioned` é limpo e o assistente Wi-Fi é sugerido na próxima configuração do posto

