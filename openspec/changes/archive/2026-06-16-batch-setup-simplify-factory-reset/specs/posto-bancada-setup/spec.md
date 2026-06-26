## ADDED Requirements

### Requirement: Vínculo único de bancada por instalação
O app SHALL persistir um único `device_id` de bancada vinculado ao posto (instalação do app no PC), independente da sessão de operador.

#### Scenario: Primeira configuração
- **WHEN** o operador conclui o setup de bancada escolhendo um dispositivo detectado
- **THEN** `selected_device_id` e `bancada_setup_complete` são persistidos

#### Scenario: Bancada já configurada
- **WHEN** o app inicia com `bancada_setup_complete: true`
- **THEN** a tela de Lote usa automaticamente a bancada vinculada sem dropdown de seleção

### Requirement: Alteração de bancada somente em Configurações
O app SHALL NOT permitir trocar a bancada vinculada na tela de Lote; a troca SHALL ocorrer apenas em Configurações → Posto/Bancada.

#### Scenario: Lote exibe bancada read-only
- **WHEN** o operador abre a tela de Lote com bancada configurada
- **THEN** o app exibe rótulo da bancada (ex.: "Bancada 2") e status de conexão, sem seletor editável

#### Scenario: Troca em Configurações
- **WHEN** o supervisor altera a bancada em Configurações e salva
- **THEN** o novo `device_id` passa a ser usado em `SET_BATCH` e no dashboard ao vivo

### Requirement: Gate de setup quando bancada ausente
O app SHALL impedir `SET_BATCH` e exibir fluxo de configuração quando não houver bancada vinculada.

#### Scenario: Lote sem bancada
- **WHEN** `bancada_setup_complete` é falso
- **THEN** a tela de Lote exibe CTA para configurar bancada (setup ou Configurações) e o botão Configurar lote permanece desabilitado

#### Scenario: Após login sem setup
- **WHEN** o operador autentica-se e não há bancada configurada
- **THEN** o app apresenta tela de setup de posto antes do uso normal de Lote
