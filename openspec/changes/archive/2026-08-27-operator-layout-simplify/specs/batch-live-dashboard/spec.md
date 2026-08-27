## MODIFIED Requirements

### Requirement: Hierarquia visual do painel ao vivo para operador
Para operador (não gestor), o Batch Live SHALL priorizar: (1) veredito grande APROVADO/REPROVADO, (2) progresso do lote, (3) orientação **“Acione o pedal”** quando houver serial pendente na fila laser. Painéis de diagnóstico, gráficos e detalhes técnicos SHALL ser omitidos ou recolhidos para o operador. A UI do operador SHALL NOT pedir tecla F2.

#### Scenario: Após aprovação
- **WHEN** chega teste APROVADO e há serial na fila de gravação
- **THEN** o operador vê destaque de aprovação e instrução clara para acionar o **pedal**, sem precisar abrir outra aba

#### Scenario: Após reprovação
- **WHEN** chega teste REPROVADO
- **THEN** o veredito vermelho/grande indica falha e orienta novo teste no botão da bancada
