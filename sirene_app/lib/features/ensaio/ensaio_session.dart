import 'ensaio_config.dart';

enum EnsaioPhase { idle, on, off, completed, interrupted }

/// Estado em tempo real de um ensaio em andamento.
class EnsaioSession {
  const EnsaioSession({
    required this.nome,
    required this.deviceId,
    required this.config,
    required this.startedAt,
    required this.phase,
    required this.cycle,
    required this.remainingSeconds,
    this.recordId,
    this.phaseEndsAt,
    this.finalized = false,
  });

  final int? recordId;
  final String nome;
  final String deviceId;
  final EnsaioConfig config;
  final DateTime startedAt;
  final EnsaioPhase phase;
  final int cycle;
  final int remainingSeconds;
  final DateTime? phaseEndsAt;
  final bool finalized;

  bool get isActive => phase == EnsaioPhase.on || phase == EnsaioPhase.off;

  int get elapsedSeconds => config.totalSeconds - remainingSeconds;

  Duration get elapsed => DateTime.now().difference(startedAt);

  double get progress {
    final total = config.totalSeconds;
    if (total <= 0) return 0;
    final done = total - remainingSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  String get phaseLabel {
    switch (phase) {
      case EnsaioPhase.on:
        return 'Ligado';
      case EnsaioPhase.off:
        return 'Desligado';
      case EnsaioPhase.completed:
        return 'Concluído';
      case EnsaioPhase.interrupted:
        return 'Interrompido';
      case EnsaioPhase.idle:
        return 'Parado';
    }
  }

  EnsaioSession copyWith({
    int? recordId,
    String? nome,
    EnsaioConfig? config,
    EnsaioPhase? phase,
    int? cycle,
    int? remainingSeconds,
    DateTime? phaseEndsAt,
    bool? finalized,
  }) {
    return EnsaioSession(
      recordId: recordId ?? this.recordId,
      nome: nome ?? this.nome,
      deviceId: deviceId,
      config: config ?? this.config,
      startedAt: startedAt,
      phase: phase ?? this.phase,
      cycle: cycle ?? this.cycle,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phaseEndsAt: phaseEndsAt ?? this.phaseEndsAt,
      finalized: finalized ?? this.finalized,
    );
  }
}
