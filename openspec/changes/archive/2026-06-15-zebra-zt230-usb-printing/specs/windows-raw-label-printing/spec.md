## ADDED Requirements

### Requirement: Envio ZPL via spooler Windows RAW
Em builds Windows, o app SHALL enviar comandos ZPL em bruto (datatype RAW) para uma impressora instalada no sistema operacional, sem conversão gráfica intermediária.

#### Scenario: Job RAW enviado com sucesso
- **WHEN** o modo de impressão é USB e o operador dispara impressão de um bloco ZPL válido
- **THEN** o app abre a impressora configurada pelo nome Windows, escreve os bytes ZPL e conclui o job sem erro

#### Scenario: Impressora Windows inexistente
- **WHEN** o nome da impressora configurada não existe no sistema
- **THEN** o app falha com mensagem em português indicando impressora não encontrada e não remove entradas do buffer

### Requirement: Listagem de impressoras Windows instaladas
O app SHALL enumerar impressoras instaladas no Windows para seleção na tela de Configurações quando o modo USB estiver ativo.

#### Scenario: Dropdown populado
- **WHEN** o operador abre Configurações com modo USB em Windows
- **THEN** o app exibe lista de nomes de impressoras retornados pelo spooler

#### Scenario: Plataforma não Windows
- **WHEN** o app executa em plataforma sem suporte USB local
- **THEN** o modo USB não é oferecido e o app utiliza rede ou export ZPL conforme disponível

### Requirement: Teste de impressão USB
O app SHALL oferecer ação de teste que envia etiqueta ZPL mínima à impressora USB configurada, independente do buffer de produção.

#### Scenario: Teste bem-sucedido
- **WHEN** o operador aciona "Testar impressão" com impressora USB válida
- **THEN** a impressora emite etiqueta de teste e o app confirma sucesso em português

#### Scenario: Teste com falha
- **WHEN** a impressora está offline ou o spooler rejeita o job
- **THEN** o app exibe erro em português sem alterar o buffer de etiquetas de produção
