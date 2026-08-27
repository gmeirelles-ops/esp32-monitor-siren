## MODIFIED Requirements

### Requirement: Formulário de lote orientado a leigo
A tela Lote SHALL minimizar seções/cards, usar rótulos curtos em português e um único CTA primário “Iniciar lote” (ou equivalente). O app SHALL NOT exigir que o operador entenda jargão técnico (MQTT, FSM, buffer).

#### Scenario: Início de turno
- **WHEN** o operador autenticado abre Lote com produto e bancada já conhecidos do posto
- **THEN** consegue iniciar o lote com poucos campos e um botão principal óbvio
