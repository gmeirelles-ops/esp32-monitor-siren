import '../../core/services/app_log.dart';

/// Encadeia handlers async para processamento FIFO (uma mensagem por vez).
class MessagePump {
  Future<void> _chain = Future.value();

  void enqueue(Future<void> Function() handler) {
    _chain = _chain.then((_) async {
      try {
        await handler();
      } catch (e, st) {
        await AppLog.write('MessagePump: handler falhou', error: e, stack: st);
      }
    });
  }

  /// Aguarda o processamento de todas as mensagens enfileiradas (útil em testes).
  Future<void> get drained => _chain;
}
