import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../mqtt/mqtt_providers.dart';

class OperatorFormScreen extends ConsumerStatefulWidget {
  const OperatorFormScreen({super.key, this.existing});

  final Operator? existing;

  @override
  ConsumerState<OperatorFormScreen> createState() => _OperatorFormScreenState();
}

class _OperatorFormScreenState extends ConsumerState<OperatorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nome;
  late bool _ativo;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codigo = TextEditingController(text: e?.codigo ?? '');
    _nome = TextEditingController(text: e?.nome ?? '');
    _ativo = e?.ativo ?? true;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final codigo = _codigo.text.trim();
    final nome = _nome.text.trim();

    if (await db.operatorCodigoExists(codigo, excludeId: widget.existing?.id)) {
      _showSnack('Código $codigo já cadastrado');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await db.updateOperator(
          id: widget.existing!.id,
          codigo: codigo,
          nome: nome,
          ativo: _ativo,
        );
      } else {
        await db.insertOperator(codigo: codigo, nome: nome, ativo: _ativo);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar operador' : 'Novo operador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codigo,
                decoration: const InputDecoration(labelText: 'Código / matrícula'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                subtitle: const Text('Operadores inativos não aparecem no turno'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
