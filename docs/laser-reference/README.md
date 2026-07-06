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

1. Criar job com **DataMatrix** alimentado por TCP (`TCP: Give me string`) — ver [diatu-tcp.md](./diatu-tcp.md#job-com-datamatrix--texto-do-modelo).
2. Adicionar **texto do modelo** com TCP (`TCP: model`) se quiser nome dinâmico do produto.
3. Validar que dois objetos TCP com comandos distintos funcionam no mesmo job (F2).
4. Ajustar tamanho do DataMatrix e fonte do texto para legibilidade na carcaça ABS.

### 0.3 Validação física

- Gravar serial de teste (`0000000000` via Configurações).
- Verificar contraste e leitura visual a 30 cm.
- Documentar potência/velocidade finais no job salvo.

## Troubleshooting

Sintomas comuns e soluções: [diatu-tcp.md](./diatu-tcp.md#troubleshooting).

Resumo:
- `ERROR:BADCMD` → comando TCP diferente entre app e DiatuCAD
- Porta em uso → desativar **Marca de controlo TCP** no Diaotu
- Use o painel **Diagnóstico laser** em Configurações (log + Simular serial / Simular modelo)

## Posto com laser vs etiquetas

| Modo | Quando usar |
|------|-------------|
| **Etiquetas (Zebra)** | Postos com ZT230 e rolo adesivo |
| **Gravação laser (Diatu)** | Posto com laser B3 + DiatuCAD |

Alternar em **Configurações → Marcação de serial**.
