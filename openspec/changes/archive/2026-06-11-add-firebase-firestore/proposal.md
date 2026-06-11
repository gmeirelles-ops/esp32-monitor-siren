## Why

O app Flutter (`sirene_app`) já opera a linha de produção via MQTT e persiste resultados localmente em SQLite (Drift), mas os dados ficam presos ao posto — sem visibilidade centralizada, backup em nuvem nem rastreabilidade entre turnos ou estações. A arquitetura do projeto prevê desde a fase 1 que o Firebase Firestore seria a camada de persistência em nuvem (fase 2), com o ESP32 permanecendo exclusivamente em MQTT. Agora que o app companion está maduro (catálogo de produtos, lotes, seriais, etiquetas), é o momento de conectar a nuvem sem comprometer a operação offline da fábrica.

## What Changes

- Configurar projeto Firebase e integrar FlutterFire no `sirene_app` (Windows desktop prioritário, Android secundário).
- Implementar autenticação Firebase (e-mail/senha) para operadores de fábrica, exigida pelas regras de segurança do Firestore.
- Criar camada de sincronização **offline-first**: SQLite continua como fonte de verdade local; Firestore recebe réplica assíncrona quando há conectividade.
- Modelar coleções Firestore conforme esquema já documentado: `devices`, `test_results`, `batches`, `products`.
- Sincronizar automaticamente a partir dos eventos MQTT já processados pelo app (heartbeat → `devices`, teste → `test_results`, SET_BATCH/END_BATCH → `batches`, catálogo → `products`).
- Garantir idempotência de gravações (`numero_op` + `sequencial` como chave de documento em `test_results`).
- Adicionar fila de sincronização pendente no SQLite para reenvio após reconexão.
- Expor configuração e status de sync na tela de Configurações (habilitar/desabilitar, indicador online/offline, último sync).
- Provisionar regras de segurança Firestore, índices compostos necessários e arquivo `firebase.json` na raiz do repositório.
- Documentar setup do projeto Firebase e variáveis de ambiente para deploy.

## Capabilities

### New Capabilities

- `firebase-setup`: Inicialização do SDK Firebase no Flutter (FlutterFire CLI, `firebase_options.dart`, dependências, bootstrap no `main.dart`).
- `firebase-auth`: Login/logout de operadores com e-mail e senha; persistência de sessão; gate de acesso à sincronização.
- `firestore-sync`: Modelo de dados Firestore, serviço de sincronização, fila offline, idempotência e hooks nos fluxos MQTT/SQLite existentes.

### Modified Capabilities

- `device-monitoring`: Adicionar sincronização de heartbeat e presença para coleção `devices/{device_id}`.
- `product-catalog`: Adicionar upload opcional do catálogo local para coleção `products/{id_produto}`.
- `flutter-app-shell`: Adicionar telas/fluxos de login Firebase e configuração de sincronização em nuvem.

## Impact

- **App Flutter** (`sirene_app/`): novas dependências (`firebase_core`, `cloud_firestore`, `firebase_auth`), módulo `lib/features/cloud/`, alterações em `mqtt_providers.dart`, `database.dart` (fila de sync), `app.dart` (auth gate).
- **Repositório**: novo diretório `firebase/` com `firestore.rules`, `firestore.indexes.json`; `firebase.json` na raiz; atualização de `docs/PRODUCAO.md` e `GUIA_COMPLETO.md`.
- **Firmware ESP32**: nenhuma alteração — continua MQTT-only.
- **Infraestrutura**: projeto Firebase (Firestore Standard, região `southamerica-east1` sugerida para colocation com fábrica BR); contas de operador criadas no Console ou via script Admin SDK.
- **Segurança**: credenciais Firebase embutidas via FlutterFire (públicas por design); proteção via Auth + Security Rules, não por ocultação de API keys.
