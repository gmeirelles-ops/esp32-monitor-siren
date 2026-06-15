## ADDED Requirements

### Requirement: Cliente TCP para laser Diatom
O app SHALL implementar `DiatomLaserBackend` que conecta via TCP ao controlador configurado e envia o serial aprovado usando template de comando documentado em `docs/laser-reference/diatom-tcp.md`.

#### Scenario: Envio de serial após aprovação
- **WHEN** o modo de marcação é `laser` e um serial é gerado após teste aprovado
- **THEN** o app envia o serial ao controlador laser via TCP configurado

#### Scenario: Falha de conexão
- **WHEN** o laser não responde ou a conexão TCP falha
- **THEN** o serial permanece na fila de gravação com `last_error` e o operador vê alerta na UI

#### Scenario: Teste de gravação nas Configurações
- **WHEN** o operador aciona "Testar gravação" com host/porta configurados
- **THEN** o app envia serial de teste fixo (ex.: `0000000000`) ao laser sem alterar buffer de produção

### Requirement: Fila local de gravações pendentes
O app SHALL persistir gravações pendentes em SQLite (`mark_queue`) com retry automático até sucesso ou falha permanente visível ao operador.

#### Scenario: Serial enfileirado offline
- **WHEN** a gravação falha por rede
- **THEN** a entrada fica com status pendente e é reprocessada periodicamente

#### Scenario: Gravação bem-sucedida
- **WHEN** o backend confirma envio bem-sucedido
- **THEN** a entrada é removida da fila ou marcada como concluída

### Requirement: Regravação manual de serial
O app SHALL permitir regravação de um serial do histórico local quando modo laser está ativo, sem duplicar registro de teste.

#### Scenario: Regravação avulsa
- **WHEN** o operador busca serial no histórico e aciona "Regravar"
- **THEN** o app envia o serial ao laser independentemente da fila automática

### Requirement: Template de gravação no laser
O repositório SHALL documentar em `docs/laser-reference/` o template de job (campo variável `serial`, dimensões, material) e procedimento de homologação física na carcaça da sirene.

#### Scenario: Homologação documentada
- **WHEN** um integrador segue `docs/laser-reference/README.md`
- **THEN** consegue criar template no software Diatom e validar legibilidade do serial ITF de 10 dígitos
