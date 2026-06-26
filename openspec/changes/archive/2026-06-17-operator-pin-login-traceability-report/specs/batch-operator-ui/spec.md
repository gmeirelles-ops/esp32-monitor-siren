## ADDED Requirements

### Requirement: Operador do lote definido pela sessão de login
O fluxo de lote SHALL utilizar o operador autenticado na sessão de login como operador ativo, sem exigir seleção manual adicional antes de configurar o lote.

#### Scenario: Início de lote com sessão ativa
- **WHEN** o operador autenticado abre a tela de Lote
- **THEN** o operador ativo já está definido conforme a sessão e o formulário de lote pode ser preenchido

#### Scenario: Troca de operador durante o turno
- **WHEN** o operador aciona troca de operador nas Configurações
- **THEN** a sessão é encerrada, o lote em andamento permanece no dispositivo, e novo operador deve autenticar-se na login
