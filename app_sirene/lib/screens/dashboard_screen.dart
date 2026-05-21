import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../theme/app_colors.dart';

/// Dashboard QA – pizza Aprovadas vs Reprovadas (Firestore + cache Hive).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService.instance;

  late Future<({int aprovados, int reprovados})> _contagemFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _contagemFuture = _db.contarAprovacaoReprovacao();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard QA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<({int aprovados, int reprovados})>(
        future: _contagemFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<({int aprovados, int reprovados})> snap,
        ) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final int aprovados = snap.data?.aprovados ?? 0;
          final int reprovados = snap.data?.reprovados ?? 0;
          final int total = aprovados + reprovados;

          if (total == 0) {
            return const Center(
              child: Text('Nenhum teste registrado ainda.'),
            );
          }

          final double taxaAprovacao = (aprovados / total) * 100;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Total de testes: $total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kDipontoNavy,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Taxa de aprovação: ${taxaAprovacao.toStringAsFixed(1)}%',
                  style: TextStyle(color: kDipontoNavy.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: [
                        PieChartSectionData(
                          value: aprovados.toDouble(),
                          title: 'Aprov.\n$aprovados',
                          color: Colors.green.shade600,
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: reprovados.toDouble(),
                          title: 'Reprov.\n$reprovados',
                          color: Colors.red.shade400,
                          radius: 72,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legenda(Colors.green.shade600, 'Aprovadas ($aprovados)'),
                    const SizedBox(width: 24),
                    _legenda(Colors.red.shade400, 'Reprovadas ($reprovados)'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _legenda(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(color: kDipontoNavy)),
      ],
    );
  }
}
