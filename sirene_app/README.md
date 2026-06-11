# Diponto Sirene Validator

App Flutter companion do firmware `sirene-validator`. **Uso em produção: Windows desktop** no posto de trabalho.

## Desenvolvimento no Linux

No Linux você pode desenvolver e validar localmente, mas **não é possível gerar o `.exe` do Windows** a partir do Linux — o Flutter não faz cross-compile para Windows.

### O que fazer no Linux

```bash
cd sirene_app
flutter pub get
dart run build_runner build

# Testes e análise (sempre)
flutter analyze
flutter test

# Rodar UI localmente (Linux desktop — comportamento similar ao Windows)
flutter run -d linux
```

O target Linux usa o mesmo layout desktop (`NavigationRail`) e o mesmo fluxo de provisionamento (portal no navegador), então serve bem para testar MQTT, lote, seriais e etiquetas durante o desenvolvimento.

### O que NÃO funciona no Linux

| Ação | Linux | Windows |
|------|-------|---------|
| `flutter build windows` | Não | Sim |
| Gerar `.exe` instalável | Não | Sim |
| Abrir `ms-settings:network-wifi` | Não | Sim |

## Build para Windows (máquina de destino ou CI)

Pré-requisitos no Windows:

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)
- Visual Studio 2022 com workload **"Desktop development with C++"**

```bash
cd sirene_app
flutter pub get
dart run build_runner build
flutter build windows --release
```

Saída:

```
build/windows/x64/runner/Release/
├── sirene_app.exe
├── flutter_windows.dll
└── data/
```

Copie a pasta `Release/` inteira para o PC do posto (não só o `.exe`).

## Configuração no posto (Windows)

1. PC na mesma rede do broker MQTT (padrão `192.168.51.87:1883`)
2. **Configurações** → host/porta do broker e IP da impressora Zebra (`9100`)
3. Provisionamento ESP32: Wi-Fi `SireneValidator` → portal `http://192.168.4.1` no navegador
4. **Produtos** → cadastre cada SKU com autocalibração (peça padrão na bancada, tolerância 10%)
5. **Lote** → selecione produto cadastrado (limites preenchidos automaticamente)

Checklist completo: [docs/PRODUCAO.md](../docs/PRODUCAO.md)

## CI opcional (GitHub Actions)

Para gerar o `.exe` automaticamente sem máquina Windows local, use um runner `windows-latest` no pipeline. O código-fonte é o mesmo; só o ambiente de build muda.
