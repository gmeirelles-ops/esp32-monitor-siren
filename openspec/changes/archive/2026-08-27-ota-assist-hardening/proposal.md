## Why

OTA na LAN ainda falha com frequência no posto: firewall Windows, IP errado (adaptador virtual), dependência de Python para servir o `.bin`, e docs que pedem `python -m http.server` em vez do fluxo do app. Flash USB já existe no app, mas o checklist de produção ainda aponta só `idf.py`. Endurecer o assistente OTA reduz retrabalho na bancada sem mudar o protocolo firmware.

## What Changes

- Preferir **servidor HTTP Dart** no Windows (Python só como fallback opcional).
- Pré-voo antes de `OTA_UPDATE`: IP LAN detectado, porta ouvindo, URL montada, dica de firewall se bind/lan falhar.
- UI Admin/Firmware: status claro (URL, IP, porta) + checklist curto (mesma rede Wi‑Fi, firewall privado, bancada online).
- Docs: `docs/PRODUCAO.md` e trechos OTA do guia apontam fluxo do app (OTA assist + USB no app); `python -m http.server` vira fallback manual.
- Testes unitários da lógica de pré-voo / mensagens de erro.

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `ota-campaign` — pré-voo e serve assistido antes da campanha/envio
- `ota-update` — requisitos de assist HTTP / mensagens operacionais (se aplicável)
- `project-documentation` — PRODUCAO/guia alinhados ao app

## Impact

- `sirene_app/lib/features/firmware/` (`ota_assist_service`, `ota_assist_logic`, tela)
- `docs/PRODUCAO.md`, trechos OTA em docs firmware
- Sem mudança de payload MQTT `OTA_UPDATE` no ESP32
