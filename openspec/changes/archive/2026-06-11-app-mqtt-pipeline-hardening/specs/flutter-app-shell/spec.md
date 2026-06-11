## ADDED Requirements

### Requirement: Pipeline MQTT ativo desde a inicialização
O app SHALL inicializar a conexão MQTT e o registro de mensagens na inicialização do aplicativo, independentemente da tela exibida primeiro.

#### Scenario: App aberto direto no Painel
- **WHEN** o app é iniciado e o operador permanece em uma tela que não observa dispositivos (ex.: Painel, Produtos)
- **THEN** heartbeats, presença e resultados de teste recebidos via MQTT são registrados normalmente

#### Scenario: Resultado de teste com app recém-aberto
- **WHEN** um dispositivo publica um resultado de teste logo após o app iniciar
- **THEN** o resultado é persistido e a etiqueta gerada sem exigir visita prévia à tela de Dispositivos ou Lote
