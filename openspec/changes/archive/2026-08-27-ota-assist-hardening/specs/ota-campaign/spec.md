## ADDED Requirements

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
