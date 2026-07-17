## MODIFIED Requirements

### Requirement: Configuração laser sem comando de manual
Em modo Gravação laser, a tela de Configurações SHALL permitir editar porta TCP, comando de serial e comando de modelo. SHALL NOT exibir campo de comando TCP de manual. Textos de ajuda e diagnóstico SHALL descrever o ciclo serial + modelo apenas.

#### Scenario: Salvar comandos laser
- **WHEN** o operador salva porta, comando de serial e comando de modelo válidos e distintos
- **THEN** o app persiste a configuração e reinicia o servidor TCP sem referências a comando manual

#### Scenario: Diagnóstico
- **WHEN** o operador usa simulação no painel de diagnóstico laser
- **THEN** há ações para simular serial e modelo, sem simular manual
