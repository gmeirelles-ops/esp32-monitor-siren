/// Copy voltada ao operador de linha (linguagem simples).
///
/// No posto o gatilho da gravação é o **pedal** (não a tecla F2 do software).
class LaserOperatorCopy {
  LaserOperatorCopy._();

  static const triggerTitle = 'Acione o pedal';
  static const triggerShort = 'Acione o pedal para gravar';
  static const triggerBody =
      'Com o serial na fila, acione o pedal para gravar na carcaça.';

  static String enqueuedSnack(String serial, {String? modelo}) => modelo != null
      ? 'Serial $serial ($modelo) na fila — acione o pedal'
      : 'Serial $serial na fila — acione o pedal';

  static String remarkDialogBody(String serial) =>
      'O serial $serial vai para a frente da fila de gravação. '
      'Acione o pedal para gravar na carcaça.';

  static const queueHelp =
      'Quando aparecer o serial na fila, acione o pedal para gravar.';
}
