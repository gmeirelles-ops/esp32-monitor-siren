## ADDED Requirements

### Requirement: Gate de setup de bancada após login
O app SHALL verificar se a bancada do posto está configurada após autenticação do operador e SHALL impedir acesso ao shell principal até concluir o setup quando necessário.

#### Scenario: Posto sem bancada configurada
- **WHEN** o operador autentica-se e `bancada_setup_complete` é falso
- **THEN** o app exibe `PostoSetupScreen` em vez do shell principal

#### Scenario: Posto com bancada já vinculada
- **WHEN** o operador autentica-se e `bancada_setup_complete` é verdadeiro
- **THEN** o app navega diretamente ao shell principal

#### Scenario: Migração de instalações existentes
- **WHEN** o app atualiza em posto que já possui `selected_device_id` persistido
- **THEN** `bancada_setup_complete` é definido como verdadeiro automaticamente na primeira execução pós-atualização

### Requirement: Seção Manutenção do posto em Configurações
O app SHALL incluir seção "Manutenção do posto" em Configurações com vínculo de bancada, atalho de provisionamento Wi-Fi e reset geral.

#### Scenario: Alterar bancada em Configurações
- **WHEN** o supervisor acessa Configurações → Manutenção do posto → Bancada
- **THEN** pode selecionar outro dispositivo detectado e salvar o novo vínculo

#### Scenario: Reset geral acessível
- **WHEN** o supervisor abre Configurações → Manutenção do posto
- **THEN** o botão "Reset geral do posto" está visível com estilo destrutivo
