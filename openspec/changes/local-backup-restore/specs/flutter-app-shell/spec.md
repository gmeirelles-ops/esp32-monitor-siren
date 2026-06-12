## MODIFIED Requirements

### Requirement: Tela de Configurações
O app SHALL oferecer tela de Configurações acessível pela navegação, contendo broker MQTT, impressora, `station_id`, sync em nuvem e manutenção local (backup e restore do SQLite).

#### Scenario: Acesso às configurações
- **WHEN** o operador abre Configurações
- **THEN** o app exibe campos editáveis de infraestrutura e status de sync

#### Scenario: Backup e restore visíveis
- **WHEN** o operador rola até a seção de manutenção
- **THEN** o app exibe ações "Fazer backup" e "Restaurar backup" com avisos de segurança
