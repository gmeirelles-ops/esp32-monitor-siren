# Proposta de Arquitetura: Sistema de Teste de Sirenes (V2)

## 1. Visão Geral da Solução
O sistema adota um modelo descentralizado: o ESP32 (ESP-IDF 5.3.2) atua como um coletor de dados robusto e seguro, e o aplicativo Flutter atua como a inteligência do negócio. A comunicação em tempo real é feita através do Firebase Realtime Database para sinalização de testes, e o Firestore para histórico de longo prazo.

## 2. Estrutura de Dados (Firebase)
* **Nó Realtime: `/teste_atual`**
  * `id_modelo`: string
  * `lote`: string
  * `id_operador`: string
  * `status`: enum ("AGUARDANDO_BOTAO", "CONCLUIDO", "ERRO_SENSOR")
  * `corrente_lida`: float
  * `potencia_lida`: float

* **Coleção Firestore: `Modelos_Sirenes`**
  * `id_modelo` (Document ID)
  * `nome_modelo`: string
  * `corrente_minima_a`: float
  * `corrente_maxima_a`: float
  * `potencia_minima_w`: float
  * `potencia_maxima_w`: float

* **Coleção Firestore: `Historico_Testes`**
  * `data_hora`: timestamp
  * `id_operador`: string
  * `id_modelo`: string
  * `lote`: string
  * `corrente_lida`: float
  * `potencia_lida`: float
  * `resultado`: enum ("Aprovado", "Reprovado")
  * `motivo_reprovacao`: string (ex: "Sobrecorrente")

## 3. Arquitetura do Firmware (ESP-IDF 5.3.2)
O firmware utilizará o FreeRTOS dividido em duas Tasks principais fixadas em cores (cores) diferentes para evitar que o processamento de rede interfira no controle de tempo do hardware:
* `Task_WiFi` (Core 0): Gerencia e monitora a conexão de rede.
* `Task_Teste` (Core 1): Monitora o botão de teste (com debounce de 50ms por software), aciona o Relé de Estado Sólido (SSR), executa o delay de 1000ms do Inrush, faz a leitura dos registradores Modbus do PZEM via UART e envia os dados brutos via requisição HTTP PATCH REST.

### 3.1 Mapeamento de Hardware (Pinout)
* **PZEM_TX_PIN:** GPIO 17 (UART1 RX do ESP32 conectado ao TX do PZEM)
* **PZEM_RX_PIN:** GPIO 16 (UART1 TX do ESP32 conectado ao RX do PZEM)
* **SSR_RELE_PIN:** GPIO 4 (Acionamento do Relé de Estado Sólido)
* **BOTAO_PIN:** GPIO 0 (Botão físico em modo PULLUP interno)

## 4. Arquitetura do Aplicativo Flutter (Offline First)
* **Gerenciamento de Estado:** Pacote `Provider` para reatividade das telas.
* **Persistência Local (Contingência):** Uso do pacote `Hive` ou `Isar` para criar um banco de dados NoSQL local offline.
* **Lógica de Sincronização:** O `SyncService` monitorará a conectividade. Se houver falha de rede, os registros do `Historico_Testes` são salvos no cache local. Assim que a conexão for reestabelecida, uma rotina em segundo plano descarrega o cache no Firestore.

## 5. Segurança Industrial e Tratamento de Erros
* **Timeout do Sensor:** Se o PZEM não responder via Modbus RTU em até 2000ms, o ESP32 corta o SSR instantaneamente, aborta o ciclo e envia o status `"ERRO_SENSOR"`.
* **Botão de Emergência:** Disposto em série com a alimentação principal do SSR para corte elétrico imediato independente do software.