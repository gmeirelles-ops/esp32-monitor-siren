## 1. Navegação operador

- [x] 1.1 Remover Consulta do `_navEntries` do operador (`app.dart`) — só Lote + Gravação
- [x] 1.2 Ajustar índice seguro / testes de shell se existirem

## 2. Tokens e formulário Lote

- [x] 2.1 Adicionar `kPageContentMaxWidth` em `layout.dart`; aplicar em Lote/Gravação
- [x] 2.2 Simplificar `BatchScreen`: menos cards, `ResponsiveFieldRow`, limites compactos, CTA claro
- [x] 2.3 Revisar copy do intro Lote (texto curto, sem jargão)

## 3. Painel ao vivo (operador)

- [x] 3.1 Hierarquia: hero > progresso > pedal; diagnóstico só gestor
- [x] 3.2 Mensagem de pedal visível acima da dobra quando `mark_queue` pendente
- [x] 3.3 Copy leiga (aguardando botão / aprovado / reprovado)

## 4. Gravação + copy pedal

- [x] 4.1 Helper único de copy do operador (pedal); atualizar callout, labels_screen, remark, batch_live, dialogs
- [x] 4.2 Empty/pending states com instrução de pedal; largura via token
- [x] 4.3 Nota curta em `docs/laser-reference`: no posto o gatilho é o pedal

## 5. Specs + verificação

- [x] 5.1 Sync deltas → `openspec/specs/`
- [x] 5.2 Atualizar testes que assertam “F2” na UI de operador
- [x] 5.3 `flutter test`
