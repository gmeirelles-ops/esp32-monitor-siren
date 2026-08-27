## MODIFIED Requirements

### Requirement: Tokens de largura desktop
O app SHALL definir e usar tokens em `layout.dart`: formulários ≤ `kFormMaxWidth` (600), páginas de conteúdo operacional ≤ `kPageContentMaxWidth` (900), breakpoint desktop 900. Painel analítico do gestor MAY usar largura maior documentada.

#### Scenario: Lote em monitor wide
- **WHEN** o operador abre Lote em janela ≥ 900 px
- **THEN** o formulário não estica além de `kFormMaxWidth` (centralizado ou alinhado conforme `ScreenPageLayout`/`DesktopFormLayout`)

### Requirement: Densidade do formulário de Lote
Campos principais do lote (OP, quantidade; ano se editável) SHALL compartilhar linha em desktop via `ResponsiveFieldRow` (ou equivalente). Limites do produto SHALL aparecer de forma compacta (não grade verbosa).

#### Scenario: Preencher OP e quantidade
- **WHEN** o operador preenche o lote em desktop
- **THEN** OP e quantidade aparecem na mesma linha
