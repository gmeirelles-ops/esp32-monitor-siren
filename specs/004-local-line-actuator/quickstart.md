# Quickstart: Validar decisão local e atuador

**Feature**: 004-local-line-actuator  
**Pré-requisitos**: Bancada com firmware ≥ **1.8.0**, PZEM OK, lote configurado.

## 1. Confirmar baseline (já funciona hoje)

1. Inicie lote no app com limites conhecidos.
2. Pressione botão com sirene na faixa.
3. Observe LED verde **antes** do snackbar/etiqueta no app.
4. Desligue Wi-Fi do roteador **após** lote ativo.
5. Execute teste — LED e relé devem responder; ao religar Wi-Fi, `tipo:teste` aparece no broker (fila offline).

**Esperado**: Veredito físico sem nuvem.

## 2. Latência GPIO (após FW-B)

1. Osciloscópio ou LED no `GPIO_REJECT`.
2. Reproduza peça fora da faixa.
3. Meça: fim da última amostra PZEM → borda de subida do pulso.

**Esperado**: &lt; 50 ms.

## 3. Benchmark PZEM (após FW-A)

```text
# No monitor serial firmware (tag pzem)
# Comparar tempo entre logs de início/fim de leitura — 100 amostras
```

**Esperado**: redução ≥ 30% vs baseline 1.7.7.

## 4. Dual-core stress (após FW-C)

1. Inicie teste de 10 s.
2. Durante teste, force reconnect Wi-Fi (portal ou reiniciar AP).
3. Verifique que ciclo não trava e veredito sai no fim.

**Esperado**: Sem watchdog reset; duração do ciclo ±5%.

## 5. Regressão app

```powershell
cd sirene_app
flutter test test/mqtt_parser_test.dart test/mqtt_verdict_trust_test.dart test/batch_live_screen_test.dart
```

**Esperado**: App continua confiando em `veredito` sem recalcular.

## Critério de aceite da feature

Registrar resultados em [bench-results.md](./bench-results.md).

- [ ] 10 testes com broker down: contadores NVS corretos
- [ ] Pulso refugo em reprovado (hardware)
- [ ] `verdict_gpio_latency_us` &lt; 50 ms (log serial)
- [ ] Documentação pinagem em `board_config.h` / Kconfig
- [ ] PZEM fast read ≥ 30% mais rápido (bench)
- [ ] Nenhuma regressão `001-fw-sw-compat` SC-001
