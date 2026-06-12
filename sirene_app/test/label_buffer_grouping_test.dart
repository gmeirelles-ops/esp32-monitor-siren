import 'package:flutter_test/flutter_test.dart';
import 'package:sirene_app/core/database/database.dart';
import 'package:sirene_app/features/labels/label_buffer_grouping.dart';

void main() {
  LabelBufferEntry entry(String serial, String op, DateTime at) {
    return LabelBufferEntry(id: serial.hashCode, serial: serial, numeroOp: op, createdAt: at);
  }

  test('groupLabelBufferByOp agrupa e ordena por data mais antiga', () {
    final t1 = DateTime(2026, 6, 10);
    final t2 = DateTime(2026, 6, 11);
    final t3 = DateTime(2026, 6, 9);

    final groups = groupLabelBufferByOp([
      entry('1232600011', 'OP-B', t2),
      entry('1232600021', 'OP-A', t1),
      entry('1232600031', 'OP-B', t3),
    ]);

    expect(groups.length, 2);
    expect(groups.first.numeroOp, 'OP-B');
    expect(groups.first.count, 2);
    expect(groups.last.numeroOp, 'OP-A');
    expect(groups.first.entries.first.serial, '1232600031');
  });

  test('orphanCount reflete módulo 3', () {
    final groups = groupLabelBufferByOp([
      entry('1', 'OP', DateTime.now()),
      entry('2', 'OP', DateTime.now()),
      entry('3', 'OP', DateTime.now()),
      entry('4', 'OP', DateTime.now()),
    ]);
    expect(groups.single.orphanCount, 1);
  });

  test('numeroOp vazio agrupa em Sem OP', () {
    final groups = groupLabelBufferByOp([
      entry('1', '', DateTime.now()),
    ]);
    expect(groups.single.numeroOp, 'Sem OP');
  });
}
