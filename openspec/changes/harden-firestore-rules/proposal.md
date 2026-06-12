## Why

As regras Firestore atuais permitem que qualquer usuário autenticado leia e escreva todas as coleções (`devices`, `test_results`, `batches`, `products`). Um operador poderia apagar histórico de testes ou sobrescrever catálogo de outro posto. Com sync habilitado em produção, isso é risco real de integridade e rastreabilidade.

## What Changes

- Regras por coleção com papéis via custom claims (`operator`, `supervisor`, `admin`) ou, na v1, restrições sem roles: `test_results` imutável após create, `products` só update com `updated_by_station`, leitura ampla para autenticados.
- Validação de campos obrigatórios em writes (`station_id`, `numero_op`, `sequencial`).
- Documentação de criação de usuários e claims no Console Firebase.
- Testes com Firebase Emulator Suite (`scripts/`).

## Capabilities

### New Capabilities

_(nenhuma)_

### Modified Capabilities

- `firebase-setup`: regras de segurança e política de claims
- `firestore-sync`: restrições que o app deve respeitar ao enfileirar (sem delete de `test_results`)

## Impact

- **Firebase**: `firebase/firestore.rules`, possivelmente `firestore.indexes.json`
- **App Flutter**: ajustes se alguma operação atual violar novas regras (ex.: delete)
- **Console**: script ou doc para atribuir claims a operadores
