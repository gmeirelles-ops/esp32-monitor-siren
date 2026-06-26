# Gestor Firestore

O app `sirene_manager_app` lê `test_results/{op}/seriais` e `reprovadas` via **collection group** filtrado por `timestamp`.

## Setup rápido (Windows)

Você já deve estar na pasta do app gestor (não rode `cd sirene_manager_app` de novo se o prompt já mostra `...\sirene_manager_app>`):

```powershell
# Na raiz do repo:
cd esp32-monitor-siren\sirene_manager_app

flutter pub get
flutter run -d windows
```

### Não precisa de `flutterfire configure` se...

O arquivo `lib/firebase_options.dart` **já existe** (cópia do mesmo projeto do `sirene_app`, `monitor-sirenv2-6d201`). Use o app direto com `flutter run`.

Só rode `flutterfire configure` se for **criar outro app** no Console Firebase ou trocar de projeto.

### Se `flutterfire` / `firebase projects:list` falhar

Isso é problema de **login na CLI**, não do Flutter:

```powershell
npx -y firebase-tools@latest login
npx -y firebase-tools@latest projects:list
```

Se continuar falhando, abra `firebase-debug.log` na pasta atual. Causas comuns: sem login, rede/proxy, conta Google errada.

**Para rodar o app gestor**, a CLI não é obrigatória — basta `firebase_options.dart` + conta de usuário no login do app (e-mail/senha já cadastrado no Firebase Auth).

### Login no app

Use a **mesma conta Firebase** que funciona em Configurações → Nuvem no app operador (ou outra conta com Auth habilitado no projeto).

### Erro `permission-denied` no painel

As queries do gestor usam **collection group** em `seriais` e `reprovadas`. As regras em `firebase/firestore.rules` precisam estar **deployadas** no projeto:

```powershell
# Na raiz do repo (esp32-monitor-siren), não dentro de sirene_manager_app
cd ..
npx -y firebase-tools@latest login
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes --project monitor-sirenv2-6d201
```

Depois reinicie o app gestor e faça login novamente.

## Permissões

v1: qualquer usuário Firebase autenticado com acesso de leitura às regras atuais (`isAuthenticated()`).

Para restringir a gestores:

```bash
# Firebase Admin SDK — atribuir custom claim
admin.auth().setCustomUserClaims(uid, { manager: true });
```

Regra opcional futura em `firestore.rules`:

```
function isManager() {
  return request.auth != null && request.auth.token.manager == true;
}
```

## Índices

Após alterar `firebase/firestore.indexes.json`, deploy:

```bash
firebase deploy --only firestore:indexes
```
