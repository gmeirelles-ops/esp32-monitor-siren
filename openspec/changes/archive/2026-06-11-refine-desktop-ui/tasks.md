## 1. Fundação — tema e widgets compartilhados

- [x] 1.1 Criar `core/constants/layout.dart` com `kDesktopBreakpoint = 900` e `kFormMaxWidth = 600`
- [x] 1.2 Adicionar `DipontoColors.cardElevated` (`#1E1E1E`) e ajustar `inputDecorationTheme.enabledBorder` em `diponto_theme.dart`
- [x] 1.3 Adicionar `outlinedButtonTheme` neutro em `diponto_theme.dart`
- [x] 1.4 Criar `shared/widgets/desktop_form_layout.dart` (`Center` + `ConstrainedBox`)
- [x] 1.5 Criar `shared/widgets/form_section_card.dart` (título + child em Card elevado)
- [x] 1.6 Criar `shared/widgets/responsive_field_row.dart` (Row em desktop, Column em mobile)
- [x] 1.7 Criar `shared/widgets/empty_state_view.dart` (ícone, título, subtítulo, progress opcional)

## 2. Navegação lateral

- [x] 2.1 Ajustar `NavigationRail` em `app.dart`: `minWidth` ≥ 88, `indicatorShape` arredondado, `indicatorColor` amber ~15%
- [x] 2.2 Validar contraste do item selecionado em todas as seis destinações

## 3. Tela Configurações

- [x] 3.1 Envolver conteúdo em `DesktopFormLayout`
- [x] 3.2 Agrupar Broker MQTT, Impressora Zebra e Nuvem em `FormSectionCard` cada
- [x] 3.3 Host + Porta MQTT na mesma linha (`ResponsiveFieldRow` 70/30)
- [x] 3.4 IP + Porta impressora na mesma linha (70/30)
- [x] 3.5 Botão Salvar com largura intrínseca (não full-width) em desktop

## 4. Tela Lote

- [x] 4.1 Envolver formulário em `DesktopFormLayout`
- [x] 4.2 Ano + Quantidade + Próximo sequencial em `ResponsiveFieldRow` (desktop)
- [x] 4.3 "Configurar lote" como `ElevatedButton` primário; "Encerrar lote" como `OutlinedButton` vermelho/cinza
- [x] 4.4 Botões sem largura total em desktop

## 5. Telas Admin e cadastro de produto

- [x] 5.1 Aplicar `DesktopFormLayout` em `admin_screen.dart`
- [x] 5.2 Aplicar `DesktopFormLayout` em `product_form_screen.dart`
- [x] 5.3 Revisar botões de ação para hierarquia primário/secundário

## 6. Empty states

- [x] 6.1 Substituir empty state em `devices_screen.dart` por `EmptyStateView` com progress
- [x] 6.2 Substituir empty state em `labels_screen.dart` por `EmptyStateView`
- [x] 6.3 Substituir empty state em `products_screen.dart` por `EmptyStateView`

## 7. Validação

- [x] 7.1 `flutter analyze` e `flutter test` passando
- [x] 7.2 Verificação visual manual: janela ≥ 1280 px (Settings, Lote, Dispositivos vazio) e viewport mobile < 900 px
