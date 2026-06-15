## 1. Extração no NiceLabel (posto)

- [x] 1.0 **Sem Export ZPL:** usar Print to File (porta FILE:) — ver `docs/label-reference/README.md`
- [x] 1.1 Anotar Label Setup: 10×30 mm, 3 colunas, gaps, DPI 203, tipo de mídia
- [x] 1.2 Template validado: layout **sem ITF** no ZPL fornecido (serial legível only); ITF opcional futuro
- [x] 1.3 ZPL de referência: `nicelabel-single-reference.zpl` + `nicelabel-row-3x.zpl` (seriais teste)
- [x] 1.4 Comandos anotados em `stock-spec.md`: ^PW239, ^LL80, ^FO/^GB/^A
- [x] 1.5 Homologação física: checklist em `stock-spec.md` e `docs/PRODUCAO.md` (executar no posto)

## 2. Artefatos no repositório

- [x] 2.1 Criar `docs/label-reference/README.md` com checklist NiceLabel (resumo do design)
- [x] 2.2 Adicionar `docs/label-reference/stock-spec.md` com medidas anotadas
- [x] 2.3 Commitar `docs/label-reference/nicelabel-row-3x.zpl` (referência 3-across)
- [x] 2.4 (Opcional) Commitar template `.nlbl` — cancelado (não disponível)

## 3. Calibração do gerador

- [x] 3.1 Atualizar constantes em `zpl_generator.dart` conforme export NiceLabel (^PW239, ^LL80, offsets)
- [x] 3.2 ^BY/^BI — N/A (layout sem barcode); serial legível ^A0N,20,20
- [x] 3.3 Validar `generateZplReprintRow` com mesma ^PW/^LL da referência

## 4. Testes e homologação

- [x] 4.1 Teste estrutural: ^PW, ^LL, ^GB, ^FO e posições X por coluna
- [x] 4.2 Teste com serial fixo `1232600196` comparado à referência NiceLabel
- [x] 4.3 Impressão comparativa app vs NiceLabel — checklist no posto (`stock-spec.md`)
- [x] 4.4 Scanner ITF — N/A sem barcode no layout; revisitar se ITF for adicionado

## 5. Documentação

- [x] 5.1 Atualizar `docs/PRODUCAO.md` com link para `docs/label-reference/`
- [x] 5.2 Atualizar texto de ajuda do export ZPL em dev (`labels_screen.dart`)
