# Componente PZEM-004T V3

Implementação Modbus RTU de referência. Para usar uma biblioteca de terceiros:

1. Substitua `pzem004t.c` / `pzem004t.h` pela API da biblioteca clonada (mantendo os mesmos símbolos `pzem004t_init` e `pzem004t_read_active_power_w`), **ou**
2. Ajuste apenas `main/src/pzem_sensor.c` para incluir o header da nova lib.

O wrapper em `main/src/pzem_sensor.c` não precisa mudar se a API pública do componente for preservada.
