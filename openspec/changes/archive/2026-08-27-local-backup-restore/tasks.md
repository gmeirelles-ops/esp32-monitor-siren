## 1. Serviço de backup

- [x] 1.1 Adicionar dep `archive`; criar `BackupService` (export ZIP: sqlite + manifest + prefs)
- [x] 1.2 `BackupService.restore()` — validar manifest/formatVersion/schema; close DB; substituir arquivo; aplicar prefs; invalidar providers
- [x] 1.3 Helpers de snapshot consistente (close/reopen ou checkpoint) reutilizando padrão do factory reset

## 2. UI Configurações → Manutenção

- [x] 2.1 Botões "Fazer backup" / "Restaurar backup" + `file_selector`
- [x] 2.2 Diálogos: sync pendente, digitar `RESTAURAR`, erros de schema/ZIP inválido

## 3. Documentação

- [x] 3.1 Seção em `docs/PRODUCAO.md` (backup semanal + troca de PC)

## 4. Testes

- [x] 4.1 Unit: manifest parse, rejeição schema maior, aceitação schema menor
- [x] 4.2 Unit/integration leve: export cria ZIP com 3 entradas; restore aplica fixture mínima
- [x] 4.3 `flutter test` verde
