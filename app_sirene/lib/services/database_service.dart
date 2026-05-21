import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sirene_model.dart';
import '../models/teste_result_model.dart';
import '../utils/teste_validator.dart';
import 'connectivity_service.dart';

/// Singleton: Realtime Database (teste live) + Firestore (histórico) + Hive (offline).
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  factory DatabaseService() => instance;

  static const String boxHistoricoPendentes = 'historico_pendentes';
  static const String colecaoModelos = 'Modelos_Sirenes';
  static const String colecaoHistorico = 'Historico_Testes';
  static const String noTesteAtual = 'teste_atual';

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseReference get _refTesteAtual => _database.ref(noTesteAtual);

  /// Escuta o nó `/teste_atual` (payload com inteiros brutos do ESP32).
  Stream<Map<String, dynamic>?> escutarTesteAtual() {
    return _refTesteAtual.onValue.map((DatabaseEvent event) {
      final Object? valor = event.snapshot.value;
      if (valor == null) return null;
      if (valor is! Map) return null;
      return Map<String, dynamic>.from(
        valor.map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        ),
      );
    });
  }

  /// Quantidade de testes pendentes no cache Hive.
  int contarPendentes() {
    final Box<dynamic> box = Hive.box<dynamic>(boxHistoricoPendentes);
    return box.length;
  }

  /// Injeta 3 modelos de teste na coleção [colecaoModelos] (Opção 2 – dev).
  Future<void> injetarModelosTeste() async {
    final List<({String id, SireneModel modelo})> modelos = [
      (
        id: 'sirene_rotativa_110v',
        modelo: const SireneModel(
          idModelo: 'sirene_rotativa_110v',
          nome: 'Sirene Rotativa 110V',
          correnteMinima: 150,
          correnteMaxima: 350,
          potenciaMinima: 1500,
          potenciaMaxima: 4000,
        ),
      ),
      (
        id: 'sirene_industrial_220v',
        modelo: const SireneModel(
          idModelo: 'sirene_industrial_220v',
          nome: 'Sirene Industrial 220V',
          correnteMinima: 80,
          correnteMaxima: 200,
          potenciaMinima: 1800,
          potenciaMaxima: 4500,
        ),
      ),
      (
        id: 'sirene_eletronica_max',
        modelo: const SireneModel(
          idModelo: 'sirene_eletronica_max',
          nome: 'Sirene Eletrônica Max',
          correnteMinima: 50,
          correnteMaxima: 120,
          potenciaMinima: 500,
          potenciaMaxima: 1500,
        ),
      ),
    ];

    final WriteBatch batch = _firestore.batch();
    for (final ({String id, SireneModel modelo}) item in modelos) {
      batch.set(
        _firestore.collection(colecaoModelos).doc(item.id),
        item.modelo.toMap(),
      );
    }
    await batch.commit();
  }

  /// Lista modelos de sirene cadastrados no Firestore.
  Future<List<SireneModel>> listarModelos() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection(colecaoModelos)
        .get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id_modelo'] ??= doc.id;
      return SireneModel.fromMap(data);
    }).toList();
  }

  /// Salva no Firestore; em falha (ex.: offline), persiste no Hive.
  Future<void> salvarTeste(TesteResult result) async {
    final bool online = await ConnectivityService.instance.hasConnection;
    if (!online) {
      await _salvarNoCache(result);
      return;
    }

    try {
      await _salvarNoFirestore(result);
    } catch (e, st) {
      debugPrint('salvarTeste Firestore falhou: $e\n$st');
      await _salvarNoCache(result);
    }
  }

  Future<void> _salvarNoFirestore(TesteResult result) async {
    await _firestore.collection(colecaoHistorico).add(_mapFirestore(result));
  }

  Map<String, dynamic> _mapFirestore(TesteResult result) {
    final bool aprovado = TesteValidator.isAprovado(result.status);
    return {
      'data_hora': Timestamp.fromDate(result.dataHora),
      'id_operador': result.idOperador,
      'id_modelo': result.idModelo,
      'lote': result.lote,
      'corrente_lida': result.correnteLida,
      'potencia_lida': result.potenciaLida,
      'status': result.status,
      'resultado': aprovado ? 'Aprovado' : 'Reprovado',
      'motivo_reprovacao': TesteValidator.motivoReprovacao(result.status),
      'is_synced': true,
    };
  }

  Future<void> _salvarNoCache(TesteResult result) async {
    final Box<dynamic> box = Hive.box<dynamic>(boxHistoricoPendentes);
    final Map<String, dynamic> map = result.toMap()
      ..['is_synced'] = false;
    await box.add(map);
  }

  /// Descarrega registros pendentes do Hive para o Firestore.
  Future<int> sincronizarPendentes() async {
    if (!await ConnectivityService.instance.hasConnection) return 0;

    final Box<dynamic> box = Hive.box<dynamic>(boxHistoricoPendentes);
    int sincronizados = 0;

    final List<dynamic> keys = box.keys.toList();
    for (final dynamic key in keys) {
      final dynamic raw = box.get(key);
      if (raw is! Map) continue;

      final Map<String, dynamic> map = Map<String, dynamic>.from(
        raw.map(
          (dynamic k, dynamic v) => MapEntry(k.toString(), v),
        ),
      );
      final TesteResult result = TesteResult.fromMap(map);

      try {
        await _salvarNoFirestore(result);
        await box.delete(key);
        sincronizados++;
      } catch (e) {
        debugPrint('sincronizarPendentes falhou key=$key: $e');
      }
    }
    return sincronizados;
  }

  /// Contagem para o dashboard (Firestore + pendentes locais).
  Future<({int aprovados, int reprovados})> contarAprovacaoReprovacao() async {
    int aprovados = 0;
    int reprovados = 0;

    void contarStatus(String status) {
      if (TesteValidator.isAprovado(status)) {
        aprovados++;
      } else {
        reprovados++;
      }
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collection(colecaoHistorico)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final Map<String, dynamic> data = doc.data();
        final String status = _extrairStatus(data);
        contarStatus(status);
      }
    } catch (e) {
      debugPrint('contarAprovacaoReprovacao Firestore: $e');
    }

    final Box<dynamic> box = Hive.box<dynamic>(boxHistoricoPendentes);
    for (final dynamic key in box.keys) {
      final dynamic raw = box.get(key);
      if (raw is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          raw.map(
            (dynamic k, dynamic v) => MapEntry(k.toString(), v),
          ),
        );
        contarStatus(_extrairStatus(map));
      }
    }

    return (aprovados: aprovados, reprovados: reprovados);
  }

  String _extrairStatus(Map<String, dynamic> data) {
    final String? status = data['status'] as String?;
    if (status != null && status.isNotEmpty) return status;
    final String? resultado = data['resultado'] as String?;
    if (resultado != null &&
        resultado.toLowerCase().contains('aprovado') &&
        !resultado.toLowerCase().contains('reprovado')) {
      return TesteStatus.aprovado;
    }
    return TesteStatus.reprovadoSubcorrente;
  }
}
