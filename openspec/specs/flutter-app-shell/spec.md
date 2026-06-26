# flutter-app-shell Specification

## Purpose
Shell do app Flutter companion: navegação principal, AppBar global, Configurações de infraestrutura e indicadores de conexão MQTT.
## Requirements
### Requirement: Tema visual Diponto amber
O app Flutter SHALL aplicar uma paleta de cores amber como identidade visual primária, alinhada à marca Diponto, com fundo escuro para uso em ambiente industrial.

#### Scenario: Cores primárias aplicadas
- **WHEN** o app é iniciado
- **THEN** o tema Material 3 utiliza amber (`#FFB300`) como cor primária, amber escuro (`#FF8F00`) como secundária e fundo escuro (`#1A1A1A`) como surface

#### Scenario: Componentes seguem o tema
- **WHEN** o operador navega entre telas
- **THEN** AppBar, botões primários, FAB e indicadores ativos exibem a cor amber da marca

### Requirement: Navegação principal do app
O app SHALL oferecer navegação entre as seções: Lote, Painel, Relatório, Etiquetas (ou Gravação em modo laser), Cadastros e Configurações, acessível somente após autenticação do operador na tela de login.

#### Scenario: Acesso às seções após login
- **WHEN** o operador autenticado abre o app
- **THEN** uma barra de navegação permite alternar entre Lote, Painel, Relatório, Etiquetas/Gravação, Cadastros e Configurações

#### Scenario: Shell bloqueado sem login
- **WHEN** não há operador autenticado
- **THEN** o shell principal e sua navegação não são acessíveis

### Requirement: Configuração global do broker MQTT
O app SHALL permitir configurar e persistir o endereço do broker MQTT (host e porta) nas Configurações.

#### Scenario: Broker configurado
- **WHEN** o operador informa host `192.168.1.100` e porta `1883` e salva
- **THEN** o app persiste a configuração e utiliza esse endereço em todas as conexões MQTT subsequentes

#### Scenario: Broker padrão na primeira execução
- **WHEN** o app é executado pela primeira vez sem configuração prévia
- **THEN** o app exibe o valor padrão `mqtt://192.168.1.100:1883` (alinhado ao firmware) e solicita confirmação do operador

### Requirement: Logo e identidade Diponto
O app SHALL exibir o logo Diponto na AppBar e utilizar tipografia legível para ambiente de fábrica.

#### Scenario: Logo visível
- **WHEN** o operador está em qualquer tela principal
- **THEN** o logo Diponto é exibido na AppBar

### Requirement: Seção de nuvem nas Configurações
O app SHALL incluir nas Configurações uma seção "Nuvem" com: toggle de sincronização Firestore, campo `station_id`, status da fila de sync, listagem de dead-letter com retry e botão de logout (quando autenticado).

#### Scenario: Operador configura posto
- **WHEN** o operador define `station_id` e salva nas Configurações
- **THEN** o valor é persistido em SharedPreferences e usado em gravações Firestore subsequentes

#### Scenario: Status da fila visível
- **WHEN** existem itens pendentes ou com falha na fila de sync
- **THEN** a seção Nuvem exibe contagem de pendências e falhas permanentes

#### Scenario: Dead-letter listado
- **WHEN** existem entradas com falha permanente na fila
- **THEN** a seção Nuvem lista cada falha com erro e oferece ação de retry

### Requirement: Fluxo de login integrado à navegação
O app SHALL manter login Firebase opcional nas Configurações → Nuvem para sincronização, independente do login de operador local obrigatório na entrada.

#### Scenario: Uso local após login de operador
- **WHEN** o operador autenticado utiliza Lote, Painel e Etiquetas sem sessão Firebase
- **THEN** todas as funcionalidades locais (MQTT, SQLite, etiquetas) permanecem acessíveis

#### Scenario: Login Firebase para nuvem
- **WHEN** o operador tenta habilitar sincronização sem sessão Firebase
- **THEN** o app navega para a tela de login Firebase antes de ativar o toggle

### Requirement: Toggle de sync desabilitado por padrão
Em instalação nova, o toggle de sincronização Firestore SHALL iniciar desabilitado até que o operador autenticado o habilite explicitamente.

#### Scenario: Primeira execução após instalação
- **WHEN** o app é aberto pela primeira vez com Firebase configurado
- **THEN** a sincronização em nuvem está desligada e nenhum dado é enviado ao Firestore

### Requirement: Indicador visual destacado no NavigationRail
Em layout desktop (≥ 900 px), o item selecionado no `NavigationRail` SHALL exibir fundo destacado com cor primária amber em aproximadamente 10–20% de opacidade, bordas arredondadas e ícone na cor primária.

#### Scenario: Navegação entre seções
- **WHEN** o operador seleciona "Lote" no menu lateral
- **THEN** o destino Lote exibe fundo amber translúcido arredondado além da mudança de cor do ícone e do rótulo

#### Scenario: Largura confortável do menu
- **WHEN** o app é exibido em desktop
- **THEN** o `NavigationRail` utiliza largura mínima maior que o padrão compacto (≥ 88 px) para rótulos e ícones sem aparência espremida

### Requirement: Hierarquia de botões primário e secundário
O tema SHALL reservar `ElevatedButton` / `FilledButton` com cor amber Diponto para ações primárias de fluxo (ex.: "Configurar lote", "Salvar", "Cadastrar"). Ações secundárias ou destrutivas (ex.: "Encerrar lote", "Cancelar") SHALL usar `OutlinedButton` com contorno vermelho ou cinza, sem preenchimento amber.

#### Scenario: Configurar lote vs encerrar lote
- **WHEN** o operador visualiza a tela de Lote com lote ativo
- **THEN** "Configurar lote" aparece como botão preenchido amber e "Encerrar lote" como botão outlined vermelho ou cinza

#### Scenario: Ação primária em Configurações
- **WHEN** o operador salva configurações
- **THEN** o botão Salvar utiliza estilo primário amber do tema

### Requirement: Contraste melhorado de campos de texto
O `InputDecorationTheme` SHALL definir borda visível no estado habilitado (não focado), com contraste adequado sobre fundo escuro, além da borda amber no estado focado.

#### Scenario: Campo sem foco
- **WHEN** um `TextField` está habilitado mas não focado em tema escuro
- **THEN** o contorno do campo permanece visível contra o fundo do formulário

### Requirement: Pipeline MQTT ativo desde a inicialização
O app SHALL inicializar a conexão MQTT e o registro de mensagens na inicialização do aplicativo, independentemente da tela exibida primeiro.

#### Scenario: App aberto direto no Painel
- **WHEN** o app é iniciado e o operador permanece em uma tela que não observa dispositivos (ex.: Painel, Produtos)
- **THEN** heartbeats, presença e resultados de teste recebidos via MQTT são registrados normalmente

#### Scenario: Resultado de teste com app recém-aberto
- **WHEN** um dispositivo publica um resultado de teste logo após o app iniciar
- **THEN** o resultado é persistido e a etiqueta gerada sem exigir visita prévia à tela de Dispositivos ou Lote

### Requirement: Indicador de conexão MQTT global
O app SHALL exibir o indicador de status da conexão MQTT (`ConnectionStatusBadge`) na AppBar de todas as telas principais, não apenas na tela de Dispositivos.

#### Scenario: Badge visível fora de Dispositivos
- **WHEN** o operador está na tela de Lote, Painel, Etiquetas ou Configurações
- **THEN** o badge de conexão MQTT permanece visível na AppBar

#### Scenario: Queda de conexão refletida globalmente
- **WHEN** a conexão com o broker MQTT é perdida
- **THEN** o badge reflete o estado desconectado em qualquer tela principal

### Requirement: Limpeza de sessão de operador ao encerrar o app
O app SHALL limpar a sessão de operador em memória quando o processo for encerrado. Na próxima abertura, o operador SHALL autenticar-se novamente na tela de login.

#### Scenario: Fechar janela no desktop
- **WHEN** o operador fecha a janela principal do app no Windows/Linux/macOS
- **THEN** a sessão de operador em memória é descartada

#### Scenario: Próxima abertura exige login
- **WHEN** o app é iniciado após encerramento completo do processo anterior
- **THEN** a tela de login é exibida e nenhum operador permanece autenticado

### Requirement: Gate de setup de bancada após login
O app SHALL verificar se a bancada do posto está configurada após autenticação do operador e SHALL impedir acesso ao shell principal até concluir o setup quando necessário.

#### Scenario: Posto sem bancada configurada
- **WHEN** o operador autentica-se e `bancada_setup_complete` é falso
- **THEN** o app exibe `PostoSetupScreen` em vez do shell principal

#### Scenario: Posto com bancada já vinculada
- **WHEN** o operador autentica-se e `bancada_setup_complete` é verdadeiro
- **THEN** o app navega diretamente ao shell principal

#### Scenario: Migração de instalações existentes
- **WHEN** o app atualiza em posto que já possui `selected_device_id` persistido
- **THEN** `bancada_setup_complete` é definido como verdadeiro automaticamente na primeira execução pós-atualização

### Requirement: Seção Manutenção do posto em Configurações
O app SHALL incluir seção "Manutenção do posto" em Configurações com vínculo de bancada, atalho de provisionamento Wi-Fi e reset geral.

#### Scenario: Alterar bancada em Configurações
- **WHEN** o supervisor acessa Configurações → Manutenção do posto → Bancada
- **THEN** pode selecionar outro dispositivo detectado e salvar o novo vínculo

#### Scenario: Reset geral acessível
- **WHEN** o supervisor abre Configurações → Manutenção do posto
- **THEN** o botão "Reset geral do posto" está visível com estilo destrutivo

