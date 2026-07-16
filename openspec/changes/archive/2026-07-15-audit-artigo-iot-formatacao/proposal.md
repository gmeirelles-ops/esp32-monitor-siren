## Why

O artigo [`ARTIGO - IoT (revisado).docx`](../../../ARTIGO%20-%20IoT%20(revisado).docx) foi gerado com formatação manual (estilo `Normal`, fontes aplicadas à mão) e não segue estritamente o modelo institucional [`ANEXO 5A - MODELO DE ARTIGO - AUTOR ÚNICO (2).docx`](../../../ANEXO%205A%20-%20MODELO%20DE%20ARTIGO%20-%20AUTOR%20%C3%9ANICO%20(2).docx). Para submissão acadêmica, o documento precisa aderir aos estilos Word, margens, seções, resumo, autoria e convenções de figuras/tabelas/referências definidos no anexo — caso contrário há risco de reprovação na revisão editorial.

## What Changes

- Auditar o artigo revisado contra o ANEXO 5A e registrar todas as divergências de formatação e normas editoriais.
- Reformatar o artigo usando o próprio ANEXO 5A como base de estilos (não recriar formatação manualmente).
- Corrigir estrutura de autoria: **Gabriel da Silva Meirelles** (autor) e **Dirlei Ernane Bagestão** (orientador), conforme modelo de autor único.
- Ajustar resumo e palavras-chave às regras do modelo (`Resumo—`, sem siglas no resumo, 3–5 palavras-chave com vírgulas).
- Remover elementos ausentes no modelo: cabeçalho institucional SENAI no topo, Abstract/Keywords em inglês e paginação no rodapé.
- Aplicar estilos corretos em títulos (`Heading 1/2`), corpo (`Body Text`), citação longa, legendas (`Fig. N.`), tabela romana (`table head`) e referências (`references`).
- Refatorar [`scripts/generate_artigo_revisado.py`](../../../scripts/generate_artigo_revisado.py) para gerar o `.docx` a partir do template ANEXO 5A.
- Adicionar verificação automatizada (script de auditoria) para detectar regressões de formatação.

## Capabilities

### New Capabilities

- `artigo-iot-formatacao`: Requisitos de conformidade editorial do artigo IoT com o modelo ANEXO 5A (estilos Word, estrutura, resumo, autoria, figuras, tabelas e referências).

### Modified Capabilities

<!-- Nenhuma capability de software do produto é alterada; apenas documentação acadêmica. -->

## Impact

- **Arquivos**: `ARTIGO - IoT (revisado).docx`, `scripts/generate_artigo_revisado.py`, novo script de auditoria (ex.: `scripts/audit_artigo_formatacao.py`).
- **Dependências**: `python-docx` para geração e validação programática do `.docx`.
- **Sem impacto** em firmware, app Flutter, Firebase ou pipelines de release do sistema sirene.
