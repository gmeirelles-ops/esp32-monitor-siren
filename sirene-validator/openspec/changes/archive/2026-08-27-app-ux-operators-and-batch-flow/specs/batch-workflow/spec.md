## MODIFIED Requirements

### Requirement: Lote é o hub operacional

O sistema SHALL centralizar configuração de lote, progresso, dashboard ao vivo e ações de encerramento na tela de Lote.

#### Scenario: Lote ativo

- **WHEN** um lote está em andamento
- **THEN** a tela de Lote exibe OP, produto, sequencial, aprovados/reprovados, operador e estado FSM em tempo real

#### Scenario: Configurar novo lote

- **WHEN** o operador inicia configuração de lote com operador e dispositivo válidos
- **THEN** o formulário de lote e o envio `SET_BATCH` ocorrem na mesma tela sem navegar para Dispositivos

### Requirement: Simulação de teste permanece em modo debug

O sistema SHALL manter "Simular teste (dev)" acessível apenas em builds debug, dentro do dashboard ao vivo na tela de Lote.

#### Scenario: Build release

- **WHEN** o app é compilado em release
- **THEN** a opção de simulação não é exibida

## ADDED Requirements

### Requirement: Resumo do posto na tela de Lote

O sistema SHALL exibir card-resumo com operador ativo, dispositivo alvo, broker MQTT e impressora configurada.

#### Scenario: Visão geral

- **WHEN** o operador está na tela de Lote sem lote ativo
- **THEN** o card-resumo mostra status de cada integração com ícones e textos curtos
