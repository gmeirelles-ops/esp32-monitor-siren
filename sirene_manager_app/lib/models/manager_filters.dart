/// Filtros do painel supervisor.
class ManagerFilters {
  const ManagerFilters({
    this.period = 'week',
    this.stationId,
    this.opFilter,
    this.operatorFilter,
  });

  final String period;
  final String? stationId;
  final String? opFilter;
  final String? operatorFilter;

  static const periodLabels = {
    'today': 'Hoje',
    'week': '7 dias',
    'all': '30 dias',
  };

  bool get hasActiveFilters =>
      (stationId != null && stationId!.isNotEmpty) ||
      (opFilter != null && opFilter!.trim().isNotEmpty) ||
      (operatorFilter != null && operatorFilter!.trim().isNotEmpty);

  ManagerFilters copyWith({
    String? period,
    String? stationId,
    String? opFilter,
    String? operatorFilter,
    bool clearStation = false,
    bool clearOp = false,
    bool clearOperator = false,
  }) {
    return ManagerFilters(
      period: period ?? this.period,
      stationId: clearStation ? null : (stationId ?? this.stationId),
      opFilter: clearOp ? null : (opFilter ?? this.opFilter),
      operatorFilter: clearOperator ? null : (operatorFilter ?? this.operatorFilter),
    );
  }

  ManagerFilters cleared() => const ManagerFilters();
}
