## MODIFIED Requirements

### Requirement: Cadastro de produto sem campo manual de gravação
O formulário de produto SHALL permitir editar identificação, nome, potências, tolerância, tempo de teste e sequencial. SHALL NOT exibir campo “Manual do produto” para envio ao laser. Persistência e sync MAY manter a coluna/campo legado vazio.

#### Scenario: Criar ou editar produto
- **WHEN** o operador salva um produto pelo formulário
- **THEN** o app persiste os campos visíveis e não exige nem envia texto de manual para a gravação laser
