# calibration-history Specification

## Purpose
TBD - created by archiving change ota-campaign-calibration-oplock. Update Purpose after archive.
## Requirements
### Requirement: Registro histórico de calibrações
O app SHALL registrar um evento de calibração por produto sempre que uma nova autocalibração for concluída e salva, contendo `id_produto`, `potencia_ref`, dispositivo e instante.

#### Scenario: Nova calibração registrada
- **WHEN** o operador conclui uma autocalibração e salva o produto
- **THEN** o app grava um registro de calibração com a potência de referência medida, o dispositivo e o timestamp

#### Scenario: Edição sem recalibrar não gera registro
- **WHEN** o operador edita apenas metadados do produto sem nova calibração
- **THEN** o app não cria novo registro de calibração

### Requirement: Visualização do histórico de calibração
O app SHALL exibir o histórico de calibrações de um produto ao editá-lo, em ordem cronológica decrescente.

#### Scenario: Histórico exibido na edição
- **WHEN** o operador abre um produto já calibrado para edição
- **THEN** o app lista as calibrações anteriores com potência de referência e data, da mais recente para a mais antiga

