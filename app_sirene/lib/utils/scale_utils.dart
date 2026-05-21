/// Converte valores inteiros brutos do ESP32 (ex.: 250 → 2,50).
abstract final class ScaleUtils {
  static const int fatorEscala = 100;

  static double paraDecimal(int valorBruto) => valorBruto / fatorEscala;

  static String formatarAmperes(int correnteBruta) =>
      '${paraDecimal(correnteBruta).toStringAsFixed(2)} A';

  static String formatarWatts(int potenciaBruta) =>
      '${paraDecimal(potenciaBruta).toStringAsFixed(2)} W';
}
