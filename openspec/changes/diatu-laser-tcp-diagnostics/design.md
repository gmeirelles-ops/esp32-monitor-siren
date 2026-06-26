## Context

Arquitetura implementada (change `diatom-laser-serial-marking`):

```
DiatuCAD (cliente) ──connect──► App Sirene ServerSocket :9101
DiatuCAD ──"TCP: Give me string"──► App
App ◄── serial ITF 10 dígitos ── ou ERROR:BADCMD / ERROR:EMPTY
```

O DiatuCAD exibe o **texto retornado pelo TCP** no campo variável. Por isso `ERROR:BADCMD` aparece fisicamente na pré-visualização/gravação — não é bug do laser, é resposta do app.

### Causas prováveis observadas no posto

| # | Sintoma | Causa provável |
|---|---------|----------------|
| 1 | `ERROR:BADCMD` na peça/tela | Comando no app ≠ comando no DiatuCAD (ex. `S1=123456` vs `TCP: Give me string`) |
| 2 | App não sobe servidor | Modo ainda em Etiquetas; config não salva; porta ocupada |
| 3 | Conflito porta 9101 | **Marca de controlo TCP** do Diaotu ativo (Diatu escuta na porta) enquanto app também tenta escutar |
| 4 | `ERROR:EMPTY` | Fila `mark_queue` vazia — operador não aprovou sirene nem clicou “Testar gravação” |
| 5 | Conexões TIME_WAIT | DiatuCAD conecta repetidamente (normal após F2); indica rede OK mas resposta rejeitada |

## Goals / Non-Goals

**Goals:**

- Operador/integrador identifica em **&lt; 2 minutos** qual camada falhou (porta, comando, fila, laser).
- Testes automatizados cobrem protocolo TCP v1 sem hardware.
- Documentação elimina confusão entre os dois modos TCP do Diaotu/EzCad.

**Non-Goals:**

- Alterar protocolo do Diaotu ou suportar “Marca de controlo TCP” como servidor remoto.
- Controle do laser por outro protocolo (RS-232, USB direto).
- Assinatura digital ou criptografia TCP.

## Decisions

### 1. Diagnóstico em Configurações (não tela separada)

Card expansível abaixo dos campos laser com:
- Servidor: `Ativo em :9101` / `Parado` / `Erro: porta em uso`
- Fila: `N pendentes`
- Última conexão: timestamp, comando recebido (truncado), resposta enviada
- Log rolante (últimas 20 linhas)

**Alternativa:** tela Debug separada — rejeitada (operador já está em Configurações).

### 2. Ring buffer de eventos no `DiatuLaserTcpServer`

```dart
class LaserTcpEvent {
  final DateTime at;
  final String remote;
  final String? request;
  final String? response;
  final String? error;
}
```

Exposto via `ChangeNotifier` ou `Stream` consumido pelo `MarkQueueProcessor` e Riverpod.

### 3. Matching de comando mais tolerante

```dart
bool matchesDiatuTcpCommand(String request, String commandPrefix) {
  final r = normalizeTcpPayload(request);
  final p = normalizeTcpPayload(commandPrefix);
  if (p.isEmpty) return r.isNotEmpty;
  return r.contains(p);
}

String normalizeTcpPayload(String s) =>
    s.replaceAll('\r', '').replaceAll('\n', '').trim();
```

Comparação case-sensitive (DiatuCAD envia exatamente como configurado); documentar que operador deve copiar/colar o mesmo texto nos dois lados.

### 4. Detecção de porta ocupada

Ao `ServerSocket.bind` falhar com `SocketException` (address already in use):
- Gravar `lastError` com mensagem clara: “Porta 9101 em uso. Desative ‘Marca de controlo TCP’ no Diaotu ou mude a porta.”
- Sugerir `netstat -ano | findstr 9101` na documentação.

### 5. Botão “Simular DiatuCAD”

Cliente TCP em isolate ou `Future`: conecta `127.0.0.1:porta`, envia `laserTcpCommand`, lê resposta, mostra em SnackBar/dialog. Não consome serial da fila (usa peek sem deliver) — **decisão:** simulação chama endpoint de teste que faz `peek` sem `markQueueDelivered`, ou enfileira serial de teste antes (comportamento atual do botão Testar).

### 6. Script PowerShell de bancada

`scripts/test_laser_tcp.ps1 -Port 9101 -Command "TCP: Give me string"` — espelha doc existente; retorna exit code ≠ 0 se resposta começa com `ERROR:`.

### 7. Documentação: dois modos TCP no Diaotu

| Modo no Diaotu | Quem é servidor | Usar com app Sirene? |
|----------------|-----------------|----------------------|
| Texto variável → Comunicação TCP/IP | **App Sirene** | **Sim** |
| Menu → Marca de controlo TCP | **DiatuCAD** | **Não** — conflita com app |

## Risks / Trade-offs

- **[Log com serial em texto]** → truncar em UI; não enviar a nuvem.
- **[Falso positivo porta ocupada]** → Windows TIME_WAIT não bloqueia bind; só processo LISTENING conflita.
- **[Operador ignora diagnóstico]** → checklist impresso em `LEIA-ME` do posto laser.

## Migration Plan

1. Implementar diagnóstico + testes (sem mudar protocolo).
2. Validar em bancada com checklist.
3. Se necessário, ajustar default ou wizard de primeiro uso laser.

## Open Questions

- PID 5024 no posto é `sirene_app.exe` ou `DiatuCAD`? Diagnóstico deve mostrar nome do processo se possível (futuro: `Get-Process -Id` hint na doc).
- DiatuCAD envia bytes adicionais após o comando (null, newline)? Capturar hex no log na primeira bancada.
