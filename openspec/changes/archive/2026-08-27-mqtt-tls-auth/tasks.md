## 1. Firmware NVS e cliente

- [ ] 1.1 Estender `mqtt_cfg` na NVS (tls, user, pass, ca)
- [ ] 1.2 Conectar via `mqtts://` em `mqtt_bridge`
- [ ] 1.3 Portal Wi-Fi: campos MQTT TLS (HTML/form)

## 2. App Flutter

- [ ] 2.1 Configurações: TLS, CA, user/pass
- [ ] 2.2 `mqtt_service.dart`: SecurityContext e reconexão

## 3. Infra Mosquitto

- [ ] 3.1 Exemplo `mosquitto.conf` com listener 8883 e ACL
- [ ] 3.2 Script ou doc para gerar CA de fábrica

## 4. Testes e docs

- [ ] 4.1 Host test ou teste manual documentado de URI mqtts
- [ ] 4.2 Atualizar `docs/PRODUCAO.md` com migração TLS

## 5. Verificação

- [ ] 5.1 Smoke: dispositivo + app em broker TLS staging
- [ ] 5.2 Confirmar testes locais sem broker ainda funcionam
