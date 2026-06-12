# openspec-maintenance Specification

## Purpose
TBD - created by archiving change spec-purpose-cleanup. Update Purpose after archive.
## Requirements
### Requirement: Propósito documentado em cada capability
Cada arquivo em `openspec/specs/<capability>/spec.md` SHALL conter seção `## Purpose` com descrição não-placeholder do escopo da capability e do componente principal que implementa (firmware ESP32, app Flutter ou infraestrutura).

#### Scenario: Spec sem TBD
- **WHEN** um desenvolvedor abre qualquer spec listada na change `spec-purpose-cleanup`
- **THEN** a seção Purpose descreve o escopo em linguagem natural sem o texto `TBD`

#### Scenario: CLI OpenSpec com contexto
- **WHEN** o OpenSpec gera instruções para uma nova change que toca uma capability existente
- **THEN** o propósito da capability está disponível para orientar propostas sem leitura integral dos requirements

