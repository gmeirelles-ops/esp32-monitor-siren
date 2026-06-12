import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/layout.dart';
import '../../core/theme/diponto_theme.dart';
import '../../shared/widgets/screen_app_bar.dart';
import '../operators/operator_form_screen.dart';
import '../products/product_form_screen.dart';
import '../products/products_tab.dart';
import '../operators/operators_tab.dart';

class CadastrosScreen extends ConsumerStatefulWidget {
  const CadastrosScreen({super.key});

  @override
  ConsumerState<CadastrosScreen> createState() => _CadastrosScreenState();
}

class _CadastrosScreenState extends ConsumerState<CadastrosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_tabs.index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const OperatorFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = TabBar(
      controller: _tabs,
      tabs: const [
        Tab(text: 'Produtos', icon: Icon(Icons.inventory_2_outlined)),
        Tab(text: 'Operadores', icon: Icon(Icons.badge_outlined)),
      ],
    );

    final isDesktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    return Scaffold(
      appBar: screenAppBar(
        context,
        title: 'Cadastros',
        bottom: tabs,
        actions: isDesktop
            ? null
            : [
                IconButton(
                  tooltip: 'Novo',
                  onPressed: _onAdd,
                  icon: const Icon(Icons.add),
                ),
              ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          ProductsTab(),
          OperatorsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DipontoColors.primary,
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
