## ADDED Requirements

### Requirement: Geração de PDF com layout Diponto
O app SHALL gerar relatórios em PDF com cabeçalho Diponto, metadados do filtro, tabela legível e rodapé com data de geração.

#### Scenario: PDF da lista de lotes
- **WHEN** o operador solicita PDF na tela Relatório com lotes filtrados
- **THEN** o app gera PDF A4 com tabela de OPs, totais, aprovados, reprovados e yield

#### Scenario: PDF do detalhe do lote
- **WHEN** o operador solicita PDF no detalhe de um lote
- **THEN** o app gera PDF com resumo do lote e tabela de sirenes testadas conforme filtros ativos

### Requirement: Impressão e salvamento de PDF
O app SHALL abrir diálogo de impressão do sistema para o PDF gerado e permitir salvar o arquivo em pasta local de relatórios.

#### Scenario: Imprimir PDF
- **WHEN** o operador confirma impressão no diálogo
- **THEN** o sistema de impressão do Windows recebe o documento PDF

#### Scenario: Salvar PDF
- **WHEN** o operador escolhe salvar em vez de imprimir
- **THEN** o PDF é gravado em `Documents/relatorios/` com nome contendo OP ou `lotes` e timestamp

### Requirement: Conteúdo mínimo do PDF
O PDF SHALL incluir: título "Relatório de Produção", período/filtros aplicados, nome do operador da sessão (quando disponível) e tabela com colunas definidas para o tipo de relatório.

#### Scenario: Metadados no cabeçalho
- **WHEN** um PDF é gerado com filtro de produto ativo
- **THEN** o cabeçalho do PDF menciona o produto filtrado
