## 1. Estrutura base do projeto (ESP-IDF)

- [x] 1.1 Inicializar projeto ESP-IDF v5.3.2 em C nativo com estrutura de componentes
- [x] 1.2 Definir mapa de pinos (GPIO do relé, GPIO do botão com pull-up, UART do PZEM-004T, GPIO do LED/buzzer de status)
- [x] 1.3 Criar `#define` de configuração do broker MQTT, janela de inrush e demais constantes hardcoded
- [x] 1.4 Inicializar o relé em estado seguro (desligado) no boot, antes de qualquer lógica de teste
- [x] 1.5 Derivar o `device_id` a partir do MAC do ESP32
- [x] 1.6 Implementar a máquina de estados central (PROVISIONING, IDLE, BATCH_READY, TESTING, HARDWARE_FAULT)

## 2. Provisionamento de Wi-Fi (Captive Portal)

- [x] 2.1 Implementar leitura de credenciais Wi-Fi na NVS na inicialização
- [x] 2.2 Subir modo SoftAP e servidor HTTP em `192.168.4.1` quando não houver credenciais válidas
- [x] 2.3 Criar página HTML de captura de SSID/senha e endpoint de submissão
- [x] 2.4 Persistir credenciais na NVS e reiniciar em modo Station (STA)
- [x] 2.5 Implementar conexão STA usando as credenciais salvas

## 3. Camada de medição (PZEM-004T)

- [x] 3.1 Implementar driver/leitura UART do PZEM-004T
- [x] 3.2 Implementar leitura contínua e acúmulo de amostras descartando a janela inicial de inrush (padrão 500 ms)
- [x] 3.3 Implementar cálculo de potência média das leituras válidas do ciclo
- [x] 3.4 Detectar falha de comunicação UART e sinalizar para a máquina de estados

## 4. Conectividade MQTT

- [x] 4.1 Implementar cliente MQTT e conexão ao broker definido via `#define`
- [x] 4.2 Assinar o tópico `sirene/<device_id>/comando`
- [x] 4.3 Implementar parser do `SET_BATCH` validando `numero_op`, `id_produto`, `ano`, `tempo_teste`, `potencia_min`, `potencia_max`, `quantidade_total`, `proximo_sequencial`
- [x] 4.4 Implementar tratamento do comando `END_BATCH`
- [x] 4.5 Publicar status de teste em `sirene/<device_id>/status` (veredito, potência média, sequencial, OP, aprovados)
- [x] 4.6 Publicar alerta de falha em `sirene/<device_id>/alerta`
- [x] 4.7 Publicar resultado de calibração em `sirene/<device_id>/calibracao`
- [x] 4.8 Publicar mensagens de rejeição de comandos (estado/contexto inválido)

## 5. Fluxo de lote e execução do teste

- [x] 5.1 Persistir o contexto completo do lote em NVS (OP, `id_produto`, `ano`, limites, `tempo_teste`, `quantidade_total`, sequencial, aprovados)
- [x] 5.2 Restaurar o lote ativo a partir da NVS no boot (retomada após reboot)
- [x] 5.3 Implementar leitura do botão com debounce e flag de teste em andamento
- [x] 5.4 Acionar relé por `tempo_teste` (segundos) e ignorar cliques durante o teste
- [x] 5.5 Calcular veredito comparando média com `potencia_min`/`potencia_max`
- [x] 5.6 Contabilizar aprovados do lote e tratar encerramento via `END_BATCH`
- [x] 5.7 Bloquear início de teste sem lote configurado ou em estado HARDWARE_FAULT
- [x] 5.8 Implementar feedback local via LED/buzzer (aprovado, reprovado, falha) independente de rede

## 6. Rastreabilidade e sequencial

- [x] 6.1 Incrementar e persistir o sequencial em NVS apenas em caso de APROVAÇÃO
- [x] 6.2 Manter o sequencial idêntico e suprimir emissão de etiqueta em caso de REPROVAÇÃO
- [x] 6.3 Incluir sequencial e OP nas mensagens de status para o App Web

## 7. Modo Aprendizado (Calibração)

- [x] 7.1 Tratar o comando `START_CALIBRATION` apenas em `IDLE` (rejeitar com lote ativo, em TESTING ou HARDWARE_FAULT)
- [x] 7.2 Executar ciclo de 5 segundos e calcular a potência média de referência
- [x] 7.3 Publicar a potência média via MQTT para o cadastro de produtos

## 8. Resiliência offline

- [x] 8.1 Implementar fila local FIFO persistente (NVS/SPIFFS) dos resultados com tamanho máximo
- [x] 8.2 Implementar política de retenção e sinalização ao atingir o limite da fila
- [x] 8.3 Garantir continuidade do fluxo de teste sem rede/broker
- [x] 8.4 Implementar task de sincronização em segundo plano para dump da fila (ordem FIFO) ao reconectar
- [x] 8.5 Remover mensagens da fila local após confirmação de envio (idempotência por OP+sequencial)

## 9. Monitoramento de hardware

- [x] 9.1 Transicionar para HARDWARE_FAULT ao detectar perda de UART do PZEM-004T
- [x] 9.2 Travar novas execuções de teste enquanto em HARDWARE_FAULT
- [x] 9.3 Retomar operação quando a comunicação for restabelecida

## 10. Integração e validação

- [x] 10.1 Testar fluxo completo de provisionamento (SoftAP → STA)
- [x] 10.2 Testar ciclo de teste aprovado e reprovado com consumo correto do sequencial
- [x] 10.3 Testar retomada de lote após reboot/queda de energia (lote restaurado da NVS)
- [x] 10.4 Testar resiliência offline, limite da fila FIFO e sincronização ao reconectar
- [x] 10.5 Testar bloqueio, alerta e recuperação em falha de UART do PZEM-004T
- [x] 10.6 Testar rejeição de comandos por conflito de estado (SET_BATCH/END_BATCH/START_CALIBRATION)
- [x] 10.7 Validar contratos MQTT por dispositivo (SET_BATCH, END_BATCH, status, calibração, alerta) ponta a ponta com o App Web
