## 1. Scripts de build

- [x] 1.1 Criar `scripts/build_windows_release.ps1` (pub get, build_runner, flutter build, empacotar `dist/`)
- [x] 1.2 Criar `scripts/build_windows_release.sh` com fail-fast no Linux e mensagem orientativa
- [x] 1.3 Templates `LEIA-ME.txt` e `Iniciar Diponto Sirene Validator.bat` copiados pelo script

## 2. Branding Windows

- [x] 2.1 Ajustar `ProductName` / título em `windows/runner/Runner.rc` para "Diponto Sirene Validator" (se ainda genérico)

## 3. CI

- [x] 3.1 Job `windows-release` em workflow (`workflow_dispatch`) com upload do ZIP como artifact
- [x] 3.2 Documentar no README como baixar artifact do GitHub Actions

## 4. Documentação

- [x] 4.1 Seção "Pendrive / distribuição portátil" em `docs/PRODUCAO.md`
- [x] 4.2 Atualizar `sirene_app/README.md` com script e estrutura do pacote
- [x] 4.3 Adicionar `dist/` ao `.gitignore` (se ainda não ignorado)

## 5. Verificação

- [x] 5.1 Smoke manual: extrair ZIP no Windows, duplo clique no `.bat`, app abre na tela Lote
- [x] 5.2 Confirmar que `app/data/` acompanha o `.exe` (app não quebra por DLL/asset ausente)
