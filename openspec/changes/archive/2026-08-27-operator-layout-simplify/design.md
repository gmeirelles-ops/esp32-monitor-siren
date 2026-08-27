## Context

Posto Windows, operadores de linha com pouca familiaridade com UI. Gatilho físico da gravação: **pedal** (não tecla F2). O software do laser pode mapear o pedal ao mesmo ciclo que a doc DiatuCAD chama de F2 — isso é detalhe técnico, não linguagem da linha.

## Goals / Non-Goals

**Goals**

- Zero destinos mortos para o operador.
- Em 2 segundos: “aperte o botão da bancada” / “passou ou falhou” / “pise no pedal para gravar”.
- Formulário de início de lote com o mínimo de campos e um CTA claro.

**Non-Goals**

- Mudar protocolo TCP ou job do DiatuCAD.
- Redesign do Painel do gestor.
- Renomear pasta `features/labels/`.
- Overhaul mobile do gestor.

## Decisions

### 1. Nav operador: Lote | Gravação

Consulta é papel de qualidade/gestor. Regravação: fila em **Gravação**.

### 2. Ao vivo: um “palco”

Operador: hero veredito → progresso → **“Acione o pedal”** se fila pendente. Diagnóstico só gestor.

### 3. Copy: pedal na linha, F2 só no fundo técnico

| Audiência | Texto |
|-----------|--------|
| Operador (Lote ao vivo, Gravação, remark, callout) | “Acione o pedal para gravar” |
| Gestor / Configurações / laser-reference | Pode citar pedal = gatilho do job (equiv. F2 no software) |

Centralizar strings em helper (ex. `laserOperatorCopy`) para não espalhar F2 de novo.

### 4. Lote: um fluxo

Poucos cards, `ResponsiveFieldRow`, CTA “Iniciar lote”.

### 5. Tokens

`kFormMaxWidth` 600, `kPageContentMaxWidth` 900, breakpoint 900.

## Risks

- Docs antigas ainda dizem F2 — atualizar callouts do app nesta change; referência laser pode ganhar uma linha “no posto: pedal”.
