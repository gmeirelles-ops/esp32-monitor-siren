## 1. Helpers de ano e sequencial

- [x] 1.1 Implementar `resolveBatchYear()` em `batch_serial_logic.dart` (2 dígitos de `DateTime.now().year`)
- [x] 1.2 Implementar `resolveProximoSequencial(db, idProduto, ano)` consultando `SerialCounters`
- [x] 1.3 Testes unitários em `batch_serial_logic_test.dart` para ano, sequencial e virada de ano

## 2. AppConfig e migração de setup

- [x] 2.1 Adicionar `bancadaSetupComplete` e `wifiProvisioned` em `app_config.dart` (get/set)
- [x] 2.2 Na primeira leitura pós-update: se `selectedDeviceId` existir e `bancadaSetupComplete` ausente, setar `true`
- [x] 2.3 Provider `bancadaSetupCompleteProvider` (ou estender `selectedDeviceIdProvider`)

## 3. Tela de setup de posto (bancada)

- [x] 3.1 Criar `posto_setup_screen.dart` com lista de dispositivos MQTT detectados e botão Confirmar
- [x] 3.2 Ao confirmar: persistir `selectedDeviceId`, `bancadaSetupComplete = true`, navegar ao shell
- [x] 3.3 Estado vazio: mensagem "Aguardando bancada" + link para assistente Wi-Fi (não bloqueante)

## 4. Gate no app shell

- [x] 4.1 Em `app.dart`: após login, se `!bancadaSetupComplete` → `PostoSetupScreen` em vez de shell
- [x] 4.2 Garantir que MQTT pipeline inicia antes/durante setup para detectar dispositivos

## 5. Simplificar tela de Lote

- [x] 5.1 Remover campos visíveis `Ano` e `Próximo sequencial` de `batch_screen.dart`
- [x] 5.2 Substituir dropdown de bancada por card read-only (rótulo + status online/offline)
- [x] 5.3 Link "Alterar em Configurações" no card de bancada (não editável na Lote)
- [x] 5.4 Em `_buildBatch` / envio SET_BATCH: usar `resolveBatchYear()` e `resolveProximoSequencial()`
- [x] 5.5 Bloquear "Configurar lote" se `!bancadaSetupComplete` com CTA para setup
- [x] 5.6 Mover painel de reconciliação de série para Configurações (Admin/Avançado) se ainda estiver na Lote

## 6. Configurações — Manutenção do posto

- [x] 6.1 Nova seção "Manutenção do posto" em `settings_screen.dart`
- [x] 6.2 Subseção Bancada: dropdown de dispositivos + Salvar (mesma lógica que existia na Lote)
- [x] 6.3 Subseção Wi-Fi: status `wifi_provisioned` + atalho ao `ProvisioningWizard`; marcar provisionado ao concluir assistente
- [x] 6.4 Botão destrutivo "Reset geral do posto" com confirmação digitando `ZERAR`

## 7. Factory reset service

- [x] 7.1 Criar `factory_reset_service.dart`: fechar DB, apagar `sirene_app.sqlite`, limpar SharedPreferences operacionais
- [x] 7.2 Limpar `sessionOperatorIdProvider`, `selectedDeviceId`, `bancadaSetupComplete`, `wifiProvisioned`
- [x] 7.3 Checkbox opcional "Sair da nuvem também" (Firebase logout) — default desligado
- [x] 7.4 Após reset: diálogo orientando fechar/reabrir app ou hot restart; redirecionar ao login
- [x] 7.5 Testes unitários/mocks para `FactoryResetService` (prefs limpos, flags resetadas)

## 8. Documentação e validação

- [x] 8.1 Atualizar `docs/PRODUCAO.md` com setup de posto, vínculo de bancada e reset geral
- [x] 8.2 Executar `flutter test` nos arquivos alterados e corrigir falhas
- [x] 8.3 Smoke manual: Lote sem campos ano/sequencial; setup bancada; reset → login + setup novamente
