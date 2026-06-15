## 0. Homologação Diatom (pré-código)

- [ ] 0.1 Obter manual Diatom: modelo, software de controle, protocolo TCP/RS-232
- [ ] 0.2 Criar template de gravação com campo variável `serial` (10 dígitos ITF)
- [ ] 0.3 Validar gravação física na carcaça da sirene (legibilidade, contraste)
- [ ] 0.4 Documentar comando TCP em `docs/laser-reference/diatom-tcp.md`

## 1. Configuração e abstração

- [ ] 1.1 Adicionar `MarkingMode`, `laser_host`, `laser_port` em `AppConfig`
- [ ] 1.2 Criar interface `SerialMarkingBackend` + factory (`ZplLabelBackend`, `DiatomLaserBackend`)
- [ ] 1.3 Implementar `DiatomLaserBackend` (TCP, timeout, template configurável)

## 2. Persistência e fila

- [ ] 2.1 Migration Drift: tabela `mark_queue` (serial, numero_op, status, attempts, last_error, created_at)
- [ ] 2.2 `MarkQueueProcessor` com retry periódico (similar SyncQueue)
- [ ] 2.3 Testes unitários do backend TCP (mock server)

## 3. Integração no fluxo de teste

- [ ] 3.1 `processTestResult`: se modo laser → `_maybeMarkSerial` em vez de `_maybePrintLabels`
- [ ] 3.2 Reteste aprovado: sem serial/gravação (comportamento atual)
- [ ] 3.3 END_BATCH: flush fila laser pendente (opcional forçar retry)

## 4. UI

- [ ] 4.1 Configurações: seletor modo + seção laser (host, porta, testar)
- [ ] 4.2 Tela Gravação (modo laser) ou adaptar Etiquetas com layout condicional
- [ ] 4.3 Regravação manual por serial do histórico
- [ ] 4.4 Provider de falha de gravação (badge + alerta)

## 5. Documentação

- [ ] 5.1 `docs/laser-reference/README.md` — template, homologação, TCP
- [ ] 5.2 Atualizar `docs/PRODUCAO.md` — posto com laser vs etiquetas
- [ ] 5.3 Atualizar `sirene_app/README.md`

## 6. Validação

- [ ] 6.1 Teste manual: aprovar sirene → serial gravado no laser
- [ ] 6.2 Teste manual: falha TCP → fila pendente + retry
- [ ] 6.3 `flutter test` passando nos novos módulos
