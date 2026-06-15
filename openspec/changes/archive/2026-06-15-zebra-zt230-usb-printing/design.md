## Context

O app Flutter desktop (Windows) no posto gera ZPL para etiquetas de sirene aprovadas e envia via `Socket.connect(host, port)` — modelo pensado para impressora de rede na porta 9100. A Zebra **ZT230** padrão oferece **USB** e **serial RS-232**; interface Ethernet é opcional (módulo separado). O rolo em uso tem **3 etiquetas por linha**, cada uma com aproximadamente **10 mm de altura × 30 mm de comprimento** (formato comum 3-across; o operador descreveu como "1 altura por 3 de comprimento" em centímetros).

O gerador ZPL atual (`^PW315`, `^LL120`, 3 colunas em `xPositions`) já reflete esse layout em 203 dpi. O gap está no **transporte**, não no layout.

Stakeholders: operador no posto (impressão confiável), TI (instalação simples), desenvolvimento (teste sem hardware via export ZPL).

## Goals / Non-Goals

**Goals:**

- Imprimir ZPL na ZT230 conectada por **USB ao mesmo PC** que executa o app, sem print server.
- Manter modo **rede TCP** para quem tiver cartão de rede ou print server no futuro.
- Preservar regras de negócio: buffer, múltiplos de 3, fechamento de órfãs, reimpressão, export ZPL em dev.
- Configuração clara em português na tela Configurações.

**Non-Goals:**

- Suporte USB em Linux/macOS nesta entrega (app já é Windows-first no posto).
- Impressão direta do firmware ESP32 (impressora fica no PC do operador).
- Redesenho completo do layout gráfico da etiqueta (apenas calibração fina se teste físico exigir).
- Driver Zebra como dependência de build — operador instala manualmente no Windows.

## Decisions

### 1. Transporte primário: RAW via spooler Windows (USB)

**Escolha:** Enviar bytes ZPL com datatype `RAW` para uma impressora Windows já instalada (nome ex.: `ZDesigner ZT230-203dpi ZPL`).

**Por quê:** A ZT230 USB é reconhecida pelo driver Zebra; o spooler aceita jobs RAW sem conversão para GDI. O app Flutter já roda no Windows do posto — não precisa de IP nem hardware extra.

**Alternativas descartadas:**

| Opção | Prós | Contras |
|-------|------|---------|
| TCP localhost + compartilhamento Windows | Reutiliza `LabelPrinter` atual | Frágil, depende de compartilhamento e firewall |
| Porta COM / serial USB | Direto, sem spooler | Operador precisa achar COM; menos amigável |
| Print server USB→Ethernet | Mantém código TCP | Custo extra, mais um ponto de falha |
| Browser Print / Zebra Browser Print | Web-friendly | App é Flutter desktop, não browser |

**Implementação:** Pacote `win32` — `OpenPrinter` → `StartDocPrinter` (RAW) → `WritePrinter` → `EndDocPrinter`. Encapsular em `WindowsRawLabelPrinter`.

### 2. Abstração de transporte

**Escolha:** Interface comum `Future<void> sendZpl(String zpl)`; fábrica lê `AppConfig.printerMode` (`usb` | `network`).

- `TcpLabelPrinter` — código atual (`host` + `port`)
- `WindowsRawLabelPrinter` — `printerName` do Windows

Injeção única nos pontos de uso: `mqtt_providers`, `labels_screen`, `batch_report_detail_screen`.

### 3. Configuração persistida

Novos campos em `SharedPreferences`:

- `printer_mode`: `usb` (padrão em Windows) ou `network`
- `printer_windows_name`: nome exato da impressora no Painel de Controle
- `printer_host` / `printer_port`: mantidos para modo rede

UI: segmented control **USB (local)** / **Rede**; em USB, dropdown populado via `EnumPrinters` (win32); em rede, IP + porta 70/30.

### 4. Layout ZPL e rolo 3-across

Manter `generateZplLabelRow` com 3 posições. Parâmetros atuais (203 dpi):

- Largura total da linha `^PW315` (~39 mm para 3×10 mm + gaps)
- Altura `^LL120` (~15 mm incluindo gap)
- Código de barras ITF (`^BI`) + texto humano abaixo

**Calibração:** Após primeiro teste físico, ajustar `^PW`, `^LL`, `^FO` e `^BY` se desalinhamento. Documentar no `LEIA-ME.txt` / `docs/PRODUCAO.md` procedimento de feed + calibrate na ZT230.

### 5. Descoberta e validação

- Botão **Testar impressão** em Configurações envia ZPL mínimo (`^XA^FO50,50^A0N,30,30^FDTESTE^FS^XZ`).
- Erros em português: impressora não encontrada, spooler offline, timeout.

### 6. Export ZPL em dev (já existente)

Continua como fallback para desenvolvimento sem impressora; conteúdo idêntico ao que seria enviado por USB ou rede.

### 7. Reimpressão sem desalinhar o rolo

**Escolha:** Reimpressão de um serial avulso SHALL emitir **uma linha completa** (3 posições no ZPL): serial na coluna 1, colunas 2 e 3 vazias (sem código de barras). O rolo físico avança uma linha inteira, preservando alinhamento para a próxima impressão de produção.

**Por quê:** Operador confirmou que imprimir só 1 etiqueta desalinhando o rolo **não é aceitável**. O desperdício de 2 etiquetas em branco na linha é preferível à perda de sincronia do rolo 3-across.

**UI:** Ao reimprimir, avisar em português que a impressora consumirá uma linha de 3 posições (1 com o serial, 2 em branco).

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Nome da impressora muda após reinstall | Dropdown + botão atualizar lista; validar no teste |
| Driver em modo gráfico em vez de ZPL | Instalar driver ZDesigner ZPL; doc enfatiza modelo ZPL |
| `win32` só funciona em Windows | Guard `Platform.isWindows`; modo rede em outras plataformas |
| Desalinhamento físico do rolo | Teste de calibração documentado; constantes centralizadas em `zpl_generator.dart` |
| Múltiplos postos, uma impressora USB | Fora de escopo — cada posto com sua ZT230 USB; rede se compartilhar |

## Migration Plan

1. Instalar driver Zebra no PC do posto; conectar ZT230 via USB; anotar nome da impressora.
2. Atualizar app; em Configurações escolher **USB** e selecionar impressora.
3. Acionar **Testar impressão**; calibrar rolo na impressora se necessário.
4. Postos com print server existente: manter modo **Rede** com IP/porta atuais — sem breaking change.
5. Rollback: reverter binário; config antiga de rede permanece em `SharedPreferences`.

## Decisões confirmadas (operador)

| # | Pergunta | Resposta | Implicação |
|---|----------|----------|------------|
| 1 | Dimensão da etiqueta | **10×30 mm**, 3 por linha | ZPL atual (`^PW315`, `^LL120`) mantido; calibração fina só se teste físico exigir |
| 2 | Uma ZT230 por posto? | **Sim** — USB no PC do app | Modo USB local; sem print server |
| 3 | Windows 10/11 x64? | **Sim** | `win32` RAW printing como transporte primário |
| 4 | Driver Zebra ZPL instalado? | **Sim** | Setup reduzido a selecionar nome da impressora |
| 5 | Lote com reprovações | **Imprime a quantidade de etiquetas do lote** (uma por aprovação) | Fluxo de lote independente da impressão; etiqueta só em aprovação |
| 6 | Órfãs (1–2 no buffer) | **Manual** por enquanto | Sem auto-print ao fechar lote; gatilho manual permanece |
| 7 | Modo reteste | **Sim** — sem serial nem etiqueta | Comportamento atual preservado |
| 8 | Reimpressão avulsa desalinhando rolo | **Não aceitável** | Ver decisão §7: linha completa com 2 colunas vazias |
| 9 | Smoke test físico | *(esclarecido abaixo)* | Quem instalar o posto testa na hora |
| 10 | Log de impressão no SQLite | **Não** | Fora de escopo |

### Esclarecimento da pergunta 9 (smoke test)

**Smoke test** = primeiro teste real na impressora após configurar o posto: conectar USB, escolher impressora no app, acionar **Testar impressão**, imprimir uma linha de 3 seriais de teste e validar alinhamento do código de barras. Não precisa de pessoa dedicada — quem fizer a instalação (operador ou TI) executa esse checklist uma vez por posto.
