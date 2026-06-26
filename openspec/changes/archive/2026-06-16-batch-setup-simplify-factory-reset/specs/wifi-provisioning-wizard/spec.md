## ADDED Requirements

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
