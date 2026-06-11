// Stub até executar `flutterfire configure` no diretório sirene_app/.
// O arquivo gerado substitui este stub e define isConfigured = true.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase não configurado. Execute: cd sirene_app && flutterfire configure',
    );
  }
}
