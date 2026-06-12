## 1. Dados e migrations (Drift)

- [ ] 1.1 Criar tabela `operators` (id, nome, matricula, ativo, criadoEm)
- [ ] 1.2 Adicionar colunas `operadorId` e `operadorNome` em `batches` e `test_results`
- [ ] 1.3 Implementar `OperatorRepository` (CRUD, listActive, findById)
- [ ] 1.4 Escrever migration Drift e testar com DB existente

## 2. Operador — sessão e seleção

- [ ] 2.1 Criar `OperatorSessionProvider` com persistência em SharedPreferences
- [ ] 2.2 Criar `OperatorPickerDialog` / bottom sheet para seleção rápida
- [ ] 2.3 Adicionar chip de operador no `AppShell` header (tap para trocar)
- [ ] 2.4 Bloquear `SET_BATCH` e retomada de lote sem operador selecionado

## 3. Cadastros unificados

- [ ] 3.1 Criar `CadastrosPage` com TabBar Produtos / Operadores
- [ ] 3.2 Migrar listagem e formulário de produtos para aba Produtos
- [ ] 3.3 Criar `OperatorListPage` com busca, criar, editar e desativar
- [ ] 3.4 Adicionar validação de matrícula única e nome obrigatório

## 4. Navegação e fluxo lote-primeiro

- [ ] 4.1 Alterar `initialLocation` do router para `/lote`
- [ ] 4.2 Remover Dispositivos da navegação primária (drawer/rail/bottom)
- [ ] 4.3 Criar `SettingsDeviceSection` com descoberta MQTT e seleção de device_id
- [ ] 4.4 Extrair/mover lógica de `DevicesPage` para seção de Configurações
- [ ] 4.5 Exibir banner em Lote quando device_id não configurado (CTA → Configurações)

## 5. Tela de Lote — hub operacional

- [ ] 5.1 Criar `PostoSummaryCard` (operador, dispositivo, broker, impressora)
- [ ] 5.2 Consolidar formulário de lote + dashboard ao vivo na mesma rota
- [ ] 5.3 Vincular operador ativo ao enviar `SET_BATCH` e ao persistir lote local
- [ ] 5.4 Incluir operador em cada `test_result` salvo e na fila de etiquetas

## 6. App shell e layout

- [ ] 6.1 Definir tokens de tema em `lib/core/theme/app_spacing.dart` e extensões de `ThemeData`
- [ ] 6.2 Criar `EmptyStateCard` e aplicar em Lote, Cadastros e Configurações
- [ ] 6.3 Criar indicadores MQTT/dispositivo no cabeçalho global (`StatusChip`)
- [ ] 6.4 Padronizar snackbars de sucesso/erro para ações MQTT, impressão e sync
- [ ] 6.5 Revisar padding, tipografia e hierarquia nas telas principais

## 7. Sync Firestore (opcional / quando habilitado)

- [ ] 7.1 Enfileirar operadores em `SyncQueue` → coleção `operators`
- [ ] 7.2 Incluir `operador_id` e `operador_nome` em payloads de `batches` e `test_results`
- [x] 7.3 Atualizar `firebase/firestore.rules` para coleção `operators`
- [x] 7.4 Atualizar `firebase/firestore.indexes.json` se necessário

## 8. Documentação e validação

- [x] 8.1 Atualizar `docs/GUIA_COMPLETO.md` seção 15 (fluxo, cadastros, operador)
- [x] 8.2 Atualizar `docs/TESTING.md` com cenários de seleção de operador
- [ ] 8.3 Testar fluxo completo: selecionar operador → configurar lote → aprovar → etiqueta
- [ ] 8.4 Testar migração SQLite em banco com dados de produção simulados
- [ ] 8.5 `flutter analyze` e `flutter test` sem regressões
