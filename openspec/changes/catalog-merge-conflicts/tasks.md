## 1. Detecção de conflitos

- [ ] 1.1 `ProductMergeDiff` e `detectConflicts(local, remote)` puro
- [ ] 1.2 Testes unitários com pares local/remoto divergentes

## 2. CatalogCloudService

- [ ] 2.1 Refatorar `pull()` para retornar conflitos sem aplicar
- [ ] 2.2 `applyResolution(choices)` aplica upserts escolhidos

## 3. UI

- [ ] 3.1 Modal de conflitos em Configurações (pull manual e ao habilitar sync)
- [ ] 3.2 Ações: manter local, aceitar remoto, por produto e em lote

## 4. Verificação

- [ ] 4.1 `flutter test`
- [ ] 4.2 Smoke: dois postos com mesmo SKU e limites diferentes
