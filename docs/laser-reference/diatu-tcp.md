# DiatuCAD — protocolo TCP (texto variável)

Software: **Diatu Industrial / DiatuCAD1** (equivalente EzCad2).

## Modelo de comunicação

O **app Sirene** atua como **servidor TCP**. O **DiatuCAD** (no PC do laser) conecta como cliente ao pressionar **F2 (Marcação)** quando o texto usa **Texto variável → Comunicação TCP/IP**.

```
DiatuCAD  ──TCP connect──►  App Sirene (0.0.0.0:porta)
DiatuCAD  ──comando──────►  ex. "TCP: Give me string"
App       ◄──serial──────   ex. "1232600018"
DiatuCAD grava o serial na peça
```

## Configuração no DiatuCAD

1. Desenhar texto na posição da carcaça.
2. Selecionar texto → **Texto variável** → **Adicionar** → **Comunicação TCP/IP**.
3. **IP:** endereço do PC onde roda o app Sirene (mesma máquina: `127.0.0.1`).
4. **Porta:** igual à configurada no app (padrão `9101`).
5. **Comando:** igual ao configurado no app (padrão `TCP: Give me string`).
6. Salvar job (ex. `sirene_serial.ezd`).

Referência EzCad/Diatu: [variable text TCP](https://www.linxuanlaser.com/draw-menu-variable-text/).

## Protocolo (v1)

| Direção | Conteúdo |
|---------|----------|
| Cliente → Servidor | String ASCII do comando configurado (ex. `TCP: Give me string`) |
| Servidor → Cliente | Serial ITF de 10 dígitos ASCII (ex. `1232600018`) |
| Fila vazia | `ERROR:EMPTY` |

Unicode: desativado (ASCII).

## Dois modos TCP no Diaotu (não confundir)

| Modo no Diaotu | Quem escuta (servidor) | Usar com app Sirene? |
|----------------|------------------------|----------------------|
| **Texto variável → Comunicação TCP/IP** | **App Sirene** | **Sim** — este é o fluxo correto |
| **Menu → Marca de controlo TCP** | **DiatuCAD** | **Não** — conflita com o app na mesma porta |

Se **Marca de controlo TCP** estiver ativo na porta `9101`, o app não conseguirá abrir o servidor e você verá erro de porta em uso.

### Marca de controlo TCP — não usar com o app Sirene

O manual do Diaotu descreve outro recurso (**Menu → Marca de controlo TCP**):

- DiaotuCAD **escuta** na porta (ex. 9101) como **servidor**
- Um dispositivo externo conecta como **cliente** e envia comandos nativos da placa para disparar o laser
- Estado muda para *Listening* / *Ouvindo* no próprio Diaotu

Isso é integração **remota de controle da máquina**, não busca de serial para texto variável.

| | Marca de controlo TCP (manual Diaotu) | Texto variável TCP (app Sirene) |
|--|--------------------------------------|----------------------------------|
| Servidor | **DiatuCAD** | **App Sirene** |
| Cliente | Seu script / PLC / firmware | **DiatuCAD** (ao pressionar F2) |
| Objetivo | Disparar marcação por comando | Obter serial dinâmico para gravar |
| Porta 9101 | Diaotu ocupa | App ocupa |

**No posto com app Sirene:**

1. **Desmarque** *Activar a marcação TCP* em Marca de controlo TCP (ou use outra porta, ex. 9102, só se precisar desse modo para outro fim).
2. Configure o **texto do job** em *Texto variável → Comunicação TCP/IP* (IP `127.0.0.1`, porta `9101`, comando `TCP: Give me string`).
3. No app: modo **Gravação laser**, mesma porta e mesmo comando → **Salvar**.

Quem deve aparecer em `LISTENING` na 9101 é o `sirene_app.exe`, não o DiaotuCAD:

```powershell
netstat -ano | findstr 9101
```

## Troubleshooting

| Resposta / sintoma | Causa provável | Ação |
|--------------------|----------------|------|
| `ERROR:BADCMD` na tela do DiatuCAD | Comando no app ≠ comando no DiatuCAD | Copiar o mesmo texto nos dois lados |
| `ERROR:EMPTY` | Fila sem serial pendente | Aprovar sirene ou **Testar gravação** nas Configurações |
| `ERROR:SERVER` | Exceção interna no app | Ver painel **Diagnóstico laser** em Configurações |
| Não conecta | App não em modo laser ou porta ocupada | Salvar config; desativar Marca de controlo TCP |
| `TIME_WAIT` no netstat | DiatuCAD conectou e fechou (normal) | Verifique se a resposta foi serial ou ERROR:* |

### Checklist rápido (8 passos)

1. App: **Configurações → Gravação laser (Diatu)** → **Salvar**
2. Comando app = comando DiatuCAD (padrão: `TCP: Give me string`)
3. DiatuCAD: texto variável → TCP/IP → IP `127.0.0.1`, mesma porta
4. **Desativar** Marca de controlo TCP no Diaotu (ou usar outra porta)
5. Clicar **Testar gravação** (enfileira `0000000000`)
6. No painel diagnóstico: **Simular DiatuCAD** → deve retornar `0000000000`
7. DiatuCAD: F1 posicionar → F2 marcar
8. Aprovar sirene real → F2 deve gravar serial ITF

### Verificar porta no Windows

```powershell
netstat -ano | findstr 9101
```

PID em `LISTENING` deve ser o `sirene_app.exe` (não o DiatuCAD).

## Equipamento

- Laser: [Diaotu B3](https://www.alibaba.com/product-detail/Diaotu-fiber-laser-engraving-machine-plastic_1601355822930.html) (fibra, plástico/metal).
- Homologação física (potência, velocidade, contraste) feita no DiatuCAD — fora do app.

## Teste manual (laser físico)

1. App em modo **Gravação laser**, porta `9101`, configuração **Salva**.
2. Aprovar sirene na bancada → serial entra na fila.
3. No DiatuCAD, F1 (luz vermelha) → posicionar → F2.
4. Verificar gravação na carcaça.

Teste de rede sem laser:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test_laser_tcp.ps1 -Port 9101 -Command "TCP: Give me string"
```

Ou manualmente:

```powershell
$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 9101)
$stream = $client.GetStream()
$bytes = [Text.Encoding]::ASCII.GetBytes("TCP: Give me string")
$stream.Write($bytes, 0, $bytes.Length)
$buf = New-Object byte[] 64
$n = $stream.Read($buf, 0, 64)
[Text.Encoding]::ASCII.GetString($buf, 0, $n)
$client.Close()
```
