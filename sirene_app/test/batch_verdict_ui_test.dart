import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/features/batch/batch_verdict_ui.dart';
import 'package:sirene_app/features/mqtt/models/mqtt_messages.dart';

void main() {
  group('resolveBatchOperatorHeroPhase', () {
    test('prioriza live result', () {
      expect(
        resolveBatchOperatorHeroPhase(
          hasLiveResultForOp: true,
          estado: DeviceFsmState.hardwareFault,
          awaitingMqtt: true,
          stickyIssue: StickyVerdictIssue.resultPending,
          hasHardwareAlert: true,
        ),
        BatchOperatorHeroPhase.liveResult,
      );
    });

    test('testing antes de awaiting', () {
      expect(
        resolveBatchOperatorHeroPhase(
          hasLiveResultForOp: false,
          estado: DeviceFsmState.testing,
          awaitingMqtt: true,
          stickyIssue: null,
          hasHardwareAlert: false,
        ),
        BatchOperatorHeroPhase.testing,
      );
    });

    test('aguardando mqtt', () {
      expect(
        resolveBatchOperatorHeroPhase(
          hasLiveResultForOp: false,
          estado: DeviceFsmState.batchReady,
          awaitingMqtt: true,
          stickyIssue: StickyVerdictIssue.resultPending,
          hasHardwareAlert: false,
        ),
        BatchOperatorHeroPhase.awaitingMqtt,
      );
    });

    test('falha hardware sticky', () {
      expect(
        resolveBatchOperatorHeroPhase(
          hasLiveResultForOp: false,
          estado: DeviceFsmState.batchReady,
          awaitingMqtt: false,
          stickyIssue: StickyVerdictIssue.hardwareFault,
          hasHardwareAlert: false,
        ),
        BatchOperatorHeroPhase.hardwareFault,
      );
    });

    test('resultado pendente sticky', () {
      expect(
        resolveBatchOperatorHeroPhase(
          hasLiveResultForOp: false,
          estado: DeviceFsmState.batchReady,
          awaitingMqtt: false,
          stickyIssue: StickyVerdictIssue.resultPending,
          hasHardwareAlert: false,
        ),
        BatchOperatorHeroPhase.resultPending,
      );
    });
  });

  group('stickyVerdictMessage', () {
    test('pendente orienta não avançar peça', () {
      final msg = stickyVerdictMessage(StickyVerdictIssue.resultPending);
      expect(msg, contains('APROVADO'));
      expect(msg, contains('Não avance'));
    });

    test('pzem detalhe', () {
      final msg = stickyVerdictMessage(
        StickyVerdictIssue.hardwareFault,
        hardwareAlert: 'pzem_uart',
      );
      expect(msg.toLowerCase(), contains('potência'));
      expect(msg, contains('pzem_uart'));
    });
  });

  group('batch approval/sequencial gap', () {
    test('aprovados FW à frente do app', () {
      expect(
        hasBatchApprovalGap(firmwareAprovados: 5, localAprovados: 4),
        isTrue,
      );
      expect(
        hasBatchApprovalGap(firmwareAprovados: 4, localAprovados: 4),
        isFalse,
      );
    });

    test('proximo sequencial pulou', () {
      expect(
        hasBatchSequencialGap(
          firmwareProximoSequencial: 3,
          localMaxApprovedSequencial: 1,
        ),
        isTrue,
      );
      expect(
        hasBatchSequencialGap(
          firmwareProximoSequencial: 2,
          localMaxApprovedSequencial: 1,
        ),
        isFalse,
      );
      expect(
        hasBatchSequencialGap(
          firmwareProximoSequencial: 1,
          localMaxApprovedSequencial: 0,
        ),
        isFalse,
      );
    });

    test('detail menciona gap e não avançar', () {
      final d = batchSerialGapDetail(
        firmwareAprovados: 3,
        localAprovados: 1,
        firmwareProximo: 4,
      );
      expect(d, contains('FW=3'));
      expect(d, contains('app=1'));
      expect(d, contains('Não avance'));
    });
  });
}
