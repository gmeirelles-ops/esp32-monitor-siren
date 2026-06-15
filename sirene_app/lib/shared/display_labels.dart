import '../../core/database/database.dart';

/// Rótulo de bancada: "Bancada {numero}" quando [numero] está disponível.
String formatBancadaLabel(String deviceId, {int? numero}) {
  if (numero != null) return 'Bancada $numero';
  return 'Bancada …';
}

/// Resolve rótulo a partir do mapa deviceId → numero.
String formatBancadaLabelFromMap(String deviceId, Map<String, int> numeros) {
  return formatBancadaLabel(deviceId, numero: numeros[deviceId]);
}

/// Rótulo de produto: "{id} — {nome}" quando o catálogo estiver disponível.
String formatProductLabel(
  String idProduto, {
  Product? product,
  Map<String, Product>? catalog,
}) {
  final p = product ?? catalog?[_normalizeProductId(idProduto)];
  if (p != null) return '${p.idProduto} — ${p.nome}';
  final id = idProduto.trim();
  return id.isEmpty ? '—' : id;
}

/// Extrai os 3 dígitos de produto do serial.
String? productIdFromSerial(String? serial) {
  if (serial == null || serial.length < 3) return null;
  return serial.substring(0, 3);
}

String formatProductLabelFromSerial(
  String? serial, {
  Product? product,
  Map<String, Product>? catalog,
}) {
  final id = productIdFromSerial(serial);
  if (id == null) return '—';
  return formatProductLabel(id, product: product, catalog: catalog);
}

Map<String, Product> productCatalogById(Iterable<Product> products) {
  return {for (final p in products) p.idProduto: p};
}

String _normalizeProductId(String id) {
  final t = id.trim();
  if (t.isEmpty) return t;
  return t.padLeft(3, '0').substring(0, 3);
}

Future<Map<String, Product>> loadProductCatalog(AppDatabase db) async {
  return productCatalogById(await db.getProducts());
}
