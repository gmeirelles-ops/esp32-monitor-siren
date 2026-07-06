/// Parâmetros do modo ensaio (ciclos ligado/desligado por duração total).
class EnsaioConfig {
  const EnsaioConfig({
    required this.onSeconds,
    required this.offSeconds,
    required this.totalSeconds,
  });

  final int onSeconds;
  final int offSeconds;
  final int totalSeconds;

  static const EnsaioConfig defaults = EnsaioConfig(
    onSeconds: 60,
    offSeconds: 60,
    totalSeconds: 2 * 60 * 60,
  );

  Duration get totalDuration => Duration(seconds: totalSeconds);

  int get totalMinutes => totalSeconds ~/ 60;

  int get onMinutes => onSeconds ~/ 60;

  int get offMinutes => offSeconds ~/ 60;

  int get cycleMinutes => onMinutes + offMinutes;

  String? validate() {
    if (onSeconds < 60 || onSeconds > 600 || onSeconds % 60 != 0) {
      return 'Tempo ligado: entre 1 e 10 minutos';
    }
    if (offSeconds < 60 || offSeconds > 600 || offSeconds % 60 != 0) {
      return 'Tempo desligado: entre 1 e 10 minutos';
    }
    if (totalSeconds < 10) {
      return 'Duração mínima: 10 s';
    }
    if (totalSeconds > 8 * 60 * 60) {
      return 'Duração máxima: 480 min (8 h)';
    }
    if (onSeconds + offSeconds > totalSeconds) {
      return 'Ligado + desligado não pode exceder a duração total';
    }
    return null;
  }

  Map<String, dynamic> toMqttPayload() => {
        'cmd': 'START_ENSAIO',
        'on_sec': onSeconds,
        'off_sec': offSeconds,
        'duracao_total_sec': totalSeconds,
      };

  EnsaioConfig copyWith({
    int? onSeconds,
    int? offSeconds,
    int? totalSeconds,
  }) {
    return EnsaioConfig(
      onSeconds: onSeconds ?? this.onSeconds,
      offSeconds: offSeconds ?? this.offSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }
}
