import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';

class SimpleBarChartBar {
  const SimpleBarChartBar({
    required this.label,
    required this.value,
    this.color,
    this.stackedValue,
  });

  final String label;
  final double value;
  final Color? color;
  /// Parcela empilhada dentro de [value] (ex.: aprovados dentro do total).
  final double? stackedValue;
}

/// Gráfico de barras leve, sem dependência externa.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    required this.bars,
    this.defaultColor = DipontoColors.primary,
    this.stackedColor,
    this.height = 160,
    this.showLegend = false,
    this.legendTotalLabel = 'Total',
    this.legendStackedLabel = 'Aprovados',
    this.valueFormatter,
    super.key,
  });

  final List<SimpleBarChartBar> bars;
  final Color defaultColor;
  final Color? stackedColor;
  final double height;
  final bool showLegend;
  final String legendTotalLabel;
  final String legendStackedLabel;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Sem dados para exibir')),
      );
    }

    final maxValue = bars.fold<double>(1, (m, b) => b.value > m ? b.value : m);
    final innerColor = stackedColor ?? DipontoColors.success;
    final format = valueFormatter ?? (v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 16,
              children: [
                _LegendDot(
                  color: defaultColor.withValues(alpha: 0.35),
                  label: legendTotalLabel,
                ),
                _LegendDot(color: innerColor, label: legendStackedLabel),
              ],
            ),
          ),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          format(bar.value),
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: (bar.value / maxValue).clamp(0.02, 1.0),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: (bar.color ?? defaultColor).withValues(alpha: 0.35),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  if (bar.stackedValue != null && bar.value > 0)
                                    FractionallySizedBox(
                                      heightFactor:
                                          (bar.stackedValue! / bar.value).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: innerColor,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bar.label,
                          style: const TextStyle(fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
