# MQTT Rejection Codes (006)

Publicados em `{site}/bancada-{NN}/status` quando comando ou botão é rejeitado.

## peca_ja_aprovada (novo — 006)

Emitido quando o operador pressiona o botão dentro da janela de cooldown após aprovação (default 5 s), sem modo reteste.

```json
{
  "tipo": "rejeicao",
  "motivo": "peca_ja_aprovada"
}
```

**Comportamento esperado**:
- Firmware: não inicia ciclo de teste; feedback OLED breve
- App: exibe "Aguarde — peça já aprovada"

## Códigos existentes (inalterados)

| motivo | Contexto |
|--------|----------|
| end_batch_durante_teste | END_BATCH em TESTING |
| lote_cheio | Meta atingida |
| botao_duplo | Duplo toque em 800 ms |
