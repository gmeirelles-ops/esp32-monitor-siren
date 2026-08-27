## ADDED Requirements

### Requirement: Layout segue hierarquia de produção

O sistema SHALL aplicar design system compartilhado com tipografia legível (mín. 14sp corpo, 18sp títulos de seção), espaçamento de 8px grid e contraste adequado para uso em chão de fábrica.

#### Scenario: Tela de Lote

- **WHEN** o operador visualiza a tela principal de Lote
- **THEN** informações críticas (OP, progresso, operador, estado do dispositivo) aparecem acima da dobra sem scroll

### Requirement: Estados vazios orientam o operador

O sistema SHALL exibir empty states com título, descrição e CTA em telas sem dados (sem lote, sem operadores, sem dispositivo configurado).

#### Scenario: Sem lote ativo

- **WHEN** não há lote configurado
- **THEN** a tela exibe mensagem clara e botão "Configurar lote"

### Requirement: Feedback visual de ações

O sistema SHALL exibir snackbar ou banner para sucesso/erro de ações assíncronas (MQTT, impressão, sync) com duração mínima de 3 segundos.

#### Scenario: Falha ao enviar SET_BATCH

- **WHEN** o comando MQTT falha por dispositivo offline
- **THEN** o sistema exibe mensagem de erro com sugestão de verificar conexão em Configurações

### Requirement: Indicadores de conexão no shell

O sistema SHALL exibir no cabeçalho global ícones de status MQTT (conectado/desconectado) e dispositivo alvo (online/offline/não configurado) sem tela dedicada.

#### Scenario: Dispositivo offline

- **WHEN** o heartbeat do dispositivo alvo expira
- **THEN** o indicador no cabeçalho muda para offline e ações de lote exibem aviso
