## 1. Telemetria firmware

- [ ] 1.1 Contadores NVS: `reboot_count`, `watchdog_resets`
- [ ] 1.2 Estender JSON de heartbeat
- [ ] 1.3 Logs estruturados para eventos críticos

## 2. Host tests fila offline

- [ ] 2.1 Extrair/testar serialização da fila (tópico + payload)
- [ ] 2.2 Testes: FIFO, limite, entrada legada → tópico `status`
- [ ] 2.3 Integrar no `scripts/ci_local.sh`

## 3. App (opcional)

- [ ] 3.1 Parser e UI: exibir contadores no detalhe do dispositivo

## 4. Documentação

- [ ] 4.1 Procedimento de bancada: queda de energia durante lote em `docs/PRODUCAO.md`

## 5. Verificação

- [ ] 5.1 `ctest` passando
- [ ] 5.2 Smoke MQTT: novos campos no heartbeat
