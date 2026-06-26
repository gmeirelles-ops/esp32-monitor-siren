# factory-reset Specification

## Purpose
Reset geral do posto: apagar dados locais, desvincular bancada e reiniciar fluxo de configuração sem afetar a nuvem por padrão.

## Requirements
### Requirement: Reset geral do posto
O app SHALL oferecer ação "Reset geral do posto" em Configurações que apaga todos os dados locais, remove vínculo de bancada e marca Wi-Fi como não provisionado.

#### Scenario: Confirmação obrigatória
- **WHEN** o operador inicia reset geral
- **THEN** o app exige confirmação com digitação de `ZERAR` antes de executar

#### Scenario: Dados locais apagados
- **WHEN** o reset é confirmado e concluído com sucesso
- **THEN** o arquivo SQLite local é removido ou recriado vazio, `SharedPreferences` operacionais são limpos e a sessão de operador é encerrada

#### Scenario: Bancada e Wi-Fi resetados
- **WHEN** o reset conclui
- **THEN** `selected_device_id` e `bancada_setup_complete` são limpos e `wifi_provisioned` passa a `false`

#### Scenario: Próximo uso após reset
- **WHEN** o app reabre após reset
- **THEN** a tela de login é exibida e o fluxo de setup de bancada é exigido novamente

### Requirement: Reset não afeta nuvem por padrão
O reset geral SHALL NOT apagar dados no Firestore nem deslogar Firebase Auth, salvo opção explícita separada.

#### Scenario: Reset padrão com sync habilitado
- **WHEN** o operador executa reset sem marcar "Sair da nuvem"
- **THEN** apenas dados locais são removidos; credenciais Firebase podem permanecer no dispositivo

### Requirement: Feedback após reset
O app SHALL informar ao operador que o reset foi concluído e que é necessário reconfigurar o posto (login, bancada, Wi-Fi).

#### Scenario: Mensagem de sucesso
- **WHEN** o reset termina sem erro
- **THEN** o app exibe mensagem em português orientando reconfiguração do posto
