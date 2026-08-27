## ADDED Requirements

### Requirement: Ações de backup na Manutenção
A categoria **Manutenção** das Configurações SHALL expor ações "Fazer backup" e "Restaurar backup" acessíveis ao perfil gestor (mesmo gate das demais configs administrativas).

#### Scenario: Gestor abre Manutenção
- **WHEN** o gestor navega para Configurações → Manutenção
- **THEN** vê os botões de backup e restore além das ações já existentes (ex.: factory reset)
