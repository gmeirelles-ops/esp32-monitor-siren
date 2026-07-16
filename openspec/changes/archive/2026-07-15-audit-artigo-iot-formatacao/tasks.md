## 1. Preparação e auditoria inicial

- [x] 1.1 Fazer backup de `ARTIGO - IoT (revisado).docx` antes de qualquer alteração
- [x] 1.2 Documentar baseline: executar análise comparativa modelo vs artigo (estilos, margens, seções)
- [x] 1.3 Confirmar que `python-docx` está disponível no ambiente de geração

## 2. Script de auditoria

- [x] 2.1 Criar `scripts/audit_artigo_formatacao.py` com validações de estilos Word obrigatórios
- [x] 2.2 Adicionar checagens de elementos proibidos (cabeçalho SENAI, Abstract EN, paginação)
- [x] 2.3 Adicionar checagens de resumo (`Resumo—`, sem siglas, 100–250 palavras) e palavras-chave (3–5, vírgulas)
- [x] 2.4 Adicionar checagens de autoria (autor | orientador), títulos sentence case e referências
- [x] 2.5 Executar auditoria contra o artigo atual e confirmar que reporta violações (baseline não conforme)

## 3. Refatoração do gerador

- [x] 3.1 Refatorar `scripts/generate_artigo_revisado.py` para carregar `ANEXO 5A - MODELO DE ARTIGO - AUTOR ÚNICO (2).docx` como template
- [x] 3.2 Implementar limpeza do conteúdo instrucional do modelo (texto de exemplo)
- [x] 3.3 Implementar preenchimento: título (`paper title`), tabela autor/orientador, resumo e palavras-chave
- [x] 3.4 Mapear seções com estilos corretos: `Heading 1`, `Heading 2`, `Body Text`, citação longa Groover
- [x] 3.5 Mapear metodologia (itens 1–4), legendas `Fig. N.` (`figure caption`) e Tabela I (`table head`)
- [x] 3.6 Mapear conclusão e referências (`Heading 5` + estilo `references`)
- [x] 3.7 Remover código legado: cabeçalho SENAI, Abstract EN, formatação manual `_font`/`p_center`, paginação

## 4. Ajustes de conteúdo normativos

- [x] 4.1 Reescrever resumo sem siglas, mantendo sentido técnico e 100–250 palavras
- [x] 4.2 Reduzir palavras-chave para 5 termos com vírgulas e minúsculas
- [x] 4.3 Garantir definição de siglas na 1ª ocorrência no corpo (IoT, MQTT, etc.)

## 5. Geração e validação final

- [x] 5.1 Gerar `ARTIGO - IoT (revisado).docx` com o script refatorado
- [x] 5.2 Executar `scripts/audit_artigo_formatacao.py` e corrigir até saída zero
- [x] 5.3 Revisão visual no Word: comparar lado a lado com ANEXO 5A (margens, colunas, estilos)
- [x] 5.4 Entregar documento final conforme spec `artigo-iot-formatacao`
