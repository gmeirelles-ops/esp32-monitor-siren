## ADDED Requirements

### Requirement: Indicador de conexão MQTT global
O app SHALL exibir o indicador de status da conexão MQTT (`ConnectionStatusBadge`) na AppBar de todas as telas principais, não apenas na tela de Dispositivos.

#### Scenario: Badge visível fora de Dispositivos
- **WHEN** o operador está na tela de Lote, Painel, Etiquetas ou Configurações
- **THEN** o badge de conexão MQTT permanece visível na AppBar

#### Scenario: Queda de conexão refletida globalmente
- **WHEN** a conexão com o broker MQTT é perdida
- **THEN** o badge reflete o estado desconectado em qualquer tela principal

## MODIFIED Requirements

### Requirement: Seção de nuvem nas Configurações
O app SHALL incluir nas Configurações uma seção "Nuvem" com: toggle de sincronização Firestore, campo `station_id`, status da fila de sync, listagem de dead-letter com retry e botão de logout (quando autenticado).

#### Scenario: Operador configura posto
- **WHEN** o operador define `station_id` e salva nas Configurações
- **THEN** o valor é persistido em SharedPreferences e usado em gravações Firestore subsequentes

#### Scenario: Status da fila visível
- **WHEN** existem itens pendentes ou com falha na fila de sync
- **THEN** a seção Nuvem exibe contagem de pendências e falhas permanentes

#### Scenario: Dead-letter listado
- **WHEN** existem entradas com falha permanente na fila
- **THEN** a seção Nuvem lista cada falha com erro e oferece ação de retry
