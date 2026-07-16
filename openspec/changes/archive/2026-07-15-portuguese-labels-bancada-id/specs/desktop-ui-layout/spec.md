## ADDED Requirements

### Requirement: Métricas com rótulos em português
Telas de formulário e dashboard SHALL exibir rótulos de métricas em português (Rendimento, Total testadas, Aprovadas, Reprovadas, Pendentes).

#### Scenario: Painel de produção
- **WHEN** o operador visualiza o painel de produção
- **THEN** o percentual de aprovação é rotulado "Rendimento" e demais métricas usam termos em português
