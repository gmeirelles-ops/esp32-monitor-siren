# Exploração de Requisitos: Sistema de Teste de Qualidade para Sirenes Rotativas

## 1. Contexto do Projeto
A empresa fabrica sirenes rotativas industriais e necessita de um sistema de Controle de Qualidade (QA) automatizado, rastreável e baseado em dados. O processo atual será substituído por uma bancada de testes inteligente que avaliará o consumo elétrico do motor da sirene para determinar se ela "Passou" ou "Reprovou" no teste de qualidade, salvando o histórico e métricas de produção, garantindo segurança industrial e resiliência contra quedas de rede.

## 2. Objetivos Principais
* **Automatizar a decisão de qualidade:** Eliminar o "achismo" utilizando medições elétricas precisas (Corrente e Potência).
* **Coletar Métricas:** Entender quais modelos de sirenes apresentam mais falhas e os motivos (causa raiz).
* **Rastreabilidade:** Vincular cada teste realizado a um Operador específico, Modelo, Lote e Data/Hora.
* **Segurança e Confiabilidade Industrial:** Proteger o hardware contra falhas críticas (relé colado) e garantir a continuidade da produção mesmo sem internet.
* **Escalabilidade:** Permitir o cadastro dinâmico de novos modelos de sirenes sem necessidade de reprogramar o hardware.

## 3. Requisitos Técnico Mapeados
* **Microcontrolador:** ESP32 programado em C utilizando o framework ESP-IDF nativo (Versão Estável 5.3.2) com FreeRTOS.
* **Sensores:** Módulo PZEM-004T v3.0 (comunicação Modbus RTU via UART) para leitura de Corrente (A) e Potência Ativa (W).
* **Atuadores e Proteção de Hardware:** * Relé de Estado Sólido (SSR) para acionamento do motor, eliminando o risco de contatos "soldarem/colarem" por arco elétrico.
  * Botão de Emergência físico tipo Cogumelo para corte imediato de energia em caso de anomalia.
  * Encapsulamento em gabinete industrial com classificação de proteção IP65 (contra poeira e vibração).
* **Conectividade e Resiliência (Offline First):** Conexão Wi-Fi com a rede da fábrica. Em caso de oscilação ou queda de sinal, o aplicativo não pode parar a linha de produção.

## 4. Regras de Negócio e Restrições
* **Comportamento do Motor (Inrush):** O sistema deve ignorar o pico de corrente de partida aguardando um tempo de estabilização de exatamente 1000ms antes de coletar os dados do PZEM.
* **Limites de Tolerância:** Cadastro de limites absolutos (mínimo e máximo de corrente/potência) por modelo no aplicativo para evitar falsos positivos causados pela não-linearidade dos motores.
* **Contingência Offline:** O aplicativo Flutter deve armazenar os testes localmente em cache caso o Wi-Fi caia e sincronizar tudo automaticamente com o Firebase assim que a rede retornar.
* **Diagnósticos de Falha Esperados:**
  * Subcorrente (Corrente abaixo do mínimo): Rotor girando em falso, aletas soltas ou quebradas.
  * Sobrecorrente (Corrente acima do máximo): Eixo travado, falta de lubrificação ou curto na bobina.
  * Circuito Aberto (Corrente igual a zero): Fio rompido ou falha grave de solda.

## 5. Expansões Futuras Planejadas (Fase 2)
* **Auditoria Acústica Integrada:** Adição de um microfone calibrado na bancada para medir os Decibéis (dB) emitidos pela sirene.
* **Rastreabilidade Física (Etiquetagem):** Integração com uma impressora térmica na bancada para impressão automática de etiquetas com QR Code após o status "APROVADO".