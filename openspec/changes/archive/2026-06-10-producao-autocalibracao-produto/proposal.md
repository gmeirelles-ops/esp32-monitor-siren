## Why

O firmware `sirene-validator` v1.1.1 está funcional e endurecido, mas ainda não está pronto para operação em produção no posto: o operador precisa digitar manualmente `potencia_min` e `potencia_max` no lote, e a calibração existe apenas como botão isolado na tela Admin — sem cadastro de produtos nem fluxo que derive os limites a partir de uma medição real. Na prática, cada novo produto exige adivinhar tolerâncias ou consultar planilha externa, o que é lento e propenso a erro.

A ideia correta para a linha Diponto é: **no cadastro do produto**, colocar uma peça padrão na bancada, autocalibrar (medir potência de referência), **ver as leituras em tempo real**, e o app calcular automaticamente min/max com tolerância configurável — depois reutilizar esses valores em todo `SET_BATCH`.

## What Changes

- Nova tela **Cadastro de Produtos** no app Flutter: criar/editar produtos com `id_produto`, nome, tempo de teste e tolerância de potência.
- Fluxo de **autocalibração no cadastro**: operador aciona "Medir peça padrão", firmware executa ciclo de calibração e publica amostras em tempo real + média final; app exibe gráfico/indicador ao vivo e propõe `potencia_min`/`potencia_max`.
- **Integração com lote**: tela de lote passa a selecionar produto cadastrado e preenche automaticamente limites e tempo de teste (operador só informa OP, ano, quantidade e sequencial).
- **Firmware**: `START_CALIBRATION` passa a publicar amostras periódicas de potência durante o ciclo (além da média final), para feedback visual no cadastro.
- **Remoção da calibração solta no Admin**: calibração migra para o cadastro de produtos; Admin fica apenas com OTA.
- **Checklist de produção**: documentação e validação final para colocar firmware + app + broker na linha.

## Capabilities

### New Capabilities
- `product-catalog`: Cadastro local de produtos com limites de potência derivados de autocalibração, persistidos em SQLite e reutilizados no lote.

### Modified Capabilities
- `calibration-mode`: Calibração publica amostras em tempo real durante o ciclo, não só a média final.
- `calibration-and-ota`: Calibração integrada ao cadastro de produto; removida da tela Admin.
- `batch-operator-ui`: Seleção de produto cadastrado com preenchimento automático de limites.
- `mqtt-messaging`: Contrato de amostras de calibração em tempo real no tópico `calibracao`.
- `mqtt-client`: App assina e processa amostras de calibração para UI ao vivo.
- `flutter-app-shell`: Nova seção "Produtos" na navegação principal.

## Impact

- **Firmware** (`sirene-validator/main/main.c`, `pzem.c`): publicação periódica de amostras durante `START_CALIBRATION`; versão bump para 1.2.0.
- **App Flutter** (`sirene_app/`): nova feature `products/`, migração SQLite (tabela `products`), alterações em `batch_screen.dart` e `admin_screen.dart`, providers MQTT para stream de calibração.
- **Operação**: primeiro cadastro de cada SKU na bancada com peça padrão; lotes subsequentes só selecionam o produto.
- **Sem breaking change no MQTT de lote**: `SET_BATCH` mantém os mesmos campos; apenas a origem dos limites muda (cadastro → lote).
- **Firebase**: fora de escopo; catálogo permanece em SQLite local (sync nuvem é fase futura).
