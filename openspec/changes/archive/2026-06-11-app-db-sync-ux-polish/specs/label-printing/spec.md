## ADDED Requirements

### Requirement: Buffer de etiquetas reativo na UI
A tela de Etiquetas SHALL refletir automaticamente inserções e remoções no buffer local, incluindo o contador do badge, sem exigir navegação ou recarga manual.

#### Scenario: Novo serial no buffer
- **WHEN** um serial aprovado é adicionado ao buffer enquanto a tela de Etiquetas está aberta
- **THEN** a lista e o contador do badge são atualizados imediatamente

#### Scenario: Impressão remove entradas
- **WHEN** um bloco de etiquetas é impresso com sucesso e removido do buffer
- **THEN** a lista na tela de Etiquetas reflete a remoção sem recarregar a tela
