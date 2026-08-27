## ADDED Requirements

### Requirement: Versões documentadas batem com o código
A documentação operacional SHALL citar a versão de firmware definida em `sirene-validator/components/board_config/include/board_config.h` (`FIRMWARE_VERSION`) e a versão do app em `sirene_app/pubspec.yaml`, sem números legados como fluxo “atual”.

#### Scenario: Guia firmware
- **WHEN** um integrador abre `sirene-validator/docs/GUIA_COMPLETO.md` ou `DEPLOY_PRODUCTION.md`
- **THEN** a versão destacada é a mesma de `FIRMWARE_VERSION` (ex.: 1.8.10)

#### Scenario: Produção
- **WHEN** um supervisor abre `docs/PRODUCAO.md`
- **THEN** o checklist de flash/logs referencia a versão atual do firmware e do app, não 1.7.x

### Requirement: Marcação física documentada como laser apenas
`README.md`, `docs/PRODUCAO.md` e `sirene_app/README.md` SHALL descrever somente gravação laser Diatu/DiatuCAD como marcação de serial no posto (sem checklist ativo de impressora Zebra).

#### Scenario: Onboarding posto
- **WHEN** o operador segue o checklist de produção
- **THEN** encontra passos laser (porta TCP, DiatuCAD, F2) e não é instruído a instalar driver Zebra como fluxo padrão

### Requirement: Heartbeat documentado em 10 s
Documentação de telemetria MQTT SHALL indicar intervalo de heartbeat de **10 segundos**, alinhado a `HEARTBEAT_INTERVAL_SEC` no firmware.

#### Scenario: Tabela de tópicos
- **WHEN** o guia lista `.../heartbeat`
- **THEN** o intervalo descrito é 10 s (não 30 s)
