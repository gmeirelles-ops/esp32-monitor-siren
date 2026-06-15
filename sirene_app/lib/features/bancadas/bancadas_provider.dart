import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers/core_providers.dart';

/// Mapa deviceId (MAC) → número sequencial da bancada (1, 2, 3…).
final bancadasMapProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).watchBancadaNumeros();
});

/// Bancadas ordenadas por número crescente.
final bancadasOrderedProvider = StreamProvider<List<Bancada>>((ref) {
  return ref.watch(databaseProvider).watchAllBancadasOrdered();
});
