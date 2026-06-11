# serial-traceability Specification

## Purpose
TBD - created by archiving change validacao-sirenes. Update Purpose after archive.
## Requirements
### Requirement: Estrutura do número de série
O número de série SHALL ter 10 dígitos compostos por: 3 dígitos de ID do Produto, 2 dígitos do Ano, 4 dígitos de Sequencial e 1 dígito Verificador calculado segundo o padrão ITF 2 de 5.

#### Scenario: Composição do serial completo
- **WHEN** um serial é gerado para uma sirene aprovada
- **THEN** o serial possui exatamente 10 dígitos na ordem: ID do Produto (3) + Ano (2) + Sequencial (4) + Dígito Verificador (1)

### Requirement: Origem do ID do Produto e do Ano
O `id_produto` (3 dígitos) e o `ano` (2 dígitos) que compõem o serial SHALL ser fornecidos ao dispositivo no comando `SET_BATCH`, de modo que o serial possa ser montado sem depender de relógio de tempo real (RTC) ou de NTP no ESP32.

#### Scenario: Identidade recebida no lote
- **WHEN** o dispositivo recebe um `SET_BATCH` com `id_produto` e `ano`
- **THEN** o dispositivo associa esses valores ao lote e os utiliza (junto ao sequencial) para identificar cada peça aprovada

#### Scenario: Operação offline preserva a identidade
- **WHEN** o dispositivo está offline e aprova uma sirene
- **THEN** o `id_produto` e o `ano` do lote ativo permanecem disponíveis localmente para compor o serial, sem necessidade de consulta de data por rede

### Requirement: Consumo do sequencial condicionado ao resultado
O sequencial SHALL ser consumido e incrementado localmente no dispositivo apenas quando a sirene for aprovada; em caso de reprovação, o contador SHALL permanecer idêntico.

#### Scenario: Sirene aprovada consome o sequencial
- **WHEN** o resultado do teste é APROVADO
- **THEN** o dispositivo valida o sequencial, consome-o e incrementa o contador interno para a próxima peça

#### Scenario: Sirene reprovada não consome o sequencial
- **WHEN** o resultado do teste é REPROVADO
- **THEN** o dispositivo mantém o contador de sequencial idêntico, não emite etiqueta e disponibiliza o mesmo sequencial para a próxima tentativa

### Requirement: Cálculo do dígito verificador e serial pelo App Web
O cálculo do dígito verificador ITF 2 de 5 e a montagem do serial completo SHALL ser realizados pelo App Flutter a partir do sequencial aprovado.

#### Scenario: Geração do serial após aprovação
- **WHEN** o App Flutter recebe a confirmação de aprovação com o sequencial consumido
- **THEN** o App Flutter calcula o dígito verificador e gera o número de série completo de 10 dígitos

