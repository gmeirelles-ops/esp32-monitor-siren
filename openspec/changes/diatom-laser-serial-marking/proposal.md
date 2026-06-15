## Why

Hoje cada sirene aprovada gera serial e imprime **etiqueta adesiva** na Zebra ZT230 (ZPL, rolo 3×10×30 mm). A Diponto possui um **laser Diatom** capaz de gravar permanentemente o número de série na carcaça da peça — eliminando consumível de etiqueta, desalinhamento de rolo e passo extra de colagem. Integrar o laser ao fluxo do app mantém a mesma geração de serial ITF e rastreabilidade, trocando apenas o **backend de marcação física**.

## What Changes

- Novo modo de marcação em **Configurações**: `Etiquetas (Zebra)` | `Gravação laser (Diatom)` — um posto usa um ou outro.
- Abstração `SerialMarkingBackend` (similar ao transporte ZPL existente) com implementação TCP para o controlador/software do laser Diatom.
- Após aprovação: enviar **um serial por vez** ao laser (sem buffer de múltiplos de 3 nem layout 3-across).
- Job/template de gravação pré-configurado no laser (campo variável `serial` + opcional código 2D); app envia o serial dinamicamente.
- Fila local de gravações pendentes + retry em falha de comunicação (análogo leve à SyncQueue).
- UI: tela **Gravação** (ou extensão de Etiquetas) com fila pendente, teste de conexão, regravação manual por serial.
- Documentação de homologação: material da sirene, foco, template EzCad/Diatom, protocolo TCP confirmado com manual do equipamento.
- Modo Zebra **inalterado** quando selecionado — postos com etiqueta continuam como hoje.

## Capabilities

### New Capabilities

- `diatom-laser-marking`: integração TCP, template de gravação, envio de serial e fila de retry.
- `marking-mode-selection`: escolha global Etiquetas vs Laser e configuração de rede/host do laser.

### Modified Capabilities

- `label-printing`: requisitos de buffer ZPL aplicam-se somente quando modo = Etiquetas.
- `serial-and-labels`: geração ITF igual; disparo de marcação física depende do modo ativo.
- `desktop-ui-layout`: Configurações e navegação refletem modo laser (Etiquetas vs Gravação).

## Impact

- `sirene_app/lib/features/labels/` — abstração de backend, cliente TCP Diatom, fila de gravação
- `sirene_app/lib/core/config/app_config.dart` — `MarkingMode`, host/porta laser, template id
- `sirene_app/lib/features/mqtt/mqtt_providers.dart` — `_maybePrintLabels` vs `_maybeMarkSerial`
- `sirene_app/lib/features/settings/settings_screen.dart` — config laser + teste
- `docs/PRODUCAO.md` — checklist posto com laser
- **Hardware:** laser Diatom + PC Windows na rede LAN; template de gravação no software do laser
- **Dependência de protocolo:** manual/API Diatom (a confirmar na fase 0 de homologação)
