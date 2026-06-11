## Context

O `SireneApp` usa `LayoutBuilder` com breakpoint `900 px`: desktop exibe `NavigationRail` + conteúdo; mobile usa `NavigationBar`. Telas de formulário (`BatchScreen`, `SettingsScreen`, `AdminScreen`, `ProductFormScreen`) usam `ListView`/`Column` com `TextField` e `ElevatedButton` sem limite de largura — em monitores wide os controles ocupam 100% da área útil.

O tema atual (`diponto_theme.dart`) define `surface` `#1A1A1A`, `surfaceVariant` `#2D2D2D`, `Card` com `surfaceVariant`, e `NavigationRail` com `indicatorColor` amber 25%. Empty states são texto simples em `Center`.

## Goals / Non-Goals

**Goals:**

- Formulários desktop legíveis com largura máxima ~600 px, centralizados ou alinhados à esquerda com padding consistente.
- Hierarquia visual clara via cards por domínio (MQTT, impressora, nuvem).
- Menos rolagem vertical em Lote e Configurações via `Row`/`Expanded` em desktop.
- Empty states que comunicam estado ativo (escutando broker) vs. lista vazia estática.
- Navegação lateral com seleção mais evidente.
- Botões primários vs. secundários/destrutivos distinguíveis por estilo, não só por cor de fundo.

**Non-Goals:**

- Painel lateral de logs MQTT em tempo real (mencionado como opção futura; fora deste change).
- Redesign completo de listas de dispositivos/produtos com dados.
- Alteração de fluxos de negócio, providers ou persistência.
- Suporte tablet intermediário com layout dedicado (usa desktop ou mobile pelo breakpoint existente).

## Decisions

### 1. Widget `DesktopFormLayout`

Criar `shared/widgets/desktop_form_layout.dart`:

```dart
class DesktopFormLayout extends StatelessWidget {
  const DesktopFormLayout({
    required this.child,
    this.maxWidth = 600,
    this.padding = const EdgeInsets.all(24),
  });
  // Center > ConstrainedBox(maxWidth) > padding > child
}
```

Usar em `BatchScreen`, `SettingsScreen`, `AdminScreen`, `ProductFormScreen` quando `constraints.maxWidth >= 900` (passar `LayoutBuilder` ou `MediaQuery`). Em mobile, renderizar `child` direto com padding padrão.

**Alternativa considerada:** `Align(alignment: Alignment.topLeft)` com largura fixa e painel direito reservado — rejeitada por escopo; centralizado é suficiente para v1.

### 2. Widget `FormSectionCard`

```dart
class FormSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  // Card(color: Color(0xFF1E1E1E)) + Padding + title TextStyle bold
}
```

Aplicar em `SettingsScreen` para as três seções. Reutilizável em Admin se houver blocos distintos.

Atualizar `diponto_theme.dart`: adicionar `DipontoColors.cardElevated = Color(0xFF1E1E1E)` e `scaffoldBackgroundColor` opcional `#121212` se contraste com card for insuficiente — manter `#1A1A1A` se cards `#1E1E1E` já destacarem.

### 3. Helper `ResponsiveFieldRow`

Widget leve para linhas de campos:

```dart
ResponsiveFieldRow(
  children: [
    Expanded(flex: 7, child: hostField),
    SizedBox(width: 12),
    Expanded(flex: 3, child: portField),
  ],
)
```

Em mobile (`< 900`): empilhar verticalmente (`Column`). Implementar com `LayoutBuilder` interno ou flag `isDesktop` do pai.

**Lote:** linha com Ano (flex 2), Quantidade (flex 3), Próximo sequencial (flex 3).

### 4. Widget `EmptyStateView`

```dart
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showProgress; // CircularProgressIndicator abaixo do ícone
}
```

- **Dispositivos:** `Icons.router`, `showProgress: true`, subtítulo sobre broker MQTT.
- **Etiquetas:** `Icons.label_outline`, sem progress.
- **Produtos:** `Icons.inventory_2_outlined`, CTA para cadastrar se aplicável.

Ícone com `opacity: 0.35`, tamanho 64–80.

### 5. NavigationRail customizado

Em `app.dart`:

- `minExtendedWidth: 88` (padrão 72) ou envolver rail em `SizedBox(width: 96)`.
- Substituir dependência apenas de `indicatorColor` por destino customizado via `NavigationRailDestination` não suporta fundo por item nativamente — usar `NavigationDrawer` **ou** manter `NavigationRail` com `useIndicator: true`, `indicatorShape: RoundedRectangleBorder(borderRadius: 12)`, `indicatorColor: primary @ 0.15`, aumentar `elevation` do rail.

Material 3 `NavigationRail` já suporta `indicatorShape` e `minWidth`. Ajustar `selectedIconTheme` / padding.

### 6. Hierarquia de botões no tema

Em `diponto_theme.dart`:

- `elevatedButtonTheme`: manter amber para primário.
- Adicionar `outlinedButtonTheme` com borda `onSurface @ 0.5` para secundário neutro.
- Criar estilo local ou `OutlinedButton.styleFrom(foregroundColor: error, side: BorderSide(color: error))` para "Encerrar lote" em `batch_screen.dart` — não globalizar vermelho em todo outlined.

Melhorar `inputDecorationTheme.enabledBorder` com `BorderSide(color: onSurface @ 0.3)` para contraste.

### 7. Botões não full-width

Trocar `SizedBox(width: double.infinity)` ou `width: MediaQuery...` por `Align(alignment: Alignment.centerLeft, child: FilledButton(...))` dentro do `DesktopFormLayout`. Em mobile, botões podem permanecer full-width para área de toque.

## Risks / Trade-offs

- **[Risk] Breakpoint 900 px inconsistente entre telas** → Reutilizar mesma constante `kDesktopBreakpoint` em `core/constants/layout.dart`.
- **[Risk] Cards escurecem demais o tema** → Validar contraste WCAG em labels; ajustar `cardElevated` vs `surfaceVariant`.
- **[Risk] Grid de campos apertado em janelas ~900 px** → `ResponsiveFieldRow` colapsa para coluna abaixo do breakpoint.
- **[Trade-off] Centralizar formulários vs. alinhar à esquerda** → Centralizado reduz implementação; painel MQTT fica para change futuro.

## Migration Plan

1. Adicionar constantes e widgets shared (sem alterar telas).
2. Atualizar tema e `NavigationRail`.
3. Migrar telas uma a uma (Settings → Batch → Admin → forms → empty states).
4. `flutter analyze` + `flutter test`; validação visual manual em janela ≥ 1280 px e mobile.

Rollback: revert commit — apenas UI, sem migração de dados.

## Open Questions

- Scaffold background `#121212` vs manter `#1A1A1A` — decidir na implementação após mock visual.
- `ProductFormScreen` em mobile durante calibração: manter layout vertical completo (confirmado como non-goal alterar fluxo).
