## ADDED Requirements

### Requirement: Serial não gerado em modo reteste
O app SHALL NOT gerar serial completo nem adicionar entrada ao buffer de impressão quando o resultado aprovado for processado em modo reteste.

#### Scenario: Aprovação em reteste sem serial
- **WHEN** chega `status` com `veredito: "APROVADO"` e modo reteste está ativo no app
- **THEN** nenhum serial de 10 dígitos é calculado e o buffer de etiquetas permanece inalterado

#### Scenario: Aprovação em produção gera serial
- **WHEN** chega `status` com `veredito: "APROVADO"` e modo reteste está inativo
- **THEN** o app gera serial e adiciona ao buffer conforme requisitos existentes
