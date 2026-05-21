# Plano de Execução (Apply): Sistema de Teste de Sirenes

## Tarefa 1: Firmware ESP32 (ESP-IDF v5.3.2)
* **Ações Requeridas:**
  1. Configurar o ambiente do projeto utilizando a estrutura padrão do ESP-IDF v5.3.2 (`idf.py create-project`).
  2. Implementar a inicialização de GPIOs (GPIO 0 como entrada pull-up, GPIO 4 como saída digital para o SSR).
  3. Criar a rotina de debounce por software de 50ms utilizando `vTaskDelay` ou temporizadores do FreeRTOS.
  4. Configurar o driver UART1 (9600 baud, 8N1) nos pinos 16 e 17. Implementar o frame Modbus RTU (Function Code `0x04`) para ler os registradores do PZEM-004T v3.0.
  5. Implementar o componente `esp_http_client` configurado para o método `HTTP_METHOD_PATCH` para atualizar de forma atômica o nó `/teste_atual.json`.

## Tarefa 2: Aplicativo Flutter com Suporte Offline (Cache)
* **Ações Requeridas:**
  1. Inicializar o projeto Flutter e estruturar em pastas (`models`, `services`, `screens`, `widgets`).
  2. Configurar o `Hive` ou `Isar` no arquivo `main.dart` para inicializar os boxes de cache offline.
  3. Desenvolver o `ConnectivityService` para verificar o estado da rede em tempo real.
  4. Desenvolver a "Tela de Teste Live" utilizando um `StreamBuilder` apontado para o Firebase Realtime Database.
  5. Escrever a lógica de decisão: ao ler o status `"CONCLUIDO"`, comparar os dados brutos com os limites absolutos. Se houver internet, salvar no Firestore; se não, salvar no cache local do Hive.

## Tarefa 3: Dashboard de Qualidade
* **Ações Requeridas:**
  1. Utilizar o pacote `fl_chart` para renderizar gráficos de barra e pizza no aplicativo.
  2. Criar consultas agregadas no Firestore para calcular o total de testes diários, taxa de reprovação e ranking de erros (Sobrecorrente, Subcorrente, Circuito Aberto).

## Tarefa 4: Ganchos de Expansão (Fase 2)
* **Ações Requeridas:**
  1. Deixar interfaces (classes abstratas) preparadas no Flutter para o `AudioTestingService` (leitura de dB) e `LabelPrinterService` (impressão térmica), garantindo que a Fase 2 possa ser acoplada sem refatorar o núcleo do app.