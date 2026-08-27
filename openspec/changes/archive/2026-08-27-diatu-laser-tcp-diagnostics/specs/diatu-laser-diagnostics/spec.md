### Requirement: Painel de diagnóstico laser em Configurações
O app SHALL exibir, quando modo Gravação laser estiver ativo, um painel com: estado do servidor TCP (ativo/parado/erro), porta vinculada, quantidade de seriais pendentes na fila `mark_queue`, e registro das últimas conexões (timestamp, comando recebido, resposta enviada ou erro).

#### Scenario: Servidor ativo com fila pendente
- **WHEN** modo laser está ativo, servidor escutando na porta configurada e há itens pendentes na fila
- **THEN** o painel mostra "Ativo", a porta e o número de pendentes

#### Scenario: Falha ao abrir porta
- **WHEN** outro processo já ocupa a porta TCP configurada
- **THEN** o painel mostra erro explícito sugerindo desativar "Marca de controlo TCP" no Diaotu ou alterar a porta

### Requirement: Simulação de cliente DiatuCAD
O app SHALL oferecer ação "Simular DiatuCAD" que conecta a `127.0.0.1` na porta configurada, envia o comando TCP esperado e exibe a resposta do servidor local sem exigir o software do laser.

#### Scenario: Simulação com fila de teste
- **WHEN** o operador acionou "Testar gravação" e em seguida "Simular DiatuCAD"
- **THEN** a resposta exibida é o serial de teste enfileirado (ex. `0000000000`)

#### Scenario: Simulação sem fila
- **WHEN** a fila está vazia e o operador aciona "Simular DiatuCAD"
- **THEN** a resposta exibida é `ERROR:EMPTY`

### Requirement: Script de teste de rede
O repositório SHALL fornecer `scripts/test_laser_tcp.ps1` aceitando porta e comando, imprimindo a resposta e retornando código de saída diferente de zero se a resposta começar com `ERROR:`.

#### Scenario: Teste manual no posto
- **WHEN** o integrador executa o script com porta e comando iguais ao app
- **THEN** recebe o serial pendente ou `ERROR:EMPTY` / `ERROR:BADCMD` conforme estado da fila e configuração
