## 1. Firmware — amostras de calibração

- [x] 1.1 Refatorar `pzem_measure_cycle` (ou loop em `handle_start_calibration`) para publicar `calibracao_amostra` a cada 500 ms após inrush
- [x] 1.2 Manter publicação final `tipo: "calibracao"` com `potencia_media` inalterada
- [x] 1.3 Bump `FIRMWARE_VERSION` para 1.2.0 em `board_config.h`
- [x] 1.4 Atualizar `GUIA_COMPLETO.md` e `TESTING.md` com contrato de amostras
- [x] 1.5 Compilar firmware e validar com `mosquitto_sub` no tópico `calibracao`

## 2. App — banco de dados e modelos

- [x] 2.1 Adicionar tabela `Products` no Drift com migração schema v1→v2
- [x] 2.2 Implementar CRUD: listar, criar, editar, recalibrar produtos
- [x] 2.3 Criar `products_provider` (Riverpod) com stream da lista de produtos
- [x] 2.4 Implementar função `calcularLimites(ref, toleranciaPct)` com arredondamento 2 casas

## 3. App — MQTT calibração ao vivo

- [x] 3.1 Estender `MqttParser` para `calibracao_amostra` (`potencia_w`, `elapsed_ms`)
- [x] 3.2 Criar stream/provider de amostras de calibração por `device_id`
- [x] 3.3 Sinalizar conclusão ao receber `tipo: "calibracao"` final

## 4. App — tela Cadastro de Produtos

- [x] 4.1 Criar `features/products/products_screen.dart` com lista de produtos
- [x] 4.2 Criar `product_form_screen.dart`: id, nome, tolerância %, tempo teste, seletor de dispositivo
- [x] 4.3 Botão "Medir peça padrão" com painel ao vivo (amostra atual + sparkline + progresso 5 s)
- [x] 4.4 Ao concluir: preencher ref/min/max, permitir ajuste manual, salvar no SQLite
- [x] 4.5 Botão "Recalibrar" em produto existente
- [x] 4.6 Adicionar seção "Produtos" na navegação (`app.dart`)

## 5. App — integração com lote

- [x] 5.1 Substituir campos manuais de id/min/max/tempo por dropdown de produto em `batch_screen.dart`
- [x] 5.2 Exibir limites como somente leitura ao selecionar produto
- [x] 5.3 Mensagem orientativa quando catálogo vazio
- [x] 5.4 Montar `SET_BATCH` a partir do produto selecionado

## 6. App — limpeza Admin

- [x] 6.1 Remover seção de calibração de `admin_screen.dart`
- [x] 6.2 Manter apenas OTA na tela Admin

## 7. Testes

- [x] 7.1 Teste unitário `calcularLimites` (ex.: 20,0 W ±10% → 18/22)
- [x] 7.2 Teste unitário parse `calibracao_amostra` no `mqtt_parser_test.dart`
- [x] 7.3 Teste widget/formulário de produto (validação id 3 dígitos)
- [x] 7.4 `flutter analyze` e `flutter test` passando

## 8. Produção e documentação

- [x] 8.1 Criar `docs/PRODUCAO.md` com checklist de deploy (firmware, broker, app Windows, cadastro SKUs)
- [ ] 8.2 Validar ciclo ponta a ponta em bancada: cadastro → lote → teste → serial → etiqueta
- [ ] 8.3 Build Windows release (`flutter build windows --release`) em máquina Windows
- [x] 8.4 Smoke test scripts `bench_mqtt_telemetry.sh` e calibração manual via portal
