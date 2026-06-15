# Referência de etiqueta — NiceLabel → ZPL

Rolo: **3 etiquetas por linha**, cada **10 mm (altura) × 30 mm (comprimento)**, Zebra ZT230 **203 dpi**.

Layout visual (template NiceLabel):

```
┌──────────────────────────────────────┐
│ [NOME PRODUTO]       MADE IN         │
│ (fundo preto)          BRAZIL          │
│           1234567890                 │  ← serial (variável)
└──────────────────────────────────────┘
```

> **Layout atual (ZPL fornecido):** faixa preta + origem + **serial legível** (sem código de barras ITF). ITF pode ser adicionado depois se o posto exigir leitura por scanner.

---

## Como obter ZPL quando o NiceLabel não tem “Export ZPL”

Muitas edições do NiceLabel **não** têm `File → Export → ZPL`. Use um destes métodos (do mais fácil ao alternativo):

### Método 1 — Imprimir para arquivo (recomendado)

1. Instale o driver **ZDesigner ZT230-203dpi ZPL** (ou use a impressora USB já configurada).
2. Painel de Controle → Impressoras → ZT230 → **Propriedades da impressora** → aba **Portas**.
3. Adicione porta **FILE:** (Print to File) e aponte para `C:\temp\nicelabel-test.zpl`.
4. No NiceLabel: **File → Print** (ou Ctrl+P) → impressora ZT230 → **Print**.
5. Abra `C:\temp\nicelabel-test.zpl` no Bloco de Notas — conteúdo começa com `^XA` e termina com `^XZ`.

**Dica:** volte a porta da impressora para **USB** depois do teste.

### Método 2 — Copiar posições do NiceLabel (sem ZPL)

Mesmo sem export, dá para calibrar o app:

1. Clique em cada objeto → painel **Properties** / **Position**:
   - anote **X, Y, Width, Height** (mm)
2. Anote **Label Setup** → largura 30 mm, altura 10 mm, 3 colunas, gaps.
3. Barcode → symbology **ITF**, module width, height, human readable.
4. Converta mm → dots: **`dots = mm × 8`** (203 dpi).

Preencha `stock-spec.md` (modelo abaixo) e envie ao dev — o ZPL é montado no app.

### Método 3 — Zebra Setup Utilities

1. Imprima **uma** etiqueta pelo NiceLabel na ZT230.
2. Zebra Setup Utilities → **View Print Queue** / log (depende da versão).
3. Algumas instalações guardam o job RAW; se não aparecer, use o Método 1.

### Método 4 — NiceLabel Designer (se existir na sua licença)

- **File → Export → Printer Code → ZPL**
- ou **Store to printer** / **Send to printer** com opção “Include ZPL”
- Versões **Express** costumam **não** exportar ZPL; **Designer Pro** costuma exportar.

---

## O que anotar no NiceLabel (checklist)

Copie para `stock-spec.md`:

| Campo | Valor |
|-------|--------|
| Largura etiqueta | 30 mm |
| Altura etiqueta | 10 mm |
| Colunas | 3 |
| Gap horizontal | ___ mm |
| Gap vertical | ___ mm |
| DPI | 203 |
| Simbologia barcode | ITF / Interleaved 2 of 5 |
| Serial exemplo | 0412603646 |
| Texto fixo produto | DP1000 220V |
| Texto fixo origem | MADE IN BRAZIL |

Posições (mm) de cada objeto:

| Objeto | X | Y | Largura | Altura |
|--------|---|---|---------|--------|
| Retângulo preto | | | | |
| Texto DP1000 220V | | | | |
| MADE IN / BRAZIL | | | | |
| Barcode | | | | |
| Serial legível | | | | |

---

## ZPL de rascunho (1 etiqueta — calibrar na impressora)

Gerado a partir do layout da captura de tela. **Substituir** pelo ZPL do Método 1 quando conseguir imprimir para arquivo.

Serial de teste: `0412603646`. Ajuste `^FO` após comparar com amostra NiceLabel.

```zpl
^XA
^PW240
^LL80
^FO2,1^GB118,16,16,B,0^FS
^FO6,3^A0N,11,11^FR^FD DP1000 220V ^FS
^FO155,1^A0N,9,9^FDMADE IN^FS
^FO155,11^A0N,9,9^FDBRAZIL^FS
^FO8,22^BY1,2,22^BI,N,22,N,N^FD0412603646^FS
^FO70,58^A0N,14,14^FD0412603646^FS
^XZ
```

### Linha com 3 etiquetas (mesmo serial de teste em cada coluna)

Offsets X aproximados para 30 mm + gap (~2 mm → 16 dots): colunas em **0**, **256**, **512**. Ajuste após medir o rolo real.

```zpl
^XA
^PW780
^LL80
^FO2,1^GB118,16,16,B,0^FS
^FO6,3^A0N,11,11^FR^FD DP1000 220V ^FS
^FO155,1^A0N,9,9^FDMADE IN^FS
^FO155,11^A0N,9,9^FDBRAZIL^FS
^FO8,22^BY1,2,22^BI,N,22,N,N^FD0412603646^FS
^FO70,58^A0N,14,14^FD0412603646^FS
^FO258,1^GB118,16,16,B,0^FS
^FO262,3^A0N,11,11^FR^FD DP1000 220V ^FS
^FO411,1^A0N,9,9^FDMADE IN^FS
^FO411,11^A0N,9,9^FDBRAZIL^FS
^FO264,22^BY1,2,22^BI,N,22,N,N^FD0412603646^FS
^FO326,58^A0N,14,14^FD0412603646^FS
^FO514,1^GB118,16,16,B,0^FS
^FO518,3^A0N,11,11^FR^FD DP1000 220V ^FS
^FO667,1^A0N,9,9^FDMADE IN^FS
^FO667,11^A0N,9,9^FDBRAZIL^FS
^FO520,22^BY1,2,22^BI,N,22,N,N^FD0412603646^FS
^FO582,58^A0N,14,14^FD0412603646^FS
^XZ
```

**Testar:** Configurações → Testar impressão (cole o ZPL de 1 etiqueta) ou Zebra Setup Utilities → Send `.zpl`.

---

## Próximos passos

1. Tentar **Método 1** (Print to File) e salvar o `.zpl` real como `nicelabel-row-3x.zpl` nesta pasta.
2. Preencher `stock-spec.md` com gaps medidos na régua.
3. Rodar `/opsx:apply nicelabel-zpl-calibration` para alinhar `zpl_generator.dart` ao layout completo (DP1000 + MADE IN BRAZIL + ITF).
