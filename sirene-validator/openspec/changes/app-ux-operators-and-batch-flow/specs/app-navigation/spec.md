## MODIFIED Requirements

### Requirement: Rota inicial é a tela de Lote

O sistema SHALL abrir diretamente na tela de Lote (configuração + dashboard) após splash, não na tela de Dispositivos.

#### Scenario: Abertura do app

- **WHEN** o operador inicia o aplicativo
- **THEN** a primeira tela visível é Lote, com seletor de operador se necessário

### Requirement: Dispositivos não é item principal de navegação

O sistema SHALL remover Dispositivos da navegação primária (bottom bar / rail / drawer principal).

#### Scenario: Menu principal

- **WHEN** o operador visualiza a navegação principal
- **THEN** os itens são Lote, Etiquetas (se aplicável), Cadastros (admin) e Configurações — sem entrada "Dispositivos"

## ADDED Requirements

### Requirement: Configuração de dispositivo em Configurações

O sistema SHALL permitir selecionar ou descobrir dispositivo MQTT em Configurações → Dispositivo, com descoberta automática via `sirene/+/heartbeat` em background.

#### Scenario: Primeiro uso sem dispositivo

- **WHEN** nenhum `device_id` está configurado
- **THEN** a tela de Lote exibe banner com link para Configurações → Dispositivo

## REMOVED Requirements

### Requirement: Tela de Dispositivos como hub inicial

**Reason:** O fluxo de produção começa pelo lote; descoberta de dispositivos é suporte, não objetivo principal do operador.

**Migration:** Funcionalidade movida para Configurações → Dispositivo; descoberta MQTT continua disponível.
