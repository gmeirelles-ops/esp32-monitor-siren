## MODIFIED Requirements

### Requirement: Cálculo do dígito verificador e serial pelo App Web
O cálculo do dígito verificador ITF 2 de 5 e a montagem do serial completo SHALL ser realizados pelo App Flutter a partir do sequencial aprovado, verificando a unicidade do serial antes de emitir a etiqueta.

#### Scenario: Geração do serial após aprovação
- **WHEN** o App Flutter recebe a confirmação de aprovação com o sequencial consumido
- **THEN** o App Flutter calcula o dígito verificador e gera o número de série completo de 10 dígitos

#### Scenario: Serial inédito é emitido
- **WHEN** o serial gerado não existe no histórico local
- **THEN** o app registra o resultado e adiciona o serial ao buffer de etiquetas

#### Scenario: Serial duplicado é bloqueado
- **WHEN** o serial gerado já existe no histórico local
- **THEN** o app não adiciona o serial ao buffer de etiquetas e sinaliza o conflito ao operador
