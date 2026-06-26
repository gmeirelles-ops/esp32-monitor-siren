## 1. Protocolo e servidor TCP

- [x] 1.1 Adicionar `normalizeTcpPayload` e aplicar em `matchesDiatuTcpCommand`
- [x] 1.2 Registrar eventos de conexão (`LaserTcpEvent` ring buffer, max 20)
- [x] 1.3 Melhorar mensagem de erro quando `bind` falha (porta ocupada)
- [x] 1.4 Testes unitários: CRLF, comando parcial, fila vazia, BADCMD

## 2. Testes automatizados E2E

- [x] 2.1 Teste: `ServerSocket` real + cliente TCP envia comando válido → recebe serial
- [x] 2.2 Teste: comando inválido → `ERROR:BADCMD`
- [x] 2.3 Teste: fila vazia → `ERROR:EMPTY`
- [x] 2.4 Teste: múltiplas conexões sequenciais (simula F2 repetido)

## 3. UI de diagnóstico

- [x] 3.1 Provider `laserDiagnosticsProvider` (status, fila, últimos eventos)
- [x] 3.2 Card em Configurações: servidor ativo/porta/erro + contagem fila
- [x] 3.3 Exibir último comando/resposta e log rolante
- [x] 3.4 Botão **Simular DiatuCAD** (cliente TCP local + resultado na UI)
- [x] 3.5 Validação ao salvar: comando vazio bloqueado; hint com valor padrão

## 4. Scripts e documentação

- [x] 4.1 Criar `scripts/test_laser_tcp.ps1` (parâmetros porta/comando)
- [x] 4.2 Atualizar `docs/laser-reference/diatu-tcp.md` — troubleshooting, conflito Marca de controlo TCP
- [x] 4.3 Atualizar `docs/PRODUCAO.md` — checklist laser (8 passos)
- [x] 4.4 Adicionar seção troubleshooting em `docs/laser-reference/README.md`

## 5. Validação em bancada (posto)

- [ ] 5.1 Checklist: app modo laser + comando idêntico ao DiatuCAD + Marca de controlo TCP **desativada**
- [ ] 5.2 Testar gravação com serial `0000000000` via botão Testar + F2
- [ ] 5.3 Aprovar sirene real → serial na fila → F2 grava ITF na carcaça
- [ ] 5.4 Capturar log do painel diagnóstico em caso de falha e anexar ao relatório
