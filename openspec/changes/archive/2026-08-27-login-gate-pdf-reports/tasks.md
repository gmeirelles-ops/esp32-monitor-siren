## 1. Login de operador (consolidação)

- [ ] 1.1 Revisar `AppGate` e `OperatorLoginScreen`: garantir que `home` do app sempre passa pelo gate
- [ ] 1.2 Tratar operador desativado com sessão antiga (invalidar e voltar ao login)
- [ ] 1.3 Polir UX da login: logo Diponto, feedback visual de seleção, loading ao entrar
- [ ] 1.4 Confirmar troca de operador em Configurações limpa sessão e exibe login
- [ ] 1.5 Widget tests do fluxo login (PIN ok/erro, bootstrap sem operadores)

## 2. Dependências PDF

- [ ] 2.1 Adicionar `pdf` e `printing` ao `pubspec.yaml`
- [ ] 2.2 Criar `batch_report_pdf.dart` com builders para lista de lotes e detalhe

## 3. Layout PDF Diponto

- [ ] 3.1 Implementar cabeçalho amber, metadados (período, filtros, operador, data)
- [ ] 3.2 Tabela zebrada para lista de OPs (totais, yield)
- [ ] 3.3 Tabela de sirenes no detalhe do lote (serial, veredito, potência, operador, data)
- [ ] 3.4 Rodapé com numeração de página e texto Diponto

## 4. Integração na UI do relatório

- [ ] 4.1 Substituir botão único de exportação por menu PDF (primário) + CSV (secundário) na lista de lotes
- [ ] 4.2 Mesmo menu no detalhe do lote
- [ ] 4.3 `Printing.layoutPdf` para preview/impressão Windows
- [ ] 4.4 Salvar PDF em `Documents/relatorios/` com timestamp

## 5. Testes e validação

- [ ] 5.1 Testes unitários: PDF lista e detalhe geram bytes não vazios e contêm colunas esperadas
- [ ] 5.2 Executar `flutter test` nos módulos novos/alterados
- [ ] 5.3 Smoke manual: abrir app → login → Relatório → PDF de um lote
