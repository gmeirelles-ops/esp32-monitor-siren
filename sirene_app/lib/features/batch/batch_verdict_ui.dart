import '../mqtt/models/mqtt_messages.dart';

/// Decide o que o operador deve ver no cartão principal (ordem de prioridade).
enum BatchOperatorHeroPhase {
  liveResult,
  testing,
  awaitingMqtt,
  hardwareFault,
  resultPending,
  idlePrompt,
}

BatchOperatorHeroPhase resolveBatchOperatorHeroPhase({
  required bool hasLiveResultForOp,
  required DeviceFsmState estado,
  required bool awaitingMqtt,
  required StickyVerdictIssue? stickyIssue,
  required bool hasHardwareAlert,
}) {
  if (hasLiveResultForOp) return BatchOperatorHeroPhase.liveResult;
  if (estado == DeviceFsmState.testing) return BatchOperatorHeroPhase.testing;
  if (awaitingMqtt) return BatchOperatorHeroPhase.awaitingMqtt;
  if (estado == DeviceFsmState.hardwareFault ||
      stickyIssue == StickyVerdictIssue.hardwareFault ||
      hasHardwareAlert) {
    return BatchOperatorHeroPhase.hardwareFault;
  }
  if (stickyIssue == StickyVerdictIssue.resultPending) {
    return BatchOperatorHeroPhase.resultPending;
  }
  return BatchOperatorHeroPhase.idlePrompt;
}

String stickyVerdictTitle(StickyVerdictIssue issue) {
  switch (issue) {
    case StickyVerdictIssue.resultPending:
      return 'Resultado pendente';
    case StickyVerdictIssue.hardwareFault:
      return 'Falha na bancada';
  }
}

String stickyVerdictMessage(
  StickyVerdictIssue issue, {
  String? hardwareAlert,
}) {
  switch (issue) {
    case StickyVerdictIssue.resultPending:
      return 'O teste não trouxe APROVADO nem REPROVADO. '
          'Não avance a peça — confira o visor da bancada ou repita o teste.';
    case StickyVerdictIssue.hardwareFault:
      final alert = hardwareAlert?.trim();
      if (alert != null && alert.isNotEmpty) {
        if (alert.toLowerCase().contains('pzem')) {
          return 'Medidor de potência com falha ($alert). '
              'Verifique cabos/conectores e tente de novo.';
        }
        return 'Falha: $alert. Verifique a bancada e tente de novo.';
      }
      return 'Medição/hardware com falha. Verifique energia nos conectores e o PZEM.';
  }
}

/// Firmware reporta mais aprovados do que o posto gravou (serial/teste ausente).
bool hasBatchApprovalGap({
  required int firmwareAprovados,
  required int localAprovados,
}) =>
    firmwareAprovados > localAprovados;

/// `proximo_sequencial` da bancada pulou à frente do maior sequencial aprovado local.
bool hasBatchSequencialGap({
  required int? firmwareProximoSequencial,
  required int localMaxApprovedSequencial,
}) {
  final proximo = firmwareProximoSequencial;
  if (proximo == null || proximo <= 0) return false;
  return proximo > localMaxApprovedSequencial + 1;
}

String batchSerialGapDetail({
  required int firmwareAprovados,
  required int localAprovados,
  int? firmwareProximo,
}) {
  final seq = firmwareProximo != null ? ', próximo seq FW=$firmwareProximo' : '';
  return 'Bancada avançou sem serial no app '
      '(aprovados FW=$firmwareAprovados, app=$localAprovados$seq). '
      'Não avance a peça — confira o visor ou repita o teste.';
}
