# Gravação laser Diatu — referência

Substitui etiquetas Zebra por gravação permanente do serial ITF na carcaça da sirene.

## Documentos

| Arquivo | Conteúdo |
|---------|----------|
| [diatu-tcp.md](./diatu-tcp.md) | Protocolo TCP servidor/cliente com DiatuCAD |

## Homologação (operador)

### 0.1 Equipamento confirmado

- Laser **Diaotu B3** (fibra)
- Software **DiatuCAD1** com menu **Controlo TCP(T)**
- Placa de controle conectada via USB (sair do modo demonstração)

### 0.2 Template de gravação

1. Criar job com texto ITF 10 dígitos.
2. Configurar **Texto variável → TCP/IP** (ver [diatu-tcp.md](./diatu-tcp.md)).
3. Ajustar fonte/tamanho para legibilidade na carcaça ABS.

### 0.3 Validação física

- Gravar serial de teste (`0000000000` via Configurações).
- Verificar contraste e leitura visual a 30 cm.
- Documentar potência/velocidade finais no job salvo.

## Troubleshooting

Sintomas comuns e soluções: [diatu-tcp.md](./diatu-tcp.md#troubleshooting).

Resumo:
- `ERROR:BADCMD` → comando TCP diferente entre app e DiatuCAD
- Porta em uso → desativar **Marca de controlo TCP** no Diaotu
- Use o painel **Diagnóstico laser** em Configurações (log + Simular DiatuCAD)

## Posto com laser vs etiquetas

| Modo | Quando usar |
|------|-------------|
| **Etiquetas (Zebra)** | Postos com ZT230 e rolo adesivo |
| **Gravação laser (Diatu)** | Posto com laser B3 + DiatuCAD |

Alternar em **Configurações → Marcação de serial**.
