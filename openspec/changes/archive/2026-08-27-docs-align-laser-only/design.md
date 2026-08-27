## Context

O app já força `markingMode => MarkingMode.laser` em `app_config.dart`, mas o enum `labels`, setters, UI de impressora, ZPL e `LabelBuffer` ainda existem. Docs misturam Zebra e laser e subestimam a versão do firmware.

## Goals / Non-Goals

**Goals**

- Documentação operacional e de firmware coerente com **1.8.10** e laser-only.
- Código e UI do `sirene_app` sem caminho Zebra executável ou configurável.
- Specs OpenSpec refletem o produto interno real.

**Non-Goals**

- Mudanças de protocolo MQTT ou firmware C.
- Segurança / TLS / Firestore rules.
- Refator grande do `DevicesNotifier` (só remover ramos Zebra).
- Novo protocolo laser; manter TCP DiatuCAD atual (`docs/laser-reference/`).

## Decisions

1. **Laser é o único modo** — remover `MarkingMode` (ou reduzir a constante interna sem storage). Preferências `marking_mode`, `printer_*` deixam de ser lidas/escritas.
2. **Apagar código Zebra**, não apenas esconder: `zpl_generator`, `tcp_label_printer`, `windows_raw_label_printer`, `label_buffer_grouping`, fluxos `_maybePrintLabels`, settings de impressora, testes associados.
3. **MarkQueue permanece** — aprovação → enfileira serial → DiatuCAD puxa via TCP server.
4. **Remark** — apenas “Regravar” / fila laser; auditoria `remark_log` com `mode: laser` (ou equivalente único).
5. **DB** — parar de usar `LabelBufferEntries`. Preferência: **schema bump** que remove a tabela se Drift permitir sem quebrar restores antigos; se risco alto em campo, deixar tabela órfã sem writes (documentar). Decisão de implementação: dropar na próxima migration se testes de migration passarem; senão orphan.
6. **Docs label-reference** — mover para `docs/label-reference/` como histórico **ou** deletar. Decisão: **manter pasta** com README curto “obsoleto — produto usa laser”; evita quebrar links externos. Não citar Zebra em PRODUCAO/README como fluxo ativo.
7. **Nomenclatura** — docs usam **Diatu / DiatuCAD** (não “Diatom”), alinhado ao código e `docs/laser-reference/`.
8. **Firmware docs** — atualizar versão, heartbeat **10 s**, diagramas sem Zebra; checklist OTA/release apontando `1.8.10`.

## Risks / Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Posto antigo ainda com Zebra | Produto interno confirmou laser-only; release notes avisam remoção |
| Migration Drift quebra DB de campo | Testar upgrade schema; fallback orphan table |
| Specs removidas quebram links em archives | Archives históricos ficam; main specs atualizam |

## Migration Plan

1. Implementar remoção de código + testes verdes.
2. Atualizar docs na mesma PR/change.
3. Ao arquivar, sync deltas → `openspec/specs/` (apagar ou esvaziar capabilities Zebra removidas).
4. Sem dist automático — perguntar ao usuário se quiser ZIP/setup.

## Open Questions

- _(nenhuma bloqueante)_ — laser-only confirmado pelo usuário.
