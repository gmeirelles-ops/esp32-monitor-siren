## Why

Após diversos testes em bancada com laser **Diaotu B3 + DiatuCAD1**, a gravação via app **não funcionou**. O operador vê `ERROR:BADCMD` gravado na tela do DiatuCAD — que é exatamente a resposta de erro do servidor TCP do app quando o comando recebido não confere com o configurado.

Evidências do posto:
- App em modo **Gravação laser**, porta `9101`, mas em um teste o comando no app estava `S1=123456` enquanto o DiatuCAD envia `TCP: Give me string`.
- `netstat` mostra porta `9101` em `LISTENING` e várias conexões `TIME_WAIT` de `127.0.0.1` — há tráfego, mas o handshake de comando falha ou há conflito com **Marca de controlo TCP** do Diaotu (outro modo que também usa a porta).
- O servidor TCP do app existe e responde; falta **visibilidade**, **testes automatizados** e **checklist** para isolar cada camada (rede → comando → fila → gravação física).

## What Changes

- Painel de **diagnóstico laser** em Configurações: status do servidor (ativo/porta/erro), último comando recebido, última resposta, tamanho da fila `mark_queue`, log das últimas N conexões.
- **Detecção de conflito de porta** ao iniciar servidor: avisar se outro processo (ex. Diaotu “Marca de controlo TCP”) já ocupa a porta.
- **Validação de configuração** ao salvar: comando não vazio; alerta se comando difere do padrão EzCad/Diatu sem confirmação.
- Botão **“Simular DiatuCAD”** no app: cliente TCP local envia o comando configurado e exibe a resposta (sem precisar do laser).
- Testes automatizados: servidor TCP end-to-end (bind, comando válido → serial, comando inválido → `ERROR:BADCMD`, fila vazia → `ERROR:EMPTY`).
- Script PowerShell `scripts/test_laser_tcp.ps1` para teste de rede fora do app.
- Documentação ampliada: distinguir **Texto variável TCP** (app = servidor) vs **Marca de controlo TCP** (Diatu = servidor — **desativar** ao usar o app); checklist de troubleshooting com capturas do posto.

## Capabilities

### New Capabilities

- `diatu-laser-diagnostics`: painel de status, log de conexões, simulação de cliente, detecção de porta ocupada.

### Modified Capabilities

- `diatom-laser-marking`: respostas de erro documentadas; matching de comando mais tolerante (trim, CRLF); servidor reporta estado observável.
- `marking-mode-selection`: validação de comando/porta na UI de Configurações.

## Impact

- `sirene_app/lib/features/labels/diatu_laser_tcp_server.dart` — log de eventos, matching robusto
- `sirene_app/lib/features/labels/mark_queue_processor.dart` — expor estado para UI
- `sirene_app/lib/features/settings/settings_screen.dart` — painel diagnóstico + simular cliente
- `sirene_app/test/diatu_laser_tcp_server_test.dart` — testes E2E TCP
- `docs/laser-reference/diatu-tcp.md` — troubleshooting e conflito de portas
- `docs/PRODUCAO.md` — checklist laser
- `scripts/test_laser_tcp.ps1` — teste manual de rede
