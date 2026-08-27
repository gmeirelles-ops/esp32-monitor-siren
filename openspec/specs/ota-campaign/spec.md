# ota-campaign Specification

## Purpose
Campanhas de atualização OTA no app Flutter: seleção de múltiplos dispositivos e envio coordenado de `OTA_UPDATE` com acompanhamento de status por bancada.
## Requirements
### Requirement: Campanha de OTA para múltiplos dispositivos
O app SHALL permitir selecionar vários dispositivos e enviar o mesmo `OTA_UPDATE` (URL de firmware) para todos em uma única ação.

#### Scenario: OTA enviado para seleção
- **WHEN** o operador seleciona dois ou mais dispositivos, informa a URL do firmware e confirma a campanha
- **THEN** o app publica `OTA_UPDATE` com a URL para cada dispositivo selecionado

#### Scenario: Acompanhamento por dispositivo
- **WHEN** os dispositivos publicam eventos de status de OTA
- **THEN** o app exibe o status recebido associando-o ao respectivo dispositivo

#### Scenario: Nenhum dispositivo selecionado
- **WHEN** o operador tenta enviar a campanha sem selecionar dispositivos ou sem URL
- **THEN** o app não envia comando e orienta a completar a seleção

### Requirement: Serve HTTP assistido antes do OTA_UPDATE
Antes de publicar `OTA_UPDATE`, o app SHALL servir o `.bin` via HTTP local (preferência: servidor Dart; Python opcional só como fallback) e exibir a URL resultante (IP LAN + porta + nome do arquivo).

#### Scenario: Sem Python no Windows
- **WHEN** o gestor inicia OTA e Python não está no PATH
- **THEN** o app serve o firmware com HttpServer Dart e prossegue se a porta estiver livre

#### Scenario: Porta ou firewall
- **WHEN** o bind da porta falha ou a URL LAN não responde no smoke test local
- **THEN** o app NÃO publica `OTA_UPDATE` e exibe orientação (porta em uso / liberar firewall rede privada)

### Requirement: Checklist operacional na UI
A tela de Firmware/OTA SHALL mostrar checklist curto: bancada online, mesma rede do broker, firewall, arquivo `.bin` válido.

#### Scenario: Pré-check falha
- **WHEN** a bancada está em teste ou offline
- **THEN** o app bloqueia o envio com a mesma política de `otaPrecheckError` já existente, mais contexto do serve HTTP

