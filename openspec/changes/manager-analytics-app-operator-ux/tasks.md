## 1. Correções rápidas no app operador

- [x] 1.1 Renomear botão em `batch_screen.dart`: "Configurar lote (SET_BATCH)" → "INICIAR"
- [x] 1.2 Corrigir `ConnectionStatusBadge`: usar `mqttService.currentState` quando stream em loading
- [x] 1.3 Teste widget/unit: badge não mostra Desconectado com serviço connected
- [x] 1.4 Remover "Painel" da navegação em `app.dart`; ajustar índices das telas
- [x] 1.5 (Opcional) Card "Testes hoje" na tela Lote com contador simples

## 2. Scaffold app gestor

- [x] 2.1 Criar projeto `sirene_manager_app/` (Flutter Windows, Riverpod, Firebase)
- [x] 2.2 Copiar/referenciar `firebase_options`, tema Diponto, assets logo
- [x] 2.3 `ManagerLoginScreen` com Firebase Auth
- [x] 2.4 `ManagerShell` com AppBar (operador gestor + badge nuvem, não MQTT)

## 3. Firestore analytics

- [x] 3.1 `FirestoreAnalyticsRepository`: queries por período, OP, produto, station
- [x] 3.2 Agregações client-side: KPIs, throughput diário, yield diário, falhas HW
- [x] 3.3 Comparativos vs ontem / vs média nos cards
- [x] 3.4 Atualizar `firestore.rules` + `firestore.indexes.json` para role gestor
- [x] 3.5 Documentar custom claim `manager` ou coleção `managers`

## 4. UI dashboard gestor (mock)

- [x] 4.1 Filtros: Hoje / 7 dias / Tudo + dropdowns OP, Produto, Bancada
- [x] 4.2 Row de KPI cards com ícones e trends
- [x] 4.3 Gráfico barras empilhadas "Visão geral" (Testado + Aprovados)
- [x] 4.4 Gráfico linha/área "Rendimento diário" + linha meta 70%
- [x] 4.5 Tabela `Produção por lote` com status pills — **sem coluna Ações**
- [x] 4.6 Estado vazio e aviso sync desatualizado

## 5. Gráficos e polish

- [x] 5.1 Adicionar `fl_chart` ou extrair widgets de gráfico compartilháveis
- [x] 5.2 Layout desktop responsivo (max-width, cards em grid)
- [ ] 5.3 Tooltips nos gráficos (dia, testado, aprovados, rendimento)

## 6. Build e documentação

- [x] 6.1 Script build Windows para `sirene_manager_app`
- [x] 6.2 Atualizar `docs/PRODUCAO.md`: app operador vs app gestor
- [x] 6.3 Atualizar `README.md` com instruções do gestor
- [ ] 6.4 `flutter test` em ambos os apps; smoke manual gestor + operador INICIAR
