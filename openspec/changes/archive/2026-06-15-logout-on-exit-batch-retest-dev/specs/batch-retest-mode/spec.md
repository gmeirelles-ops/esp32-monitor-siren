## ADDED Requirements

### Requirement: Checkbox de modo reteste no dashboard
O app SHALL exibir no Batch Live Dashboard um controle (checkbox) "Reteste" que o operador pode marcar ou desmarcar enquanto o lote está ativo e nenhum teste está em andamento (`TESTING`).

#### Scenario: Reteste desmarcado por padrão
- **WHEN** o dashboard é aberto para um lote recém-configurado
- **THEN** o checkbox Reteste inicia desmarcado e o fluxo de produção normal aplica

#### Scenario: Checkbox desabilitado durante teste
- **WHEN** o dispositivo está em estado `TESTING`
- **THEN** o checkbox Reteste fica desabilitado até o término do ciclo

#### Scenario: Operador ativa reteste
- **WHEN** o operador marca o checkbox Reteste com lote em `BATCH_READY`
- **THEN** o app sincroniza `modo_reteste: true` com a bancada via MQTT e exibe indicação visual de modo reteste

### Requirement: Sincronização MQTT do modo reteste
O app SHALL propagar o estado do checkbox Reteste para o firmware reenviando `SET_BATCH` com os parâmetros correntes do lote e campo `modo_reteste` booleano.

#### Scenario: Ativar reteste via MQTT
- **WHEN** o operador marca Reteste
- **THEN** o app publica `SET_BATCH` com `modo_reteste: true` e os demais campos inalterados do lote ativo

#### Scenario: Desativar reteste via MQTT
- **WHEN** o operador desmarca Reteste
- **THEN** o app publica `SET_BATCH` com `modo_reteste: false`

### Requirement: Reteste não consome serial nem cota no app
Com modo reteste ativo, o app SHALL processar resultados de teste (veredito, potência, persistência) mas SHALL NOT gerar serial, incrementar contador de serial, adicionar ao buffer de etiquetas nem avançar `proximo_sequencial` local do lote.

#### Scenario: Aprovação em reteste
- **WHEN** chega resultado APROVADO com modo reteste ativo
- **THEN** o app grava o teste sem serial, sem entrada no buffer e sem `bumpSerialCounter`

#### Scenario: Reprovação em reteste
- **WHEN** chega resultado REPROVADO com modo reteste ativo
- **THEN** o app grava o teste normalmente sem serial, sem alterar buffer ou contador

### Requirement: Reteste excluído das métricas de progresso
Testes gravados em modo reteste SHALL NOT entrar no cálculo de aprovados, reprovados, yield ou peças pendentes exibidos no dashboard.

#### Scenario: Contadores ignoram reteste
- **WHEN** um teste aprovado em reteste é gravado
- **THEN** os contadores de progresso do lote permanecem inalterados

### Requirement: Marcação de reteste no histórico
O app SHALL persistir flag identificável (`is_retest`) em cada `test_results` gravado durante modo reteste.

#### Scenario: Registro marcado como reteste
- **WHEN** um resultado é processado com modo reteste ativo
- **THEN** o registro em SQLite contém `is_retest = true` e `serial` nulo
