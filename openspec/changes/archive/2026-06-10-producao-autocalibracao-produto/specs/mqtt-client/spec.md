## ADDED Requirements

### Requirement: Parsing de amostras de calibração
O app SHALL parsear mensagens JSON em `sirene/<device_id>/calibracao` distinguindo `tipo: "calibracao_amostra"` e `tipo: "calibracao"`.

#### Scenario: Amostra de calibração parseada
- **WHEN** chega uma mensagem com `tipo: "calibracao_amostra"`
- **THEN** o app extrai `potencia_w` e `elapsed_ms` e disponibiliza para atualização da UI ao vivo

#### Scenario: Resultado final de calibração parseado
- **WHEN** chega uma mensagem com `tipo: "calibracao"` e `potencia_media`
- **THEN** o app extrai a potência média de referência e sinaliza conclusão do ciclo de calibração
