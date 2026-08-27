## 0. Homologação Diatom (pré-código)

- [x] 0.1 Obter manual Diatom: modelo, software de controle, protocolo TCP/RS-232
- [ ] 0.2 Criar template de gravação com campo variável `serial` (10 dígitos ITF)
- [ ] 0.3 Validar gravação física na carcaça da sirene (legibilidade, contraste)
- [x] 0.4 Documentar comando TCP em `docs/laser-reference/diatu-tcp.md`

## 1. Configuração e abstração

- [x] 1.1 Adicionar `MarkingMode`, `laser_tcp_port`, `laser_tcp_command` em `AppConfig`
- [x] 1.2 Criar interface `SerialMarkingBackend` + factory (`DiatuLaserTcpServer`)
- [x] 1.3 Implementar `DiatuLaserTcpServer` (TCP server, timeout, comando configurável)

## 2. Persistência e fila

- [x] 2.1 Migration Drift: tabela `mark_queue` (serial, numero_op, status, attempts, last_error, created_at)
- [x] 2.2 `MarkQueueProcessor` com retry periódico (similar SyncQueue)
- [x] 2.3 Testes unitários do backend TCP (mock server)

## 3. Integração no fluxo de teste

- [x] 3.1 `processTestResult`: se modo laser → fila mark_queue em vez de label buffer
- [x] 3.2 Reteste aprovado: sem serial/gravação (comportamento atual)
- [x] 3.3 END_BATCH: flush fila laser pendente (opcional forçar retry)

## 4. UI

- [x] 4.1 Configurações: seletor modo + seção laser (porta, comando, testar)
- [x] 4.2 Tela Gravação (modo laser) ou adaptar Etiquetas com layout condicional
- [x] 4.3 Regravação manual por serial do histórico
- [x] 4.4 Provider de falha de gravação (badge + alerta)

## 5. Documentação

- [x] 5.1 `docs/laser-reference/README.md` — template, homologação, TCP
- [x] 5.2 Atualizar `docs/PRODUCAO.md` — posto com laser vs etiquetas
- [x] 5.3 Atualizar `sirene_app/README.md`

## 6. Validação

- [ ] 6.1 Teste manual: aprovar sirene → serial gravado no laser
- [ ] 6.2 Teste manual: falha TCP → fila pendente + retry
- [x] 6.3 `flutter test` passando nos novos módulos
