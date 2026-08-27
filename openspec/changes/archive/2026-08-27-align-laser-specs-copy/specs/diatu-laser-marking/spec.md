## ADDED Requirements

### Requirement: Glossário Diaotu vs DiatuCAD
A documentação e a capability SHALL distinguir: **Diaotu** = marca/modelo do laser (ex. B3); **DiatuCAD** = software de job e cliente TCP; APIs do app usam prefixo `Diatu*`. O produto SHALL NOT tratar “Diaotu” como erro ortográfico de “Diatu”.

#### Scenario: Operador lê referência laser
- **WHEN** consulta `docs/laser-reference/`
- **THEN** encontra o glossário e instruções de desativar Marca de controlo TCP no Diaotu sem confundir com DiatuCAD
