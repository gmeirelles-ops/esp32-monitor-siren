## MODIFIED Requirements

### Requirement: Cálculo do dígito verificador e serial pelo App Web
O cálculo do dígito verificador ITF 2 de 5 e a montagem do serial completo SHALL ser realizados pelo App Flutter a partir do sequencial aprovado.

#### Scenario: Geração do serial após aprovação
- **WHEN** o App Flutter recebe a confirmação de aprovação com o sequencial consumido
- **THEN** o App Flutter calcula o dígito verificador e gera o número de série completo de 10 dígitos
