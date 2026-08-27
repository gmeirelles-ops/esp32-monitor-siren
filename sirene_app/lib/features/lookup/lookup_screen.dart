import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/action_section_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../../shared/widgets/screen_page_layout.dart';
import '../../shared/widgets/section_intro.dart';
import '../labels/remark_serial.dart';
import '../operators/operators_provider.dart';

final lookupQueryProvider = StateProvider<String>((ref) => '');

final lookupResultsProvider = FutureProvider<List<TestResult>>((ref) async {
  final q = ref.watch(lookupQueryProvider).trim();
  if (q.length < 2) return [];
  final db = ref.watch(databaseProvider);
  if (RegExp(r'^\d+$').hasMatch(q) && q.length <= 6) {
    final rows = await db.testsForOp(q);
    return rows.reversed.toList();
  }
  return db.searchSerials(q, limit: 50);
});

class LookupScreen extends ConsumerStatefulWidget {
  const LookupScreen({super.key});

  @override
  ConsumerState<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends ConsumerState<LookupScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    ref.read(lookupQueryProvider.notifier).state = value.trim();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isGestor = ref.watch(activeOperatorIsGestorProvider);
    if (!isGestor) {
      return Scaffold(
        appBar: screenAppBar(context, title: 'Consulta'),
        body: const Center(child: Text('Acesso restrito a gestores.')),
      );
    }

    final resultsAsync = ref.watch(lookupResultsProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final query = _controller.text.trim();

    return Scaffold(
      appBar: screenAppBar(context, title: 'Consulta'),
      body: ScreenPageLayout(
        intro: const SectionIntro(
          title: 'Consulta de rastreabilidade',
          subtitle: 'Busque por serial ou número da OP para localizar testes e regravar no laser.',
          icon: Icons.search,
        ),
        children: [
          ActionSectionCard(
            icon: Icons.manage_search,
            title: 'Buscar',
            subtitle: 'Mínimo de 2 caracteres',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Serial ou número da OP',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _search(_controller.text),
                    ),
                  ),
                  onSubmitted: _search,
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite parte do serial ou o número da OP.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DipontoColors.primaryLight,
                      ),
                ),
              ],
            ),
          ),
          resultsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => ActionSectionCard(
              icon: Icons.error_outline,
              title: 'Erro na busca',
              accentColor: DipontoColors.error,
              child: Text('Erro: $e'),
            ),
            data: (rows) {
              if (query.length < 2) {
                return ActionSectionCard(
                  icon: Icons.info_outline,
                  title: 'Resultados',
                  child: Text(
                    'Informe um serial ou OP para buscar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              if (rows.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.search_off,
                  title: 'Nenhum resultado',
                  subtitle: 'Não encontramos testes para essa busca.',
                  showProgress: false,
                );
              }
              return ActionSectionCard(
                icon: Icons.list_alt,
                title: 'Resultados (${rows.length})',
                subtitle: query.length <= 6 && RegExp(r'^\d+$').hasMatch(query)
                    ? 'Testes da OP $query'
                    : 'Seriais correspondentes',
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          rows[i].serial ?? '—',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          'OP ${rows[i].numeroOp} · ${rows[i].veredito} · '
                          '${rows[i].operador ?? '—'} · ${dateFmt.format(rows[i].createdAt.toLocal())}',
                        ),
                        trailing: rows[i].serial != null
                            ? IconButton(
                                tooltip: 'Regravar',
                                icon: const Icon(Icons.precision_manufacturing_outlined),
                                onPressed: () => remarkSerialIfConfirmed(
                                  context: context,
                                  ref: ref,
                                  serial: rows[i].serial!,
                                  numeroOp: rows[i].numeroOp,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
