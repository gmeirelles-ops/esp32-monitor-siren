# Integrar tela de login no sirene_app

## Arquivos

Copie `app-snippets/lib/` para `sirene_app/lib/` (mesma estrutura de pastas).

## Provider (Riverpod)

```dart
final cloudAuthServiceProvider = Provider(
  (ref) => CloudAuthService(FirebaseAuth.instance),
);
```

## Rota (go_router)

```dart
GoRoute(
  path: '/configuracoes/nuvem/login',
  builder: (context, state) => LoginScreen(
    authService: ref.read(cloudAuthServiceProvider),
    initialStationId: prefs.getString('station_id'),
    onStationIdSaved: (id) => prefs.setString('station_id', id),
    onSuccess: () => context.go('/configuracoes/nuvem'),
    onSkipOffline: () => context.go('/lote'),
  ),
),
```

## Configurações → Nuvem

Substitua o formulário antigo por `CloudSettingsSection`.

## Tema global (opcional)

No `ThemeData.dark()` do app, alinhe `colorScheme.primary` com `SireneColors.primary` (laranja `#FF8C00`) para consistência com a tela de produtos.

## Comportamento

- **Continuar sem nuvem** — operador vai direto ao Lote; MQTT/local funciona normalmente.
- **Entrar** — exige `station_id` + credenciais Firebase; habilita toggle de sync.
- Erros Firebase exibidos em português.
