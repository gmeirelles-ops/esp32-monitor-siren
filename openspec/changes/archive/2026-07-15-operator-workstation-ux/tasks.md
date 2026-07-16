## 1. Schema e operadores

- [x] 1.1 Migration v9: tabela `operators` (codigo unique, nome, ativo, created_at)
- [x] 1.2 CRUD Drift + providers (`operatorsProvider`, `activeOperatorProvider` + SharedPreferences)
- [x] 1.3 Testes unitários: insert, código duplicado, ativo/inativo

## 2. Cadastros unificados

- [x] 2.1 Criar `CadastrosScreen` com TabBar Produtos | Operadores
- [x] 2.2 Extrair lista/form de produtos para aba; criar `OperatorFormScreen` / lista
- [x] 2.3 Remover entrada "Produtos" isolada da nav (substituída por Cadastros)

## 3. Shell e navegação

- [x] 3.1 Reordenar nav: Lote (default 0), Painel, Etiquetas, Cadastros, Configurações
- [x] 3.2 Remover Dispositivos e Admin da nav principal
- [x] 3.3 `DipontoAppBar` no mobile; chip operador ativo + MQTT na AppBar
- [x] 3.4 Configurações: links "Dispositivos" e "Administração (OTA)"
- [x] 3.5 Mover provisionamento Wi-Fi para Config → Dispositivos ou AppBar global

## 4. Tela Lote (workstation)

- [x] 4.1 Seções FormSectionCard: Turno, Bancada, Produto/OP, Ações
- [x] 4.2 Seletor de operador; bloquear SET_BATCH sem operador
- [x] 4.3 Dropdown dispositivo com indicador online/offline
- [x] 4.4 `processTestResult` usa operador ativo local (fallback e-mail Firebase)

## 5. Layout e alertas

- [x] 5.1 `PrintFailureBanner` global no shell (MaterialBanner)
- [x] 5.2 Revisar espaçamento/cards em Batch Live e Painel para consistência

## 6. Testes e verificação

- [x] 6.1 Widget test: Cadastros abas, seletor operador no Lote
- [x] 6.2 `flutter test` passando
- [x] 6.3 Smoke posto: selecionar operador → lote → teste grava operador no SQLite

## 7. Hotfix pós-implementação

- [x] 7.1 Corrigir layout do dropdown de dispositivo (`Expanded` em `DropdownMenuItem` causava crash na tela Lote)
