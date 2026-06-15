# Stock — etiqueta sirene

| Campo | Valor confirmado | Fonte |
|-------|------------------|--------|
| Largura (comprimento) | 30 mm | operador |
| Altura | 10 mm | operador |
| Colunas | 3 | operador |
| Gap horizontal | 0 mm (pitch 239 dots = largura etiqueta) | calibrar na impressora se desalinhar |
| Gap vertical | _medir no rolo_ mm | Label Setup NiceLabel |
| DPI | 203 | ZT230 |
| Largura 1 etiqueta (^PW) | **239** dots | ZPL NiceLabel fornecido |
| Largura linha 3-across (^PW) | **717** dots | app (`239 × 3`) |
| Comprimento linha (^LL) | **80** dots | corrigido (^LL vazio no export) |

## Comandos ZPL por objeto (1 etiqueta, dots)

| Objeto | Comando | Notas |
|--------|---------|-------|
| Faixa preta | `^FO6,3^GB145,40,40,B,0^FS` | retângulo preenchido |
| Nome produto | `^FO6,12^A0N,25,25^FR^FD … ^FS` | texto branco invertido |
| MADE IN | `^FO152,8^A0N,22,22^FDMADE IN^FS` | fixo |
| BRAZIL | `^FO152,25^A0N,22,22^FDBRAZIL^FS` | fixo |
| Serial | `^FO75,55^A0N,20,20^FD…^FS` | variável (10 dígitos) |

**Layout atual:** sem código de barras ITF no ZPL (apenas serial legível). ITF pode ser adicionado depois se necessário.

## Conteúdo

- **Fixo:** `MADE IN` / `BRAZIL`
- **Variável:** nome do produto (cadastro Produtos → Nome, ex. `DP1000 220V`)
- **Variável:** serial de 10 dígitos (ex. `0412603646`, `1232600196`)

## Offsets coluna (3-across)

| Coluna | X offset (dots) |
|--------|-----------------|
| 1 | 0 |
| 2 | 239 |
| 3 | 478 |

## Arquivos de referência

- `nicelabel-single-reference.zpl` — export operador (1 etiqueta)
- `nicelabel-row-3x.zpl` — linha com 3 seriais de teste (gerado pelo app)
- `README.md` — guia Print to File e homologação

## Homologação no posto

- [ ] Imprimir `nicelabel-single-reference.zpl` na ZT230 USB
- [ ] Aprovar 3 sirenes e comparar com NiceLabel
- [ ] Ajustar `zplColumnPitch` se gap físico ≠ 0 mm
