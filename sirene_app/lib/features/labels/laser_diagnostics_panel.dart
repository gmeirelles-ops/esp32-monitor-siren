import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'marking_providers.dart';

/// Painel de diagnóstico TCP laser (Configurações).
class LaserDiagnosticsPanel extends ConsumerStatefulWidget {
  const LaserDiagnosticsPanel({super.key});

  @override
  ConsumerState<LaserDiagnosticsPanel> createState() => _LaserDiagnosticsPanelState();
}

class _LaserDiagnosticsPanelState extends ConsumerState<LaserDiagnosticsPanel> {
  bool _simulatingSerial = false;
  bool _simulatingModel = false;
  String? _lastSerialSimulation;
  String? _lastModelSimulation;

  Future<void> _simulateSerial() async {
    setState(() {
      _simulatingSerial = true;
      _lastSerialSimulation = null;
    });
    try {
      final processor = ref.read(markQueueProcessorProvider);
      final response = await processor.simulateDiatuClient();
      if (mounted) {
        setState(() => _lastSerialSimulation = response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastSerialSimulation = 'ERRO: $e');
      }
    } finally {
      if (mounted) setState(() => _simulatingSerial = false);
    }
  }

  Future<void> _simulateModel() async {
    setState(() {
      _simulatingModel = true;
      _lastModelSimulation = null;
    });
    try {
      final processor = ref.read(markQueueProcessorProvider);
      final response = await processor.simulateDiatuModelClient();
      if (mounted) {
        setState(() => _lastModelSimulation = response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastModelSimulation = 'ERRO: $e');
      }
    } finally {
      if (mounted) setState(() => _simulatingModel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final processor = ref.watch(markQueueProcessorProvider);
    final eventLog = ref.watch(laserTcpEventLogProvider);
    final pendingAsync = ref.watch(pendingMarkCountProvider);
    final pending = pendingAsync.valueOrNull ?? 0;
    final timeFmt = DateFormat('HH:mm:ss');

    return ListenableBuilder(
      listenable: eventLog,
      builder: (context, _) {
        final last = eventLog.lastEvent;
        final serverLabel = processor.isServerRunning
            ? 'Ativo na porta ${processor.activePort}'
            : (processor.lastError != null ? 'Erro' : 'Parado');

        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Diagnóstico laser',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _row('Servidor', serverLabel),
                if (processor.lastError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    processor.lastError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                _row('Fila pendente', '$pending serial(is)'),
                if (last != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Última conexão (${timeFmt.format(last.at)})',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    last.summary,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
                if (_lastSerialSimulation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Simulação serial: $_lastSerialSimulation',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
                if (_lastModelSimulation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Simulação modelo: $_lastModelSimulation',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
                if (eventLog.events.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Log (${eventLog.events.length})', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final e in eventLog.events.take(10))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '${timeFmt.format(e.at)} ${e.remote} ${e.summary}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _simulatingSerial ? null : _simulateSerial,
                      icon: _simulatingSerial
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cable_outlined, size: 18),
                      label: const Text('Simular serial'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _simulatingModel ? null : _simulateModel,
                      icon: _simulatingModel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.text_fields_outlined, size: 18),
                      label: const Text('Simular modelo'),
                    ),
                    TextButton(
                      onPressed: eventLog.events.isEmpty ? null : eventLog.clear,
                      child: const Text('Limpar log'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
