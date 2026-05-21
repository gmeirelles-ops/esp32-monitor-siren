import 'package:flutter/material.dart';

import '../models/sirene_model.dart';
import '../models/teste_result_model.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_icon.dart';
import '../utils/scale_utils.dart';
import '../utils/teste_validator.dart';

/// Argumentos de navegação para [LiveTestScreen].
class LiveTestArgs {
  const LiveTestArgs({
    required this.modelo,
    required this.idOperador,
    required this.lote,
  });

  final SireneModel modelo;
  final String idOperador;
  final String lote;
}

/// Teste ao vivo via Realtime Database (`/teste_atual`).
class LiveTestScreen extends StatefulWidget {
  const LiveTestScreen({super.key, required this.args});

  final LiveTestArgs args;

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  final DatabaseService _db = DatabaseService.instance;

  bool _aguardandoNovoCiclo = false;
  bool _salvando = false;

  @override
  Widget build(BuildContext context) {
    final SireneModel modelo = widget.args.modelo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste ao vivo'),
        actions: const [SyncStatusIcon()],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.escutarTesteAtual(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final Map<String, dynamic>? dados = snap.data;
          return _buildConteudo(modelo, dados);
        },
      ),
    );
  }

  Widget _buildConteudo(SireneModel modelo, Map<String, dynamic>? dados) {
    final String statusEsp = dados?['status']?.toString() ?? '—';
    final int corrente = _asInt(dados?['corrente_lida']);
    final int potencia = _asInt(dados?['potencia_lida']);

    if (_aguardandoNovoCiclo && statusEsp == 'AGUARDANDO_BOTAO') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _aguardandoNovoCiclo = false);
      });
    }

    final bool cicloConcluido = !_aguardandoNovoCiclo &&
        (statusEsp == 'CONCLUIDO' || statusEsp == 'ERRO_SENSOR');

    final String? statusAvaliado = cicloConcluido
        ? TesteValidator.avaliar(
            modelo: modelo,
            correnteLida: corrente,
            potenciaLida: potencia,
            statusEsp: statusEsp,
          )
        : null;

    final bool aprovado = statusAvaliado != null &&
        TesteValidator.isAprovado(statusAvaliado);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard(
            titulo: modelo.nome,
            subtitulo:
                'Lote: ${widget.args.lote} · Operador: ${widget.args.idOperador}',
          ),
          const SizedBox(height: 16),
          _medicaoCard(
            rotulo: 'Corrente',
            valor: ScaleUtils.formatarAmperes(corrente),
            faixa:
                '${ScaleUtils.formatarAmperes(modelo.correnteMinima)} – ${ScaleUtils.formatarAmperes(modelo.correnteMaxima)}',
            icon: Icons.bolt,
          ),
          const SizedBox(height: 12),
          _medicaoCard(
            rotulo: 'Potência',
            valor: ScaleUtils.formatarWatts(potencia),
            faixa:
                '${ScaleUtils.formatarWatts(modelo.potenciaMinima)} – ${ScaleUtils.formatarWatts(modelo.potenciaMaxima)}',
            icon: Icons.power,
          ),
          const SizedBox(height: 16),
          _statusCard(statusEsp, cicloConcluido, statusAvaliado, aprovado),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cicloConcluido ? () => _refazer() : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refazer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: cicloConcluido &&
                          !_salvando &&
                          statusAvaliado != null
                      ? () => _salvarResultado(
                            statusAvaliado,
                            corrente,
                            potencia,
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kDipontoAmber,
                    foregroundColor: kDipontoNavy,
                  ),
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Salvar Resultado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String titulo, required String subtitulo}) {
    return Card(
      color: kDipontoAmber.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kDipontoNavy,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: TextStyle(color: kDipontoNavy.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicaoCard({
    required String rotulo,
    required String valor,
    required String faixa,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.amber.shade800, size: 32),
        title: Text(rotulo),
        subtitle: Text('Faixa: $faixa'),
        trailing: Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: kDipontoNavy,
              ),
        ),
      ),
    );
  }

  Widget _statusCard(
    String statusEsp,
    bool cicloConcluido,
    String? statusAvaliado,
    bool aprovado,
  ) {
    Color corFundo;
    Color corTexto;
    String mensagem;

    if (!cicloConcluido) {
      corFundo = Colors.blue.shade50;
      corTexto = Colors.blue.shade900;
      mensagem = _aguardandoNovoCiclo
          ? 'Pronto para novo ciclo. Acione o botão na bancada.'
          : 'Aguardando acionamento do botão na bancada…';
    } else if (statusAvaliado == TesteStatus.erroSensor) {
      corFundo = Colors.orange.shade50;
      corTexto = Colors.orange.shade900;
      mensagem = TesteValidator.rotuloStatus(statusAvaliado!);
    } else if (aprovado) {
      corFundo = Colors.green.shade50;
      corTexto = Colors.green.shade900;
      mensagem = TesteValidator.rotuloStatus(statusAvaliado!);
    } else {
      corFundo = Colors.red.shade50;
      corTexto = Colors.red.shade900;
      mensagem = TesteValidator.rotuloStatus(statusAvaliado!);
    }

    return Card(
      color: corFundo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status ESP: $statusEsp',
              style: TextStyle(color: corTexto.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: corTexto,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _refazer() {
    setState(() => _aguardandoNovoCiclo = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pronto para novo ciclo. Acione o botão na bancada.'),
      ),
    );
  }

  Future<void> _salvarResultado(
    String status,
    int corrente,
    int potencia,
  ) async {
    setState(() => _salvando = true);

    final TesteResult result = TesteResult(
      idOperador: widget.args.idOperador,
      idModelo: widget.args.modelo.idModelo,
      lote: widget.args.lote,
      correnteLida: corrente,
      potenciaLida: potencia,
      status: status,
      dataHora: DateTime.now(),
    );

    try {
      await _db.salvarTeste(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultado salvo (ou em fila offline).'),
          backgroundColor: Colors.green,
        ),
      );
      _refazer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }
}
