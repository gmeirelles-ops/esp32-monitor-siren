import '../../../core/database/database.dart';
import '../models/firestore_mappers.dart';

/// Lê documentos de uma coleção Firestore (ou fonte fake em teste).
typedef CatalogReader = Future<List<Map<String, dynamic>>> Function();

class CatalogPullResult {
  const CatalogPullResult({required this.products, required this.operators});

  final int products;
  final int operators;

  int get total => products + operators;
}

/// Baixa catálogo da nuvem e aplica no SQLite local.
class CatalogCloudService {
  CatalogCloudService({
    required AppDatabase db,
    required CatalogReader productReader,
    required CatalogReader operatorReader,
  })  : _db = db,
        _productReader = productReader,
        _operatorReader = operatorReader;

  final AppDatabase _db;
  final CatalogReader _productReader;
  final CatalogReader _operatorReader;

  Future<int> pullProducts() async {
    final docs = await _productReader();
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

  Future<int> pullOperators() async {
    final docs = await _operatorReader();
    var applied = 0;
    for (final doc in docs) {
      final parsed = operatorFromFirestore(doc);
      if (parsed == null) continue;
      await _db.upsertOperatorFromCloud(
        codigo: parsed.codigo,
        nome: parsed.nome,
        ativo: parsed.ativo,
        isGestor: parsed.isGestor,
        updatedAt: parsed.updatedAt,
      );
      applied++;
    }
    return applied;
  }

  Future<CatalogPullResult> pullAll() async {
    final products = await pullProducts();
    final operators = await pullOperators();
    return CatalogPullResult(products: products, operators: operators);
  }

  /// Compat: retorna só contagem de produtos.
  Future<int> pull() => pullProducts();
}
