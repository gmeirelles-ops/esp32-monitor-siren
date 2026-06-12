## ADDED Requirements

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
