import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/diponto_theme.dart';
import '../../models/manager_filters.dart';
import '../../services/aggregation_service.dart';
import 'manager_filter_bar.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _service = AggregationService();
  final _serialController = TextEditingController();
  final _opSearchController = TextEditingController();
  final _opFilterController = TextEditingController();
  final _operatorFilterController = TextEditingController();

  ManagerFilters _filters = const ManagerFilters();
  String? _draftStationId;
  List<String> _stationIds = [];
  ProductionAggregate? _data;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchByOp = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _serialController.dispose();
    _opSearchController.dispose();
    _opFilterController.dispose();
    _operatorFilterController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _stationIds = await _service.listStationIds();
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchAggregate(_filters);
      if (mounted) {
        setState(() {
          _data = data;
          if (_stationIds.isEmpty) {
            _stationIds = data.stations.map((s) => s.stationId).toList()..sort();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filters = ManagerFilters(
        period: _filters.period,
        stationId: _draftStationId,
        opFilter: _opFilterController.text.trim().isEmpty ? null : _opFilterController.text.trim(),
        operatorFilter: _operatorFilterController.text.trim().isEmpty
            ? null
            : _operatorFilterController.text.trim(),
      );
    });
    _load();
  }

  void _clearFilters() {
    _opFilterController.clear();
    _operatorFilterController.clear();
    setState(() {
      _draftStationId = null;
      _filters = ManagerFilters(period: _filters.period);
    });
    _load();
  }

  void _onPeriodChanged(String period) {
    setState(() => _filters = _filters.copyWith(period: period));
    _load();
  }

  Future<void> _runSearch() async {
    if (_searchByOp) {
      final rows = await _service.searchByOp(_opSearchController.text);
      setState(() => _searchResults = rows);
    } else {
      final rows = await _service.searchSerials(_serialController.text);
      setState(() => _searchResults = rows);
    }
  }

  Future<void> _exportCsv() async {
    final data = _data;
    if (data == null) return;
    final buf = StringBuffer()
      ..writeln('Painel fábrica Diponto')
      ..writeln('Período;${_filters.period}')
      ..writeln('Posto;${_filters.stationId ?? "todos"}')
      ..writeln('OP;${_filters.opFilter ?? "—"}')
      ..writeln('Operador;${_filters.operatorFilter ?? "—"}')
      ..writeln('Testado;${data.total}')
      ..writeln('Aprovados;${data.aprovados}')
      ..writeln('Reprovados;${data.reprovados}')
      ..writeln('Rendimento %;${data.yieldPct.toStringAsFixed(1)}')
      ..writeln()
      ..writeln('Por posto')
      ..writeln('station_id;total;aprovados;rendimento_%');
    for (final e in data.byStationStats.entries) {
      buf.writeln(
        '${e.key};${e.value.total};${e.value.aprovados};${e.value.yieldPct.toStringAsFixed(1)}',
      );
    }
    buf.writeln();
    buf.writeln('Por OP');
    buf.writeln('numero_op;total;aprovados;rendimento_%');
    for (final e in data.byOpDetail.entries) {
      buf.writeln(
        '${e.key};${e.value.total};${e.value.aprovados};${e.value.yieldPct.toStringAsFixed(1)}',
      );
    }

    final file = await _saveReport('fabrica_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv', buf.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV salvo: ${file.path}')));
  }

  Future<File> _saveReport(String name, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final reports = Directory(p.join(dir.path, 'relatorios_gestor'));
    if (!await reports.exists()) await reports.create(recursive: true);
    final file = File(p.join(reports.path, name));
    await file.writeAsString(content);
    return file;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('failed-precondition') && msg.contains('index')) {
      return 'Índice Firestore em criação ou ausente.\n\n'
          'Aguarde alguns minutos após deploy dos índices e toque em Atualizar.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da fábrica'),
        actions: [
          IconButton(tooltip: 'Exportar CSV', onPressed: _data == null ? null : _exportCsv, icon: const Icon(Icons.download_outlined)),
          IconButton(tooltip: 'Atualizar', onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Sair', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ManagerFilterBar(
                        filters: _filters,
                        stationIds: _stationIds,
                        stationId: _draftStationId,
                        opController: _opFilterController,
                        operatorController: _operatorFilterController,
                        onStationChanged: (v) => setState(() => _draftStationId = v),
                        onApply: _applyFilters,
                        onClear: _clearFilters,
                        onPeriodChanged: _onPeriodChanged,
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_data != null && !_loading) ...[
                        _KpiRow(data: _data!),
                        const SizedBox(height: 16),
                        if (_data!.byDay.isNotEmpty) _DailyChart(byDay: _data!.byDay),
                        const SizedBox(height: 16),
                        _StationHealthCard(stations: _data!.stations),
                        const SizedBox(height: 16),
                        _StationRankingCard(stats: _data!.byStationStats),
                        const SizedBox(height: 16),
                        _OpTable(ops: _data!.byOpDetail),
                        if (_data!.byOperator.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _OperatorRanking(byOperator: _data!.byOperator),
                        ],
                      ],
                      const SizedBox(height: 24),
                      _LookupSection(
                        searchByOp: _searchByOp,
                        serialController: _serialController,
                        opController: _opSearchController,
                        onModeChanged: (v) => setState(() => _searchByOp = v),
                        onSearch: _runSearch,
                        results: _searchResults,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});
  final ProductionAggregate data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Kpi('Testado', '${data.total}', Icons.science_outlined),
        _Kpi('Aprovados', '${data.aprovados}', Icons.check_circle_outline, DipontoColors.success),
        _Kpi('Reprovados', '${data.reprovados}', Icons.cancel_outlined, DipontoColors.error),
        _Kpi('Rendimento', '${data.yieldPct.toStringAsFixed(1)}%', Icons.percent),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.icon, [this.color]);
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DipontoColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DipontoColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? DipontoColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: const TextStyle(color: DipontoColors.primaryLight, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.byDay});
  final Map<String, int> byDay;

  @override
  Widget build(BuildContext context) {
    final entries = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final max = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final fmt = DateFormat('dd/MM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produção por dia', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(fmt.format(DateTime.parse(e.key)), style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : e.value / max,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: DipontoColors.surface,
                        color: DipontoColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 36, child: Text('${e.value}', textAlign: TextAlign.end)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StationHealthCard extends StatelessWidget {
  const _StationHealthCard({required this.stations});
  final List<StationHealth> stations;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum posto registrado em stations/ ainda.'),
        ),
      );
    }
    final stale = stations.where((s) => s.stale).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Saúde dos postos', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (stale > 0)
                  Chip(
                    label: Text('$stale sem sync recente'),
                    backgroundColor: DipontoColors.error.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in stations)
              ListTile(
                dense: true,
                leading: Icon(
                  s.stale ? Icons.cloud_off : Icons.cloud_done,
                  color: s.stale ? DipontoColors.error : DipontoColors.success,
                ),
                title: Text(s.stationId),
                subtitle: Text(
                  'Último sync: ${s.lastSyncAt != null ? DateFormat('dd/MM HH:mm').format(s.lastSyncAt!.toLocal()) : '—'} · '
                  'pend. ${s.pendingQueue} · falhas ${s.failedQueue}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StationRankingCard extends StatelessWidget {
  const _StationRankingCard({required this.stats});
  final Map<String, StationStats> stats;

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ranking por posto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final e in entries)
              ListTile(
                dense: true,
                title: Text(e.key),
                subtitle: Text('${e.value.aprovados} aprov. de ${e.value.total} testes'),
                trailing: Text(
                  '${e.value.yieldPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: e.value.yieldPct >= 70 ? DipontoColors.success : DipontoColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpTable extends StatelessWidget {
  const _OpTable({required this.ops});
  final Map<String, OpStats> ops;

  @override
  Widget build(BuildContext context) {
    final entries = ops.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lotes / OP', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Ordenado por volume no período filtrado', style: TextStyle(fontSize: 12, color: DipontoColors.primaryLight)),
            for (final e in entries.take(25))
              ListTile(
                dense: true,
                title: Text('OP ${e.key}'),
                subtitle: Text(
                  '${e.value.total} testes · ${e.value.aprovados} aprov.'
                  '${e.value.stationId != null ? ' · posto ${e.value.stationId}' : ''}',
                ),
                trailing: Text('${e.value.yieldPct.toStringAsFixed(0)}%'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OperatorRanking extends StatelessWidget {
  const _OperatorRanking({required this.byOperator});
  final Map<String, int> byOperator;

  @override
  Widget build(BuildContext context) {
    final entries = byOperator.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produtividade por operador', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in entries.take(15))
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: DipontoColors.surfaceVariant,
                  child: Text('${entries.indexOf(e) + 1}', style: const TextStyle(fontSize: 12)),
                ),
                title: Text(e.key),
                trailing: Text('${e.value} aprov.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LookupSection extends StatelessWidget {
  const _LookupSection({
    required this.searchByOp,
    required this.serialController,
    required this.opController,
    required this.onModeChanged,
    required this.onSearch,
    required this.results,
  });

  final bool searchByOp;
  final TextEditingController serialController;
  final TextEditingController opController;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSearch;
  final List<Map<String, dynamic>> results;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Consulta global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Serial')),
                ButtonSegment(value: true, label: Text('OP')),
              ],
              selected: {searchByOp},
              onSelectionChanged: (s) => onModeChanged(s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchByOp ? opController : serialController,
                    decoration: InputDecoration(
                      labelText: searchByOp ? 'Número da OP' : 'Serial (mín. 3 caracteres)',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onSearch, child: const Text('Buscar')),
              ],
            ),
            for (final row in results)
              ListTile(
                leading: Icon(
                  row['_tipo'] == 'reprovado' ? Icons.cancel : Icons.check_circle,
                  color: row['_tipo'] == 'reprovado' ? DipontoColors.error : DipontoColors.success,
                ),
                title: Text(row['serial']?.toString() ?? 'Reprovado #${row['sequencial'] ?? '—'}'),
                subtitle: Text(
                  'Posto ${row['station_id'] ?? '—'} · OP ${row['numero_op'] ?? '—'}'
                  '${row['operador'] != null ? ' · ${row['operador']}' : ''}'
                  '${row['timestamp'] is Timestamp ? ' · ${dateFmt.format((row['timestamp'] as Timestamp).toDate().toLocal())}' : ''}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
