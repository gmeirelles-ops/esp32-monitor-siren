import 'package:cloud_firestore/cloud_firestore.dart';

import '../../products/power_limits.dart';

/// Maior sequencial no catálogo Firestore `seriais/{produto}/anos/{YYYY}/meses/*/itens`.
Future<int?> maxCatalogSequencial({
  required FirebaseFirestore firestore,
  required String idProduto,
  required String yyyy,
}) async {
  final produto = normalizeProductId(idProduto);
  final mesesSnap = await firestore
      .collection('seriais')
      .doc(produto)
      .collection('anos')
      .doc(yyyy)
      .collection('meses')
      .get();

  int? maxSeq;
  for (final mes in mesesSnap.docs) {
    final itensSnap = await mes.reference.collection('itens').get();
    for (final item in itensSnap.docs) {
      final serial = item.id.trim();
      if (serial.length < 9) continue;
      if (!serial.startsWith(produto)) continue;
      final seq = int.tryParse(serial.substring(5, 9));
      if (seq == null) continue;
      if (maxSeq == null || seq > maxSeq) maxSeq = seq;
    }
  }
  return maxSeq;
}

/// Ano civil `YYYY` a partir do ano de lote de 2 dígitos (posto SPT ~2020–2099).
String catalogYearFromBatchAno(String ano2, [DateTime? now]) {
  final yy = int.tryParse(ano2.padLeft(2, '0').substring(0, 2)) ?? 0;
  final century = ((now ?? DateTime.now()).year ~/ 100) * 100;
  return (century + yy).toString().padLeft(4, '0');
}
