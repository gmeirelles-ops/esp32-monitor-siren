## MODIFIED Requirements

### Requirement: Persistência antes de marcação e sync
O app SHALL deduplicar por `(numero_op, ts_ms)` quando presente, gravar SQLite **antes** de enfileirar laser / sync, e exibir estados Testando/Aguardando MQTT.

#### Scenario: Aprovado
- **WHEN** chega teste APROVADO
- **THEN** o app persiste o resultado e só então gera serial e enfileira gravação laser

### Requirement: Veredito MQTT como fonte da verdade
O app SHALL tratar `veredito` de `tipo:teste` como fonte da verdade para aprovação/reprovação, serial e marcação física. O app SHALL NOT recalcular veredito a partir de potência e limites locais.

#### Scenario: Reprovado
- **WHEN** `veredito` é REPROVADO
- **THEN** o app grava REPROVADO e não gera serial nem enfileira laser
