## Why

O gerador ZPL do app (`zpl_generator.dart`) usa constantes estimadas (^PW315, ^LL120, posições X) para rolo 3×10×30 mm, mas não há referência validada contra o layout real da fábrica. O posto já usa **NiceLabel** para etiquetas Zebra — exportar de lá o ZPL e as medidas do stock é a forma mais confiável de calibrar tamanho, código de barras ITF e alinhamento das 3 colunas sem tentativa e erro na impressora.

## What Changes

- Guia operacional **NiceLabel → referência ZPL**, incluindo **Print to File** quando não há menu Export ZPL (comum no NiceLabel Express).
- Pasta `docs/label-reference/` com README, `stock-spec.md` e rascunho ZPL do layout real (DP1000 220V + MADE IN BRAZIL + ITF).
- Atualização de `zpl_generator.dart` para espelhar os comandos ^PW, ^LL, ^LH, ^FO, ^BY, ^BI do export NiceLabel.
- Teste unitário que valida estrutura do ZPL gerado contra a referência (serial fixo de exemplo).
- Checklist de homologação física: imprimir amostra NiceLabel vs amostra do app lado a lado.

## Capabilities

### New Capabilities

- `nicelabel-reference-workflow`: procedimento e artefatos para extrair do NiceLabel medidas e ZPL de referência
- `zpl-label-layout`: requisitos do layout físico e comandos ZPL (stock 3-across 10×30 mm, ITF, texto humano)

### Modified Capabilities

- `label-printing`: ZPL gerado SHALL ser equivalente ao export NiceLabel de referência para o mesmo serial
- `dev-label-file-export`: export em dev pode incluir comparação ou link à referência NiceLabel na documentação

## Impact

- **Documentação**: novo guia NiceLabel; atualização de `docs/PRODUCAO.md`
- **Código**: `zpl_generator.dart`, testes em `test/zpl_generator_test.dart`
- **Repositório**: arquivo `.zpl` e ficha de medidas commitados (sem dados de produção sensíveis)
- **NiceLabel / impressora**: uso pontual no PC do posto para export; sem dependência runtime do NiceLabel no app
