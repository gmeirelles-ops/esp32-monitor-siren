# Melhoria da tela de login (Nuvem / Firebase)

## Problema

A tela de login atual (Configurações → Nuvem) está funcional mas com UX básica, desalinhada do restante do app (tema escuro + laranja da tela de produtos).

## Solução

Snippets em `app-snippets/` para copiar em `sirene_app/lib/`:

- `LoginScreen` — layout industrial, validação, erros Firebase em PT-BR
- `CloudAuthService` — encapsula `firebase_auth`
- `firebase_auth_errors_pt.dart` — mensagens amigáveis
- Integração com **continuar sem nuvem** (sync opcional, conforme GUIA §16)

## Rotas sugeridas

- `/configuracoes/nuvem` → se não autenticado, exibe `LoginScreen`
- Após login → formulário `station_id` + toggle sync
