## Context

O repositório contém o artigo acadêmico sobre o sistema IoT de validação de sirenes e um script Python ([`scripts/generate_artigo_revisado.py`](../../../scripts/generate_artigo_revisado.py)) que gera o `.docx` com formatação manual. O modelo oficial é o [`ANEXO 5A - MODELO DE ARTIGO - AUTOR ÚNICO (2).docx`](../../../ANEXO%205A%20-%20MODELO%20DE%20ARTIGO%20-%20AUTOR%20%C3%9ANICO%20(2).docx), baseado em estilos Word IEEE/SENAI.

**Auditoria realizada** (comparação programática via `python-docx`):

| Critério | ANEXO 5A (modelo) | Artigo revisado (atual) | Conforme? |
|---|---|---|---|
| Estilos Word | `paper title`, `Abstract`, `Keywords`, `Heading 1/2/5`, `Body Text`, `references`, `table head`, `figure caption` | 56 parágrafos em `Normal` com fontes manuais | **Não** |
| Cabeçalho SENAI | Ausente | 3 linhas (Calibri 21,5 / Arial 6,5) | **Não** |
| Autoria | Tabela 2 colunas: Autor \| Orientador | Gabriel + Dirlei como coautores | **Não** |
| Resumo | `Resumo—` (travessão sem espaço), sem siglas | `Resumo —` com espaços; contém IoT, ESP32, PZEM-004T, MQTT | **Não** |
| Palavras-chave | 3–5 termos, vírgulas, minúsculas | 7 termos com `;` | **Não** |
| Abstract EN | Ausente | Presente | **Não** |
| Títulos de seção | Sentence case (`Introdução`) | MAIÚSCULAS (`INTRODUÇÃO`) | **Não** |
| Subseções | `Heading 2` itálico | MAIÚSCULAS manuais (Arial/TNR 12–13) | **Não** |
| Citação longa | Estilo `02 - Citação longa` | Parágrafo `Normal` com aspas | **Não** |
| Figuras | `Fig. N.` + `figure caption` (TNR 8) | `[Inserir figura: Figura N – …]` centralizado Arial 9 | **Não** |
| Tabela | `table head`, romano (`Tabela I`) | `TABELA I` manual Arial 10 | **Parcial** |
| Referências | `Heading 5` + estilo `references` (TNR 8) | `REFERÊNCIAS` + numeração manual Arial 10 | **Não** |
| Margens | 1,58 cm laterais; topo 2,25 cm (1ª seção) | 1,80 cm uniforme | **Não** |
| Seções | 4 seções com quebras do modelo | 2 seções | **Não** |
| Paginação | Modelo orienta não adicionar | Rodapé com número de página | **Não** |
| Conteúdo técnico | — | Completo (introdução, referencial, metodologia, resultados, conclusão, 8 refs) | **Sim** |

**Conclusão da auditoria:** o artigo **não está** estritamente conforme o ANEXO 5A. O conteúdo científico está adequado; a não conformidade é quase inteiramente de **envelope editorial**.

## Goals / Non-Goals

**Goals:**

- Reformatar o artigo para conformidade estrita com o ANEXO 5A.
- Preservar o conteúdo técnico existente (texto, dados da Tabela I, referências ABNT).
- Automatizar geração e auditoria para evitar regressões.
- Documentar checklist de conformidade reproduzível.

**Non-Goals:**

- Reescrever o argumento científico ou expandir a pesquisa.
- Inserir imagens reais das figuras (permanecem placeholders com legenda correta).
- Alterar firmware, app ou infraestrutura do produto.
- Criar versão bilíngue (Abstract em inglês não faz parte do modelo).

## Decisions

### 1. Usar o ANEXO 5A como documento base (não gerar do zero)

**Decisão:** Copiar o `.docx` do modelo e substituir conteúdo instrucional pelo texto do artigo, aplicando estilos por nome.

**Rationale:** Garante margens, quebras de seção, numeração hierárquica e estilos customizados (`Abstract`, `02 - Citação longa`, etc.) idênticos ao modelo. Gerar do zero com `python-docx` (abordagem atual) produz documento visualmente similar mas estruturalmente diferente.

**Alternativa descartada:** Edição manual única no Word — não reproduzível e sujeita a regressão.

### 2. Autoria autor único + orientador

**Decisão:** Gabriel na coluna Autor; Dirlei na coluna Orientador, conforme confirmação do autor e placeholder do modelo.

### 3. Ajustes normativos de resumo e palavras-chave

**Decisão:**
- Reescrever resumo removendo siglas (usar termos por extenso).
- Reduzir para 5 palavras-chave: `automação industrial, internet das coisas, controle de qualidade, sistemas embarcados, manufatura eletrônica`.
- Formato: `Resumo—` e `Palavras-chave: termo1, termo2, …`.

### 4. Script de auditoria separado

**Decisão:** Criar `scripts/audit_artigo_formatacao.py` que valida estilos, presença/ausência de elementos e regras do resumo; retorna lista de violações com código de saída ≠ 0 se houver falhas.

**Rationale:** Permite verificar conformidade antes de entrega sem abrir o Word.

### 5. Refatorar `generate_artigo_revisado.py`

**Decisão:** O script passa a carregar o template ANEXO 5A, limpar texto de exemplo e popular com conteúdo mapeado. Remove helpers de formatação manual (`_font`, `p_center`, cabeçalho SENAI, `add_page_number_footer`, Abstract EN).

## Risks / Trade-offs

| Risco | Mitigação |
|---|---|
| `python-docx` não preserva 100% dos estilos ao editar | Usar template como base; validar com script de auditoria + revisão visual no Word |
| Quebras de coluna em figuras/tabelas largas | Seguir posicionamento do modelo (topo/base da coluna); placeholders não forçam span de 2 colunas |
| Resumo sem siglas pode parecer menos técnico | Siglas permanecem no corpo com definição na 1ª ocorrência (regra do modelo) |
| Figuras sem imagens reais | Manter legendas `Fig. N.` formatadas; inserção de imagens fica fora do escopo |

## Migration Plan

1. Refatorar script de geração.
2. Gerar novo `ARTIGO - IoT (revisado).docx`.
3. Executar auditoria automatizada.
4. Revisão visual lado a lado com ANEXO 5A no Word.
5. Entregar `.docx` final; PDF opcional para impressão.

**Rollback:** Manter cópia do artigo revisado atual antes de sobrescrever.

## Open Questions

- Nenhuma pendente crítica. Figuras reais podem ser inseridas manualmente após a formatação, se o autor tiver os diagramas prontos.
