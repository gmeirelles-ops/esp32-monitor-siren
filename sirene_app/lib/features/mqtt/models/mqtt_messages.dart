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
}

enum AppMqttConnectionState { disconnected, connecting, connected, reconnecting }

class HeartbeatMessage {
  const HeartbeatMessage({
    required this.uptime,
    required this.rssi,
    required this.estado,
    required this.fila,
    required this.firmwareVersion,
  });

  final int uptime;
  final int rssi;
  final DeviceFsmState estado;
  final int fila;
  final String firmwareVersion;
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
  const OtaStatusMessage({required this.evento, this.detalhe});
  final String evento;
  final String? detalhe;
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

class DeviceInfo {
  DeviceInfo({required this.deviceId});

  final String deviceId;
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
