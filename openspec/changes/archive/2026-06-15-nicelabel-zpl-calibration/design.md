## Context

Rolo confirmado: **3 etiquetas por linha**, cada **10 mm (altura) × 30 mm (comprimento)**, impressora **Zebra ZT230 @ 203 dpi**, código de barras **ITF 2 de 5** para serial de 10 dígitos. O app gera ZPL programaticamente; NiceLabel Designer no posto é a fonte de verdade visual que a fábrica já conhece.

Objetivo desta mudança: definir **o que extrair do NiceLabel hoje** e como isso vira constantes/testes no app.

## Goals / Non-Goals

**Goals:**

- Lista clara de dados exportáveis do NiceLabel para calibrar o app
- ZPL de referência versionado no repo
- `zpl_generator.dart` alinhado à referência
- Homologação documentada (NiceLabel vs app)

**Non-Goals:**

- Integrar NiceLabel no runtime do app (sem SDK, sem automação COM)
- Redesenhar conteúdo gráfico além de barcode + serial legível
- Substituir NiceLabel no fluxo de produção — só referência de layout

## O que pegar no NiceLabel hoje (checklist)

### 1. Definição do stock / mídia (Label Stock)

No NiceLabel Designer: **File → Label Setup** (ou equivalente na versão instalada).

| Campo | O que anotar | Uso no app |
|-------|----------------|------------|
| Largura da etiqueta | 30 mm (comprimento na direção do feed) | Valida ^LL / pitch vertical |
| Altura da etiqueta | 10 mm | Valida altura do campo |
| Colunas (across) | 3 | Confirma 3 posições X |
| Linhas | 1 (por linha física) | Layout 3-across |
| Gap horizontal | mm entre colunas | Calcula offset X col 2 e 3 |
| Gap vertical / web | mm entre linhas do rolo | Confirma ^LL total da linha |
| Orientação | Normal / rotated | Deve bater com ZT230 |
| Tipo de mídia | Gap, black mark, continuous | ZT230 com rolo gap |
| Margem esquerda do stock | mm | Pode virar ^LH (label home) |

**Exportar:** screenshot ou anotar valores em `docs/label-reference/stock-spec.md`.

### 2. Impressora e resolução

| Campo | Valor esperado ZT230 |
|-------|----------------------|
| Driver / modelo | ZDesigner ZT230-203dpi ZPL |
| DPI | **203** (8 dots/mm) |
| Print width (^PW) | dots = largura útil da **linha inteira** (3 etiquetas + gaps) |

Converter mm → dots: `dots = mm × 8` (203 dpi).

### 3. Export ZPL (principal)

**Problema comum:** NiceLabel Express e algumas edições **não** têm `File → Export → ZPL`.

**Solução recomendada — Imprimir para arquivo:**

1. Driver **ZDesigner ZT230-203dpi ZPL** instalado.
2. Propriedades da impressora → Portas → adicionar **FILE:** → `C:\temp\nicelabel.zpl`.
3. NiceLabel → **Print** na ZT230 → abrir o `.zpl` gerado (`^XA`…`^XZ`).
4. Restaurar porta USB da impressora após o teste.

**Alternativas:** ver `docs/label-reference/README.md` (posições em mm sem ZPL, Zebra Setup Utilities, export Pro se licenciado).

**Layout real identificado (captura NiceLabel):**

- Faixa preta **DP1000 220V** + **MADE IN BRAZIL** (fixos)
- Código de barras ITF + serial legível (variável, ex. `0412603646`)
- Aviso vermelho no barcode → reduzir módulo/altura ou confirmar ITF para 10 dígitos em 30 mm

**Rascunho ZPL** (até obter export real): `docs/label-reference/nicelabel-single-draft.zpl`

**Como obter ZPL ideal (quando export existir):**

1. Abrir (ou criar) template no NiceLabel com:
   - Campo variável para serial (10 dígitos)
   - Código de barras **Interleaved 2 of 5** (ITF)
   - Texto humano igual ao serial abaixo do código
2. Preencher serial de teste fixo: ex. `1232600196`
3. **Exportar ZPL:**
   - Opção A: **File → Export → ZPL** (se disponível na edição)
   - Opção B: Imprimir para **arquivo** / driver ZPL / "Send to file"
   - Opção C: **Store format** / visualizar ZPL no spooler Zebra (Setup Utilities)
4. Salvar como `docs/label-reference/nicelabel-row-3x.zpl` (linha com 3 etiquetas) e `nicelabel-single.zpl` (1 etiqueta, se existir template separado)

**Do ZPL exportado, extrair e tabela:**

| Comando ZPL | Significado | Constante no app |
|-------------|-------------|------------------|
| `^PWnnn` | Largura de impressão (dots) | `zplPrintWidth` |
| `^LLnnn` | Comprimento do label/linha (dots) | `zplLabelLength` |
| `^LH x,y` | Label home offset | opcional |
| `^FO x,y` | Posição de cada campo | `zplColumnPositions[i]` + offsets Y |
| `^BY w,r,h` | Largura módulo barcode | parâmetro ^BI |
| `^BIn,h,y,...` | ITF: orientação, altura, legível | `^BI,N,40,Y,N` |
| `^A0N,h,w` | Fonte texto humano | tamanho legível |
| `^MD`, `~SD` | Escuridão | opcional (impressora) |

### 4. Propriedades do código de barras (painel do objeto)

No objeto barcode do NiceLabel, anotar:

- Simbologia: **ITF / Interleaved 2 of 5**
- Altura do barcode (mm ou dots)
- Largura do módulo fino (narrow bar width)
- Ratio wide/narrow
- **Human readable**: abaixo do código, mesma variável serial
- Quiet zone (margem quiet) — ITF exige zonas laterais

Comparar com app atual: `^BY1,2,40` + `^BI,N,40,Y,N`.

### 5. Posições das 3 colunas

Para layout 3-across no NiceLabel:

- Anotar **X de cada coluna** (canto superior esquerdo do barcode ou do stock column 1/2/3)
- Em dots: primeira coluna ~10, segunda ~115, terceira ~220 (valores atuais do app — **confirmar ou corrigir** com export)

Fórmula útil: `X_col_n = margem + (n-1) × (largura_etiqueta_dots + gap_horizontal_dots)`.

### 6. Arquivo de template NiceLabel (opcional)

- Salvar `.nlbl` em `docs/label-reference/` (se licença permitir versionar)
- Documentar versão do NiceLabel Designer usada

### 7. Amostra física

- Imprimir 1 linha (3 seriais) pelo NiceLabel
- Imprimir mesma linha pelo app (export ZPL em dev)
- Comparar alinhamento, leitura do scanner, tamanho em régua

## Decisions

### 1. Referência = ZPL exportado, não redesenho manual

**Escolha:** Commitar ZPL do NiceLabel com serial fixo de teste; o app deve reproduzir mesma estrutura com serial variável.

**Por quê:** Evita erro de conversão mm→dots manual; NiceLabel já fala com driver Zebra.

### 2. Ficha de medidas em markdown + teste estrutural

**Escolha:** `stock-spec.md` com tabela de medidas; teste Dart verifica presença de ^PW, ^LL, 3 blocos ^FO/^BI para linha de 3, serial no ^FD.

**Por quê:** ZPL byte-a-byte pode variar com versão NiceLabel (^FX comentários); estrutura e posições são o contrato.

### 3. Sem runtime NiceLabel

App continua gerando ZPL puro; NiceLabel só na fase de calibração.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Versões diferentes do NiceLabel exportam ZPL distinto | Documentar versão; teste estrutural, não diff byte-a-byte rígido |
| Operador não tem template pronto | Incluir passo a passo para criar template mínimo no guia |
| Stock real difere do cadastrado no NiceLabel | Homologação física com régua; ajustar stock no NiceLabel primeiro |

## Migration Plan

1. No posto: seguir checklist NiceLabel; exportar ZPL + anotar stock
2. Commitar referência em `docs/label-reference/`
3. Ajustar `zpl_generator.dart` conforme export
4. Rodar testes + impressão comparativa
5. Atualizar `docs/PRODUCAO.md` com link ao guia

## Open Questions

1. Qual **versão** do NiceLabel está instalada no posto (Designer, Express, Cloud)?
2. Já existe template `.nlbl` da sirene ou será criado do zero?
3. O ITF no NiceLabel usa **10 dígitos** sem dígito verificador visível separado, ou formato com start/stop?
4. Scanner da linha lê ITF gerado pelo app hoje ou ainda não foi testado?
