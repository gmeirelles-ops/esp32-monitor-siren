## ADDED Requirements

### Requirement: Publicação de amostras de calibração em tempo real
O dispositivo SHALL publicar amostras periódicas de potência no tópico `sirene/<device_id>/calibracao` durante o ciclo de `START_CALIBRATION`, além da mensagem final com a média.

#### Scenario: Amostra publicada durante calibração
- **WHEN** o ciclo de calibração está em andamento após o descarte de inrush
- **THEN** o dispositivo publica JSON com `tipo: "calibracao_amostra"`, `potencia_w` (float) e `elapsed_ms` (inteiro) em intervalo máximo de 500 ms

#### Scenario: Mensagem final após amostras
- **WHEN** o ciclo de calibração de 5 segundos é concluído com sucesso
- **THEN** o dispositivo publica JSON com `tipo: "calibracao"` e `potencia_media` como última mensagem do ciclo
