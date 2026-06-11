import '../../../core/database/database.dart';
import '../models/firestore_mappers.dart';

/// Lê documentos da coleção `products` do Firestore (ou fonte fake em teste).
typedef CatalogReader = Future<List<Map<String, dynamic>>> Function();

/// Baixa o catálogo da nuvem e faz upsert no SQLite local.
class CatalogCloudService {
  CatalogCloudService({required AppDatabase db, required CatalogReader reader})
      : _db = db,
        _reader = reader;

  final AppDatabase _db;
  final CatalogReader _reader;

  /// Aplica os produtos remotos no SQLite. Retorna quantos foram aplicados.
  Future<int> pull() async {
    final docs = await _reader();
    var applied = 0;
    for (final doc in docs) {
      final parsed = productFromFirestore(doc);
      if (parsed == null) continue;
      await _db.upsertProduct(
        idProduto: parsed.idProduto,
        nome: parsed.nome,
        potenciaRef: parsed.potenciaRef,
        potenciaMin: parsed.potenciaMin,
        potenciaMax: parsed.potenciaMax,
        toleranciaPct: parsed.toleranciaPct,
        tempoTesteSec: parsed.tempoTesteSec,
        calibradoEm: parsed.calibradoEm,
        calibradoDeviceId: parsed.calibradoDeviceId,
      );
      applied++;
    }
    return applied;
  }
}
