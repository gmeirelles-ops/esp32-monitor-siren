# Wi-Fi reprovisionamento sob demanda

## Problema

`idf.py flash` não apaga NVS — dispositivos gravados por cabo mantêm credenciais antigas e não entram no portal. Não havia forma de trocar Wi-Fi sem `erase-flash` ou falha de conexão no boot.

## Solução (firmware 1.4.6+)

- Comando MQTT `RESET_WIFI` (+ `clear_mqtt` opcional)
- Botão físico: segurar 5 s
- Campo `wifi_ssid` no heartbeat

## App Flutter (`sirene_app`)

Adicionar em **Configurações → Dispositivo** (ou `DeviceDetailScreen`):

1. Exibir `wifi_ssid` do heartbeat do dispositivo selecionado
2. Botão **Alterar Wi-Fi** que:
   - Confirma com o operador
   - Publica `{"cmd":"RESET_WIFI"}` via MQTT
   - Mostra wizard: aguardar reboot → conectar PC ao AP `SireneValidator` → abrir `http://192.168.4.1`
3. Alternativa offline: instruções para segurar o botão 5 s

Ver `app-snippets/` neste change para código Dart de referência.
