import 'package:flutter/material.dart';

import '../../core/theme/diponto_theme.dart';
import '../../models/manager_filters.dart';

class ManagerFilterBar extends StatelessWidget {
  const ManagerFilterBar({
    super.key,
    required this.filters,
    required this.stationIds,
    required this.stationId,
    required this.opController,
    required this.operatorController,
    required this.onStationChanged,
    required this.onApply,
    required this.onClear,
    required this.onPeriodChanged,
  });

  final ManagerFilters filters;
  final List<String> stationIds;
  final String? stationId;
  final TextEditingController opController;
  final TextEditingController operatorController;
  final ValueChanged<String?> onStationChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: DipontoColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (filters.hasActiveFilters)
                  TextButton(onPressed: onClear, child: const Text('Limpar')),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final e in ManagerFilters.periodLabels.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {filters.period},
              onSelectionChanged: (s) => onPeriodChanged(s.first),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final stationField = DropdownButtonFormField<String?>(
                  value: stationId != null && stationIds.contains(stationId) ? stationId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Posto',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos os postos')),
                    for (final id in stationIds)
                      DropdownMenuItem<String?>(value: id, child: Text(id)),
                  ],
                  onChanged: onStationChanged,
                );
                final opField = TextField(
                  controller: opController,
                  decoration: const InputDecoration(
                    labelText: 'Número da OP',
                    hintText: 'Ex.: 2026001',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onApply(),
                );
                final operField = TextField(
                  controller: operatorController,
                  decoration: const InputDecoration(
                    labelText: 'Operador',
                    hintText: 'Nome ou código',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onApply(),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stationField),
                      const SizedBox(width: 12),
                      Expanded(child: opField),
                      const SizedBox(width: 12),
                      Expanded(child: operField),
                    ],
                  );
                }
                return Column(
                  children: [
                    stationField,
                    const SizedBox(height: 12),
                    opField,
                    const SizedBox(height: 12),
                    operField,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.search),
              label: const Text('Aplicar filtros'),
            ),
            if (filters.hasActiveFilters) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (filters.stationId != null)
                    Chip(label: Text('Posto: ${filters.stationId}')),
                  if (filters.opFilter != null && filters.opFilter!.isNotEmpty)
                    Chip(label: Text('OP: ${filters.opFilter}')),
                  if (filters.operatorFilter != null && filters.operatorFilter!.isNotEmpty)
                    Chip(label: Text('Operador: ${filters.operatorFilter}')),
                  Chip(
                    label: Text(ManagerFilters.periodLabels[filters.period] ?? filters.period),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
