import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/diponto_theme.dart';

class ProvisioningWizard extends StatefulWidget {
  const ProvisioningWizard({super.key});

  @override
  State<ProvisioningWizard> createState() => _ProvisioningWizardState();
}

class _ProvisioningWizardState extends State<ProvisioningWizard> {
  static const _portalUrl = 'http://192.168.4.1';

  bool _showWebView = false;
  WebViewController? _webController;

  bool get _useEmbeddedWebView => !Platform.isWindows && !Platform.isLinux;

  @override
  void initState() {
    super.initState();
    if (_useEmbeddedWebView) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(_portalUrl));
    }
  }

  Future<void> _openWifiSettings() async {
    final Uri uri;
    if (Platform.isWindows) {
      uri = Uri.parse('ms-settings:network-wifi');
    } else if (Platform.isAndroid) {
      uri = Uri.parse('android.settings.WIFI_SETTINGS');
    } else {
      _showMessage('Abra as configurações de Wi-Fi e conecte-se ao AP SireneValidator');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage('Não foi possível abrir as configurações de Wi-Fi automaticamente');
    }
  }

  Future<void> _openPortalInBrowser() async {
    final uri = Uri.parse(_portalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage('Não foi possível abrir $uri');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(title: const Text('Provisionamento Wi-Fi')),
      body: _showWebView && _webController != null
          ? WebViewWidget(controller: _webController!)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Assistente de provisionamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No Windows, conecte o PC à rede SireneValidator e abra o portal no navegador.',
                    style: TextStyle(color: DipontoColors.primaryLight),
                  ),
                ],
                const SizedBox(height: 16),
                _StepTile(
                  number: 1,
                  title: 'Conecte-se ao Wi-Fi do dispositivo',
                  subtitle: 'Rede: SireneValidator (sem senha)',
                  action: TextButton(
                    onPressed: _openWifiSettings,
                    child: Text(Platform.isWindows ? 'Abrir Wi-Fi (Windows)' : 'Abrir Wi-Fi'),
                  ),
                ),
                const _StepTile(
                  number: 2,
                  title: 'Abra o portal de configuração',
                  subtitle: 'Endereço: http://192.168.4.1',
                ),
                const _StepTile(
                  number: 3,
                  title: 'Selecione a rede da fábrica',
                  subtitle: 'Escolha o SSID e informe a senha Wi-Fi',
                ),
                const _StepTile(
                  number: 4,
                  title: 'Aguarde reinício',
                  subtitle: 'O dispositivo reinicia e conecta à rede configurada',
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: _openPortalInBrowser,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Abrir portal no navegador'),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: () => setState(() => _showWebView = true),
                    child: const Text('Abrir portal embarcado'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openPortalInBrowser,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Abrir no navegador'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final int number;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DipontoColors.primary,
          child: Text(
            '$number',
            style: const TextStyle(color: DipontoColors.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: action,
      ),
    );
  }
}
