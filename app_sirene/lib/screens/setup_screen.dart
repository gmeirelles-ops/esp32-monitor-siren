import 'package:flutter/material.dart';

import '../models/sirene_model.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_icon.dart';
import 'dashboard_screen.dart';
import 'live_test_screen.dart';

/// Configuração do ciclo: operador, lote e modelo de sirene.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _operadorController = TextEditingController();
  final TextEditingController _loteController = TextEditingController();

  List<SireneModel> _modelos = [];
  SireneModel? _modeloSelecionado;
  bool _carregando = true;
  bool _injetandoModelos = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarModelos();
  }

  Future<void> _carregarModelos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final List<SireneModel> lista = await _db.listarModelos();
      if (!mounted) return;
      setState(() {
        _modelos = lista;
        _modeloSelecionado = lista.isNotEmpty ? lista.first : null;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _injetarModelosTeste() async {
    setState(() => _injetandoModelos = true);
    try {
      await _db.injetarModelosTeste();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modelos de teste injetados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      await _carregarModelos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao injetar modelos: $e')),
      );
    } finally {
      if (mounted) setState(() => _injetandoModelos = false);
    }
  }

  void _iniciarTeste() {
    final String operador = _operadorController.text.trim();
    final String lote = _loteController.text.trim();

    if (operador.isEmpty || lote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha operador e lote.')),
      );
      return;
    }
    if (_modeloSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um modelo de sirene.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      '/live-test',
      arguments: LiveTestArgs(
        modelo: _modeloSelecionado!,
        idOperador: operador,
        lote: lote,
      ),
    );
  }

  @override
  void dispose() {
    _operadorController.dispose();
    _loteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração'),
        actions: [
          IconButton(
            icon: _injetandoModelos
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            tooltip: 'Injetar modelos de teste (Firestore)',
            onPressed: _injetandoModelos ? null : _injetarModelosTeste,
          ),
          const SyncStatusIcon(),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro ao carregar modelos: $_erro'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _carregarModelos,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _operadorController,
                        decoration: const InputDecoration(
                          labelText: 'ID do operador',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _loteController,
                        decoration: const InputDecoration(
                          labelText: 'Lote',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SireneModel>(
                        initialValue: _modeloSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Modelo de sirene',
                          border: OutlineInputBorder(),
                        ),
                        items: _modelos
                            .map(
                              (SireneModel m) => DropdownMenuItem<SireneModel>(
                                value: m,
                                child: Text(m.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (SireneModel? value) {
                          setState(() => _modeloSelecionado = value);
                        },
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _iniciarTeste,
                        style: FilledButton.styleFrom(
                          backgroundColor: kDipontoAmber,
                          foregroundColor: kDipontoNavy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar teste ao vivo'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
