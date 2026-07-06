enum DeviceFsmState {
  provisioning,
  idle,
  batchReady,
  testing,
  hardwareFault,
  otaUpdating,
  unknown;

  static DeviceFsmState fromString(String? value) {
    switch (value) {
      case 'PROVISIONING':
        return DeviceFsmState.provisioning;
      case 'IDLE':
        return DeviceFsmState.idle;
      case 'BATCH_READY':
        return DeviceFsmState.batchReady;
      case 'TESTING':
        return DeviceFsmState.testing;
      case 'HARDWARE_FAULT':
        return DeviceFsmState.hardwareFault;
      case 'OTA_UPDATING':
        return DeviceFsmState.otaUpdating;
      default:
        return DeviceFsmState.unknown;
    }
  }

  String get label {
    switch (this) {
      case DeviceFsmState.provisioning:
        return 'Provisionando';
      case DeviceFsmState.idle:
        return 'Ocioso';
      case DeviceFsmState.batchReady:
        return 'Lote pronto';
      case DeviceFsmState.testing:
        return 'Testando';
      case DeviceFsmState.hardwareFault:
        return 'Falha hardware';
      case DeviceFsmState.otaUpdating:
        return 'Atualizando OTA';
      case DeviceFsmState.unknown:
        return 'Desconhecido';
    }
  }

  /// Valor MQTT/firmware (`IDLE`, `BATCH_READY`, …).
  String get mqttEstado {
    switch (this) {
      case DeviceFsmState.provisioning:
        return 'PROVISIONING';
      case DeviceFsmState.idle:
        return 'IDLE';
      case DeviceFsmState.batchReady:
        return 'BATCH_READY';
      case DeviceFsmState.testing:
        return 'TESTING';
      case DeviceFsmState.hardwareFault:
        return 'HARDWARE_FAULT';
      case DeviceFsmState.otaUpdating:
        return 'OTA_UPDATING';
      case DeviceFsmState.unknown:
        return '';
    }
  }
}

enum AppMqttConnectionState { disconnected, connecting, connected, reconnecting }

class HeartbeatMessage {
  const HeartbeatMessage({
    required this.uptime,
    required this.rssi,
    required this.estado,
    required this.fila,
    required this.firmwareVersion,
    this.deviceId,
    this.bancada,
    this.site,
  });

  final int uptime;
  final int rssi;
  final DeviceFsmState estado;
  final int fila;
  final String firmwareVersion;
  final String? deviceId;
  final int? bancada;
  final String? site;
}

class TestResultMessage {
  const TestResultMessage({
    required this.numeroOp,
    required this.idProduto,
    required this.ano,
    required this.veredito,
    required this.potenciaMedia,
    required this.sequencial,
    required this.aprovadosNoLote,
  });

  final String numeroOp;
  final String idProduto;
  final String ano;
  final String veredito;
  final double potenciaMedia;
  final int sequencial;
  final int aprovadosNoLote;

  bool get isApproved => veredito == 'APROVADO';
}

class RejectionMessage {
  const RejectionMessage({required this.motivo});
  final String motivo;
}

class OtaStatusMessage {
  const OtaStatusMessage({required this.evento, this.detalhe, this.deviceId});
  final String evento;
  final String? detalhe;
  final String? deviceId;
}

class CalibrationSampleMessage {
  const CalibrationSampleMessage({
    required this.potenciaW,
    required this.elapsedMs,
  });

  final double potenciaW;
  final int elapsedMs;
}

class CalibrationMessage {
  const CalibrationMessage({required this.potenciaMedia});
  final double potenciaMedia;
}

class HardwareAlertMessage {
  const HardwareAlertMessage({this.falha, this.evento});

  final String? falha;
  final String? evento;

  bool get isRecovery => evento == 'recuperado';
}

class EnsaioStatusMessage {
  const EnsaioStatusMessage({
    required this.evento,
    this.n,
    this.fase,
    this.elapsedSec = 0,
    this.ciclos = 0,
    this.motivo,
    this.onSec,
    this.offSec,
    this.duracaoTotalSec,
  });

  final String evento;
  final int? n;
  final String? fase;
  final int elapsedSec;
  final int ciclos;
  final String? motivo;
  final int? onSec;
  final int? offSec;
  final int? duracaoTotalSec;

  bool get isStarted => evento == 'iniciado';
  bool get isCycle => evento == 'ciclo';
  bool get isOnPhase => fase == 'ligado';
  bool get isOffPhase => fase == 'desligado';
  bool get isCompleted => evento == 'concluido';
  bool get isFailed => evento == 'falha';
  bool get isStopped => isCompleted && motivo == 'parado';

  /// Compatibilidade com ciclo ativo.
  int get ciclo => n ?? ciclos;
}

class DeviceInfo {
  DeviceInfo({required this.deviceId});

  final String deviceId;
  int? bancadaNum;
  bool isOnline = false;
  DeviceFsmState estado = DeviceFsmState.unknown;
  int rssi = 0;
  int uptime = 0;
  int fila = 0;
  String firmwareVersion = '';
  DateTime? lastSeen;
  String? lastHardwareAlert;
  RejectionMessage? lastRejection;
  double? lastCalibration;
  BatchConfig? activeBatch;
  TestResultMessage? lastTestResult;
}

class BatchConfig {
  const BatchConfig({
    required this.numeroOp,
    required this.idProduto,
    required this.ano,
    required this.tempoTeste,
    required this.potenciaMin,
    required this.potenciaMax,
    required this.quantidadeTotal,
    required this.proximoSequencial,
    this.modoReteste = false,
  });

  final String numeroOp;
  final String idProduto;
  final String ano;
  final int tempoTeste;
  final double potenciaMin;
  final double potenciaMax;
  final int quantidadeTotal;
  final int proximoSequencial;
  final bool modoReteste;

  Map<String, dynamic> toSetBatchJson() => {
    'cmd': 'SET_BATCH',
    'numero_op': numeroOp,
    'id_produto': idProduto,
    'ano': ano,
    'tempo_teste': tempoTeste,
    'potencia_min': potenciaMin,
    'potencia_max': potenciaMax,
    'quantidade_total': quantidadeTotal,
    'proximo_sequencial': proximoSequencial,
    'modo_reteste': modoReteste,
  };

  BatchConfig copyWith({int? proximoSequencial, bool? modoReteste}) {
    return BatchConfig(
      numeroOp: numeroOp,
      idProduto: idProduto,
      ano: ano,
      tempoTeste: tempoTeste,
      potenciaMin: potenciaMin,
      potenciaMax: potenciaMax,
      quantidadeTotal: quantidadeTotal,
      proximoSequencial: proximoSequencial ?? this.proximoSequencial,
      modoReteste: modoReteste ?? this.modoReteste,
    );
  }
}
