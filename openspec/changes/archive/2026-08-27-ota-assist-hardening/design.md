## Context

Já existem `OtaAssistService` (Dart + Python no Windows), `UsbFlashService` (esptool), `FirmwareUpdateScreen` (abas OTA/USB) e testes em `firmware_ota_logic_test.dart`. Fragilidade restante é operacional: ordem de preferência do servidor, feedback ao gestor e docs desatualizados.

## Goals / Non-Goals

**Goals**

- OTA assist confiável sem Python no PATH.
- Erros acionáveis (firewall, IP, porta ocupada) antes de publicar MQTT.
- Documentação do posto usa o app como caminho padrão.

**Non-Goals**

- Mudar protocolo OTA no firmware ou partições.
- Flash USB em Linux/macOS (continua Windows-first).
- Campanha multi-device avançada além do que já existe.
- Segurança / TLS no HTTP OTA (LAN interna).

## Decisions

1. **Dart HttpServer primeiro** em todas as plataformas; Python Windows só se Dart falhar e Python existir.
2. **Pré-voo** (`otaPreflight` / similar): validar bin, IP, startServing, HEAD/GET local do `.bin` na URL LAN quando possível; senão mensagem explícita.
3. **Docs**: PRODUCAO § OTA → Firmware no app; manter USB cabo para primeira gravação / recovery.
4. Reusar mensagens em PT já existentes; ampliar, não reinventar UI.

## Risks / Trade-offs

- Firewall do Windows ainda bloqueia inbound mesmo com servidor Dart — só mitiga com mensagem clara.
- GET na URL LAN a partir do próprio PC não prova que o ESP alcança; é smoke test do bind, não substitui Wi‑Fi correta.

## Migration Plan

Nenhuma migração de dados. Operadores passam a usar a tela Firmware do app; scripts manuais HTTP ficam na doc como fallback.
