// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TestResultsTable extends TestResults
    with TableInfo<$TestResultsTable, TestResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroOpMeta = const VerificationMeta(
    'numeroOp',
  );
  @override
  late final GeneratedColumn<String> numeroOp = GeneratedColumn<String>(
    'numero_op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vereditoMeta = const VerificationMeta(
    'veredito',
  );
  @override
  late final GeneratedColumn<String> veredito = GeneratedColumn<String>(
    'veredito',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potenciaMediaMeta = const VerificationMeta(
    'potenciaMedia',
  );
  @override
  late final GeneratedColumn<double> potenciaMedia = GeneratedColumn<double>(
    'potencia_media',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequencialMeta = const VerificationMeta(
    'sequencial',
  );
  @override
  late final GeneratedColumn<int> sequencial = GeneratedColumn<int>(
    'sequencial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aprovadosNoLoteMeta = const VerificationMeta(
    'aprovadosNoLote',
  );
  @override
  late final GeneratedColumn<int> aprovadosNoLote = GeneratedColumn<int>(
    'aprovados_no_lote',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
    'serial',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operadorMeta = const VerificationMeta(
    'operador',
  );
  @override
  late final GeneratedColumn<String> operador = GeneratedColumn<String>(
    'operador',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    numeroOp,
    veredito,
    potenciaMedia,
    sequencial,
    aprovadosNoLote,
    serial,
    operador,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<TestResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('numero_op')) {
      context.handle(
        _numeroOpMeta,
        numeroOp.isAcceptableOrUnknown(data['numero_op']!, _numeroOpMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroOpMeta);
    }
    if (data.containsKey('veredito')) {
      context.handle(
        _vereditoMeta,
        veredito.isAcceptableOrUnknown(data['veredito']!, _vereditoMeta),
      );
    } else if (isInserting) {
      context.missing(_vereditoMeta);
    }
    if (data.containsKey('potencia_media')) {
      context.handle(
        _potenciaMediaMeta,
        potenciaMedia.isAcceptableOrUnknown(
          data['potencia_media']!,
          _potenciaMediaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_potenciaMediaMeta);
    }
    if (data.containsKey('sequencial')) {
      context.handle(
        _sequencialMeta,
        sequencial.isAcceptableOrUnknown(data['sequencial']!, _sequencialMeta),
      );
    } else if (isInserting) {
      context.missing(_sequencialMeta);
    }
    if (data.containsKey('aprovados_no_lote')) {
      context.handle(
        _aprovadosNoLoteMeta,
        aprovadosNoLote.isAcceptableOrUnknown(
          data['aprovados_no_lote']!,
          _aprovadosNoLoteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aprovadosNoLoteMeta);
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    }
    if (data.containsKey('operador')) {
      context.handle(
        _operadorMeta,
        operador.isAcceptableOrUnknown(data['operador']!, _operadorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      numeroOp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_op'],
      )!,
      veredito: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}veredito'],
      )!,
      potenciaMedia: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potencia_media'],
      )!,
      sequencial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequencial'],
      )!,
      aprovadosNoLote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aprovados_no_lote'],
      )!,
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial'],
      ),
      operador: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operador'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TestResultsTable createAlias(String alias) {
    return $TestResultsTable(attachedDatabase, alias);
  }
}

class TestResult extends DataClass implements Insertable<TestResult> {
  final int id;
  final String deviceId;
  final String numeroOp;
  final String veredito;
  final double potenciaMedia;
  final int sequencial;
  final int aprovadosNoLote;
  final String? serial;
  final String? operador;
  final DateTime createdAt;
  const TestResult({
    required this.id,
    required this.deviceId,
    required this.numeroOp,
    required this.veredito,
    required this.potenciaMedia,
    required this.sequencial,
    required this.aprovadosNoLote,
    this.serial,
    this.operador,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['numero_op'] = Variable<String>(numeroOp);
    map['veredito'] = Variable<String>(veredito);
    map['potencia_media'] = Variable<double>(potenciaMedia);
    map['sequencial'] = Variable<int>(sequencial);
    map['aprovados_no_lote'] = Variable<int>(aprovadosNoLote);
    if (!nullToAbsent || serial != null) {
      map['serial'] = Variable<String>(serial);
    }
    if (!nullToAbsent || operador != null) {
      map['operador'] = Variable<String>(operador);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TestResultsCompanion toCompanion(bool nullToAbsent) {
    return TestResultsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      numeroOp: Value(numeroOp),
      veredito: Value(veredito),
      potenciaMedia: Value(potenciaMedia),
      sequencial: Value(sequencial),
      aprovadosNoLote: Value(aprovadosNoLote),
      serial: serial == null && nullToAbsent
          ? const Value.absent()
          : Value(serial),
      operador: operador == null && nullToAbsent
          ? const Value.absent()
          : Value(operador),
      createdAt: Value(createdAt),
    );
  }

  factory TestResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestResult(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      numeroOp: serializer.fromJson<String>(json['numeroOp']),
      veredito: serializer.fromJson<String>(json['veredito']),
      potenciaMedia: serializer.fromJson<double>(json['potenciaMedia']),
      sequencial: serializer.fromJson<int>(json['sequencial']),
      aprovadosNoLote: serializer.fromJson<int>(json['aprovadosNoLote']),
      serial: serializer.fromJson<String?>(json['serial']),
      operador: serializer.fromJson<String?>(json['operador']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'numeroOp': serializer.toJson<String>(numeroOp),
      'veredito': serializer.toJson<String>(veredito),
      'potenciaMedia': serializer.toJson<double>(potenciaMedia),
      'sequencial': serializer.toJson<int>(sequencial),
      'aprovadosNoLote': serializer.toJson<int>(aprovadosNoLote),
      'serial': serializer.toJson<String?>(serial),
      'operador': serializer.toJson<String?>(operador),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TestResult copyWith({
    int? id,
    String? deviceId,
    String? numeroOp,
    String? veredito,
    double? potenciaMedia,
    int? sequencial,
    int? aprovadosNoLote,
    Value<String?> serial = const Value.absent(),
    Value<String?> operador = const Value.absent(),
    DateTime? createdAt,
  }) => TestResult(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    numeroOp: numeroOp ?? this.numeroOp,
    veredito: veredito ?? this.veredito,
    potenciaMedia: potenciaMedia ?? this.potenciaMedia,
    sequencial: sequencial ?? this.sequencial,
    aprovadosNoLote: aprovadosNoLote ?? this.aprovadosNoLote,
    serial: serial.present ? serial.value : this.serial,
    operador: operador.present ? operador.value : this.operador,
    createdAt: createdAt ?? this.createdAt,
  );
  TestResult copyWithCompanion(TestResultsCompanion data) {
    return TestResult(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      numeroOp: data.numeroOp.present ? data.numeroOp.value : this.numeroOp,
      veredito: data.veredito.present ? data.veredito.value : this.veredito,
      potenciaMedia: data.potenciaMedia.present
          ? data.potenciaMedia.value
          : this.potenciaMedia,
      sequencial: data.sequencial.present
          ? data.sequencial.value
          : this.sequencial,
      aprovadosNoLote: data.aprovadosNoLote.present
          ? data.aprovadosNoLote.value
          : this.aprovadosNoLote,
      serial: data.serial.present ? data.serial.value : this.serial,
      operador: data.operador.present ? data.operador.value : this.operador,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestResult(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('veredito: $veredito, ')
          ..write('potenciaMedia: $potenciaMedia, ')
          ..write('sequencial: $sequencial, ')
          ..write('aprovadosNoLote: $aprovadosNoLote, ')
          ..write('serial: $serial, ')
          ..write('operador: $operador, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    numeroOp,
    veredito,
    potenciaMedia,
    sequencial,
    aprovadosNoLote,
    serial,
    operador,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestResult &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.numeroOp == this.numeroOp &&
          other.veredito == this.veredito &&
          other.potenciaMedia == this.potenciaMedia &&
          other.sequencial == this.sequencial &&
          other.aprovadosNoLote == this.aprovadosNoLote &&
          other.serial == this.serial &&
          other.operador == this.operador &&
          other.createdAt == this.createdAt);
}

class TestResultsCompanion extends UpdateCompanion<TestResult> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> numeroOp;
  final Value<String> veredito;
  final Value<double> potenciaMedia;
  final Value<int> sequencial;
  final Value<int> aprovadosNoLote;
  final Value<String?> serial;
  final Value<String?> operador;
  final Value<DateTime> createdAt;
  const TestResultsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.numeroOp = const Value.absent(),
    this.veredito = const Value.absent(),
    this.potenciaMedia = const Value.absent(),
    this.sequencial = const Value.absent(),
    this.aprovadosNoLote = const Value.absent(),
    this.serial = const Value.absent(),
    this.operador = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TestResultsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String numeroOp,
    required String veredito,
    required double potenciaMedia,
    required int sequencial,
    required int aprovadosNoLote,
    this.serial = const Value.absent(),
    this.operador = const Value.absent(),
    required DateTime createdAt,
  }) : deviceId = Value(deviceId),
       numeroOp = Value(numeroOp),
       veredito = Value(veredito),
       potenciaMedia = Value(potenciaMedia),
       sequencial = Value(sequencial),
       aprovadosNoLote = Value(aprovadosNoLote),
       createdAt = Value(createdAt);
  static Insertable<TestResult> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? numeroOp,
    Expression<String>? veredito,
    Expression<double>? potenciaMedia,
    Expression<int>? sequencial,
    Expression<int>? aprovadosNoLote,
    Expression<String>? serial,
    Expression<String>? operador,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (numeroOp != null) 'numero_op': numeroOp,
      if (veredito != null) 'veredito': veredito,
      if (potenciaMedia != null) 'potencia_media': potenciaMedia,
      if (sequencial != null) 'sequencial': sequencial,
      if (aprovadosNoLote != null) 'aprovados_no_lote': aprovadosNoLote,
      if (serial != null) 'serial': serial,
      if (operador != null) 'operador': operador,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TestResultsCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String>? numeroOp,
    Value<String>? veredito,
    Value<double>? potenciaMedia,
    Value<int>? sequencial,
    Value<int>? aprovadosNoLote,
    Value<String?>? serial,
    Value<String?>? operador,
    Value<DateTime>? createdAt,
  }) {
    return TestResultsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      numeroOp: numeroOp ?? this.numeroOp,
      veredito: veredito ?? this.veredito,
      potenciaMedia: potenciaMedia ?? this.potenciaMedia,
      sequencial: sequencial ?? this.sequencial,
      aprovadosNoLote: aprovadosNoLote ?? this.aprovadosNoLote,
      serial: serial ?? this.serial,
      operador: operador ?? this.operador,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (numeroOp.present) {
      map['numero_op'] = Variable<String>(numeroOp.value);
    }
    if (veredito.present) {
      map['veredito'] = Variable<String>(veredito.value);
    }
    if (potenciaMedia.present) {
      map['potencia_media'] = Variable<double>(potenciaMedia.value);
    }
    if (sequencial.present) {
      map['sequencial'] = Variable<int>(sequencial.value);
    }
    if (aprovadosNoLote.present) {
      map['aprovados_no_lote'] = Variable<int>(aprovadosNoLote.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (operador.present) {
      map['operador'] = Variable<String>(operador.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestResultsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('veredito: $veredito, ')
          ..write('potenciaMedia: $potenciaMedia, ')
          ..write('sequencial: $sequencial, ')
          ..write('aprovadosNoLote: $aprovadosNoLote, ')
          ..write('serial: $serial, ')
          ..write('operador: $operador, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LabelBufferEntriesTable extends LabelBufferEntries
    with TableInfo<$LabelBufferEntriesTable, LabelBufferEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabelBufferEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
    'serial',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroOpMeta = const VerificationMeta(
    'numeroOp',
  );
  @override
  late final GeneratedColumn<String> numeroOp = GeneratedColumn<String>(
    'numero_op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, serial, numeroOp, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'label_buffer_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabelBufferEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    } else if (isInserting) {
      context.missing(_serialMeta);
    }
    if (data.containsKey('numero_op')) {
      context.handle(
        _numeroOpMeta,
        numeroOp.isAcceptableOrUnknown(data['numero_op']!, _numeroOpMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroOpMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabelBufferEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabelBufferEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial'],
      )!,
      numeroOp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_op'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LabelBufferEntriesTable createAlias(String alias) {
    return $LabelBufferEntriesTable(attachedDatabase, alias);
  }
}

class LabelBufferEntry extends DataClass
    implements Insertable<LabelBufferEntry> {
  final int id;
  final String serial;
  final String numeroOp;
  final DateTime createdAt;
  const LabelBufferEntry({
    required this.id,
    required this.serial,
    required this.numeroOp,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['serial'] = Variable<String>(serial);
    map['numero_op'] = Variable<String>(numeroOp);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LabelBufferEntriesCompanion toCompanion(bool nullToAbsent) {
    return LabelBufferEntriesCompanion(
      id: Value(id),
      serial: Value(serial),
      numeroOp: Value(numeroOp),
      createdAt: Value(createdAt),
    );
  }

  factory LabelBufferEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabelBufferEntry(
      id: serializer.fromJson<int>(json['id']),
      serial: serializer.fromJson<String>(json['serial']),
      numeroOp: serializer.fromJson<String>(json['numeroOp']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serial': serializer.toJson<String>(serial),
      'numeroOp': serializer.toJson<String>(numeroOp),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LabelBufferEntry copyWith({
    int? id,
    String? serial,
    String? numeroOp,
    DateTime? createdAt,
  }) => LabelBufferEntry(
    id: id ?? this.id,
    serial: serial ?? this.serial,
    numeroOp: numeroOp ?? this.numeroOp,
    createdAt: createdAt ?? this.createdAt,
  );
  LabelBufferEntry copyWithCompanion(LabelBufferEntriesCompanion data) {
    return LabelBufferEntry(
      id: data.id.present ? data.id.value : this.id,
      serial: data.serial.present ? data.serial.value : this.serial,
      numeroOp: data.numeroOp.present ? data.numeroOp.value : this.numeroOp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabelBufferEntry(')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serial, numeroOp, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabelBufferEntry &&
          other.id == this.id &&
          other.serial == this.serial &&
          other.numeroOp == this.numeroOp &&
          other.createdAt == this.createdAt);
}

class LabelBufferEntriesCompanion extends UpdateCompanion<LabelBufferEntry> {
  final Value<int> id;
  final Value<String> serial;
  final Value<String> numeroOp;
  final Value<DateTime> createdAt;
  const LabelBufferEntriesCompanion({
    this.id = const Value.absent(),
    this.serial = const Value.absent(),
    this.numeroOp = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LabelBufferEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String serial,
    required String numeroOp,
    required DateTime createdAt,
  }) : serial = Value(serial),
       numeroOp = Value(numeroOp),
       createdAt = Value(createdAt);
  static Insertable<LabelBufferEntry> custom({
    Expression<int>? id,
    Expression<String>? serial,
    Expression<String>? numeroOp,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serial != null) 'serial': serial,
      if (numeroOp != null) 'numero_op': numeroOp,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LabelBufferEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? serial,
    Value<String>? numeroOp,
    Value<DateTime>? createdAt,
  }) {
    return LabelBufferEntriesCompanion(
      id: id ?? this.id,
      serial: serial ?? this.serial,
      numeroOp: numeroOp ?? this.numeroOp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (numeroOp.present) {
      map['numero_op'] = Variable<String>(numeroOp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabelBufferEntriesCompanion(')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idProdutoMeta = const VerificationMeta(
    'idProduto',
  );
  @override
  late final GeneratedColumn<String> idProduto = GeneratedColumn<String>(
    'id_produto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potenciaRefMeta = const VerificationMeta(
    'potenciaRef',
  );
  @override
  late final GeneratedColumn<double> potenciaRef = GeneratedColumn<double>(
    'potencia_ref',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potenciaMinMeta = const VerificationMeta(
    'potenciaMin',
  );
  @override
  late final GeneratedColumn<double> potenciaMin = GeneratedColumn<double>(
    'potencia_min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potenciaMaxMeta = const VerificationMeta(
    'potenciaMax',
  );
  @override
  late final GeneratedColumn<double> potenciaMax = GeneratedColumn<double>(
    'potencia_max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toleranciaPctMeta = const VerificationMeta(
    'toleranciaPct',
  );
  @override
  late final GeneratedColumn<double> toleranciaPct = GeneratedColumn<double>(
    'tolerancia_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(10.0),
  );
  static const VerificationMeta _tempoTesteSecMeta = const VerificationMeta(
    'tempoTesteSec',
  );
  @override
  late final GeneratedColumn<int> tempoTesteSec = GeneratedColumn<int>(
    'tempo_teste_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _calibradoEmMeta = const VerificationMeta(
    'calibradoEm',
  );
  @override
  late final GeneratedColumn<DateTime> calibradoEm = GeneratedColumn<DateTime>(
    'calibrado_em',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calibradoDeviceIdMeta = const VerificationMeta(
    'calibradoDeviceId',
  );
  @override
  late final GeneratedColumn<String> calibradoDeviceId =
      GeneratedColumn<String>(
        'calibrado_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    idProduto,
    nome,
    potenciaRef,
    potenciaMin,
    potenciaMax,
    toleranciaPct,
    tempoTesteSec,
    calibradoEm,
    calibradoDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_produto')) {
      context.handle(
        _idProdutoMeta,
        idProduto.isAcceptableOrUnknown(data['id_produto']!, _idProdutoMeta),
      );
    } else if (isInserting) {
      context.missing(_idProdutoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('potencia_ref')) {
      context.handle(
        _potenciaRefMeta,
        potenciaRef.isAcceptableOrUnknown(
          data['potencia_ref']!,
          _potenciaRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_potenciaRefMeta);
    }
    if (data.containsKey('potencia_min')) {
      context.handle(
        _potenciaMinMeta,
        potenciaMin.isAcceptableOrUnknown(
          data['potencia_min']!,
          _potenciaMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_potenciaMinMeta);
    }
    if (data.containsKey('potencia_max')) {
      context.handle(
        _potenciaMaxMeta,
        potenciaMax.isAcceptableOrUnknown(
          data['potencia_max']!,
          _potenciaMaxMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_potenciaMaxMeta);
    }
    if (data.containsKey('tolerancia_pct')) {
      context.handle(
        _toleranciaPctMeta,
        toleranciaPct.isAcceptableOrUnknown(
          data['tolerancia_pct']!,
          _toleranciaPctMeta,
        ),
      );
    }
    if (data.containsKey('tempo_teste_sec')) {
      context.handle(
        _tempoTesteSecMeta,
        tempoTesteSec.isAcceptableOrUnknown(
          data['tempo_teste_sec']!,
          _tempoTesteSecMeta,
        ),
      );
    }
    if (data.containsKey('calibrado_em')) {
      context.handle(
        _calibradoEmMeta,
        calibradoEm.isAcceptableOrUnknown(
          data['calibrado_em']!,
          _calibradoEmMeta,
        ),
      );
    }
    if (data.containsKey('calibrado_device_id')) {
      context.handle(
        _calibradoDeviceIdMeta,
        calibradoDeviceId.isAcceptableOrUnknown(
          data['calibrado_device_id']!,
          _calibradoDeviceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idProduto};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      idProduto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_produto'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      potenciaRef: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potencia_ref'],
      )!,
      potenciaMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potencia_min'],
      )!,
      potenciaMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potencia_max'],
      )!,
      toleranciaPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tolerancia_pct'],
      )!,
      tempoTesteSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tempo_teste_sec'],
      )!,
      calibradoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}calibrado_em'],
      ),
      calibradoDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibrado_device_id'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String idProduto;
  final String nome;
  final double potenciaRef;
  final double potenciaMin;
  final double potenciaMax;
  final double toleranciaPct;
  final int tempoTesteSec;
  final DateTime? calibradoEm;
  final String? calibradoDeviceId;
  const Product({
    required this.idProduto,
    required this.nome,
    required this.potenciaRef,
    required this.potenciaMin,
    required this.potenciaMax,
    required this.toleranciaPct,
    required this.tempoTesteSec,
    this.calibradoEm,
    this.calibradoDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_produto'] = Variable<String>(idProduto);
    map['nome'] = Variable<String>(nome);
    map['potencia_ref'] = Variable<double>(potenciaRef);
    map['potencia_min'] = Variable<double>(potenciaMin);
    map['potencia_max'] = Variable<double>(potenciaMax);
    map['tolerancia_pct'] = Variable<double>(toleranciaPct);
    map['tempo_teste_sec'] = Variable<int>(tempoTesteSec);
    if (!nullToAbsent || calibradoEm != null) {
      map['calibrado_em'] = Variable<DateTime>(calibradoEm);
    }
    if (!nullToAbsent || calibradoDeviceId != null) {
      map['calibrado_device_id'] = Variable<String>(calibradoDeviceId);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      idProduto: Value(idProduto),
      nome: Value(nome),
      potenciaRef: Value(potenciaRef),
      potenciaMin: Value(potenciaMin),
      potenciaMax: Value(potenciaMax),
      toleranciaPct: Value(toleranciaPct),
      tempoTesteSec: Value(tempoTesteSec),
      calibradoEm: calibradoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(calibradoEm),
      calibradoDeviceId: calibradoDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(calibradoDeviceId),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      idProduto: serializer.fromJson<String>(json['idProduto']),
      nome: serializer.fromJson<String>(json['nome']),
      potenciaRef: serializer.fromJson<double>(json['potenciaRef']),
      potenciaMin: serializer.fromJson<double>(json['potenciaMin']),
      potenciaMax: serializer.fromJson<double>(json['potenciaMax']),
      toleranciaPct: serializer.fromJson<double>(json['toleranciaPct']),
      tempoTesteSec: serializer.fromJson<int>(json['tempoTesteSec']),
      calibradoEm: serializer.fromJson<DateTime?>(json['calibradoEm']),
      calibradoDeviceId: serializer.fromJson<String?>(
        json['calibradoDeviceId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idProduto': serializer.toJson<String>(idProduto),
      'nome': serializer.toJson<String>(nome),
      'potenciaRef': serializer.toJson<double>(potenciaRef),
      'potenciaMin': serializer.toJson<double>(potenciaMin),
      'potenciaMax': serializer.toJson<double>(potenciaMax),
      'toleranciaPct': serializer.toJson<double>(toleranciaPct),
      'tempoTesteSec': serializer.toJson<int>(tempoTesteSec),
      'calibradoEm': serializer.toJson<DateTime?>(calibradoEm),
      'calibradoDeviceId': serializer.toJson<String?>(calibradoDeviceId),
    };
  }

  Product copyWith({
    String? idProduto,
    String? nome,
    double? potenciaRef,
    double? potenciaMin,
    double? potenciaMax,
    double? toleranciaPct,
    int? tempoTesteSec,
    Value<DateTime?> calibradoEm = const Value.absent(),
    Value<String?> calibradoDeviceId = const Value.absent(),
  }) => Product(
    idProduto: idProduto ?? this.idProduto,
    nome: nome ?? this.nome,
    potenciaRef: potenciaRef ?? this.potenciaRef,
    potenciaMin: potenciaMin ?? this.potenciaMin,
    potenciaMax: potenciaMax ?? this.potenciaMax,
    toleranciaPct: toleranciaPct ?? this.toleranciaPct,
    tempoTesteSec: tempoTesteSec ?? this.tempoTesteSec,
    calibradoEm: calibradoEm.present ? calibradoEm.value : this.calibradoEm,
    calibradoDeviceId: calibradoDeviceId.present
        ? calibradoDeviceId.value
        : this.calibradoDeviceId,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      idProduto: data.idProduto.present ? data.idProduto.value : this.idProduto,
      nome: data.nome.present ? data.nome.value : this.nome,
      potenciaRef: data.potenciaRef.present
          ? data.potenciaRef.value
          : this.potenciaRef,
      potenciaMin: data.potenciaMin.present
          ? data.potenciaMin.value
          : this.potenciaMin,
      potenciaMax: data.potenciaMax.present
          ? data.potenciaMax.value
          : this.potenciaMax,
      toleranciaPct: data.toleranciaPct.present
          ? data.toleranciaPct.value
          : this.toleranciaPct,
      tempoTesteSec: data.tempoTesteSec.present
          ? data.tempoTesteSec.value
          : this.tempoTesteSec,
      calibradoEm: data.calibradoEm.present
          ? data.calibradoEm.value
          : this.calibradoEm,
      calibradoDeviceId: data.calibradoDeviceId.present
          ? data.calibradoDeviceId.value
          : this.calibradoDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('idProduto: $idProduto, ')
          ..write('nome: $nome, ')
          ..write('potenciaRef: $potenciaRef, ')
          ..write('potenciaMin: $potenciaMin, ')
          ..write('potenciaMax: $potenciaMax, ')
          ..write('toleranciaPct: $toleranciaPct, ')
          ..write('tempoTesteSec: $tempoTesteSec, ')
          ..write('calibradoEm: $calibradoEm, ')
          ..write('calibradoDeviceId: $calibradoDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idProduto,
    nome,
    potenciaRef,
    potenciaMin,
    potenciaMax,
    toleranciaPct,
    tempoTesteSec,
    calibradoEm,
    calibradoDeviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.idProduto == this.idProduto &&
          other.nome == this.nome &&
          other.potenciaRef == this.potenciaRef &&
          other.potenciaMin == this.potenciaMin &&
          other.potenciaMax == this.potenciaMax &&
          other.toleranciaPct == this.toleranciaPct &&
          other.tempoTesteSec == this.tempoTesteSec &&
          other.calibradoEm == this.calibradoEm &&
          other.calibradoDeviceId == this.calibradoDeviceId);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> idProduto;
  final Value<String> nome;
  final Value<double> potenciaRef;
  final Value<double> potenciaMin;
  final Value<double> potenciaMax;
  final Value<double> toleranciaPct;
  final Value<int> tempoTesteSec;
  final Value<DateTime?> calibradoEm;
  final Value<String?> calibradoDeviceId;
  final Value<int> rowid;
  const ProductsCompanion({
    this.idProduto = const Value.absent(),
    this.nome = const Value.absent(),
    this.potenciaRef = const Value.absent(),
    this.potenciaMin = const Value.absent(),
    this.potenciaMax = const Value.absent(),
    this.toleranciaPct = const Value.absent(),
    this.tempoTesteSec = const Value.absent(),
    this.calibradoEm = const Value.absent(),
    this.calibradoDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String idProduto,
    required String nome,
    required double potenciaRef,
    required double potenciaMin,
    required double potenciaMax,
    this.toleranciaPct = const Value.absent(),
    this.tempoTesteSec = const Value.absent(),
    this.calibradoEm = const Value.absent(),
    this.calibradoDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idProduto = Value(idProduto),
       nome = Value(nome),
       potenciaRef = Value(potenciaRef),
       potenciaMin = Value(potenciaMin),
       potenciaMax = Value(potenciaMax);
  static Insertable<Product> custom({
    Expression<String>? idProduto,
    Expression<String>? nome,
    Expression<double>? potenciaRef,
    Expression<double>? potenciaMin,
    Expression<double>? potenciaMax,
    Expression<double>? toleranciaPct,
    Expression<int>? tempoTesteSec,
    Expression<DateTime>? calibradoEm,
    Expression<String>? calibradoDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idProduto != null) 'id_produto': idProduto,
      if (nome != null) 'nome': nome,
      if (potenciaRef != null) 'potencia_ref': potenciaRef,
      if (potenciaMin != null) 'potencia_min': potenciaMin,
      if (potenciaMax != null) 'potencia_max': potenciaMax,
      if (toleranciaPct != null) 'tolerancia_pct': toleranciaPct,
      if (tempoTesteSec != null) 'tempo_teste_sec': tempoTesteSec,
      if (calibradoEm != null) 'calibrado_em': calibradoEm,
      if (calibradoDeviceId != null) 'calibrado_device_id': calibradoDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? idProduto,
    Value<String>? nome,
    Value<double>? potenciaRef,
    Value<double>? potenciaMin,
    Value<double>? potenciaMax,
    Value<double>? toleranciaPct,
    Value<int>? tempoTesteSec,
    Value<DateTime?>? calibradoEm,
    Value<String?>? calibradoDeviceId,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      idProduto: idProduto ?? this.idProduto,
      nome: nome ?? this.nome,
      potenciaRef: potenciaRef ?? this.potenciaRef,
      potenciaMin: potenciaMin ?? this.potenciaMin,
      potenciaMax: potenciaMax ?? this.potenciaMax,
      toleranciaPct: toleranciaPct ?? this.toleranciaPct,
      tempoTesteSec: tempoTesteSec ?? this.tempoTesteSec,
      calibradoEm: calibradoEm ?? this.calibradoEm,
      calibradoDeviceId: calibradoDeviceId ?? this.calibradoDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idProduto.present) {
      map['id_produto'] = Variable<String>(idProduto.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (potenciaRef.present) {
      map['potencia_ref'] = Variable<double>(potenciaRef.value);
    }
    if (potenciaMin.present) {
      map['potencia_min'] = Variable<double>(potenciaMin.value);
    }
    if (potenciaMax.present) {
      map['potencia_max'] = Variable<double>(potenciaMax.value);
    }
    if (toleranciaPct.present) {
      map['tolerancia_pct'] = Variable<double>(toleranciaPct.value);
    }
    if (tempoTesteSec.present) {
      map['tempo_teste_sec'] = Variable<int>(tempoTesteSec.value);
    }
    if (calibradoEm.present) {
      map['calibrado_em'] = Variable<DateTime>(calibradoEm.value);
    }
    if (calibradoDeviceId.present) {
      map['calibrado_device_id'] = Variable<String>(calibradoDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('idProduto: $idProduto, ')
          ..write('nome: $nome, ')
          ..write('potenciaRef: $potenciaRef, ')
          ..write('potenciaMin: $potenciaMin, ')
          ..write('potenciaMax: $potenciaMax, ')
          ..write('toleranciaPct: $toleranciaPct, ')
          ..write('tempoTesteSec: $tempoTesteSec, ')
          ..write('calibradoEm: $calibradoEm, ')
          ..write('calibradoDeviceId: $calibradoDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collection,
    documentId,
    payload,
    operation,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String collection;
  final String documentId;
  final String payload;
  final String operation;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  const SyncQueueData({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.payload,
    required this.operation,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection'] = Variable<String>(collection);
    map['document_id'] = Variable<String>(documentId);
    map['payload'] = Variable<String>(payload);
    map['operation'] = Variable<String>(operation);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      collection: Value(collection),
      documentId: Value(documentId),
      payload: Value(payload),
      operation: Value(operation),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      collection: serializer.fromJson<String>(json['collection']),
      documentId: serializer.fromJson<String>(json['documentId']),
      payload: serializer.fromJson<String>(json['payload']),
      operation: serializer.fromJson<String>(json['operation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collection': serializer.toJson<String>(collection),
      'documentId': serializer.toJson<String>(documentId),
      'payload': serializer.toJson<String>(payload),
      'operation': serializer.toJson<String>(operation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? collection,
    String? documentId,
    String? payload,
    String? operation,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    collection: collection ?? this.collection,
    documentId: documentId ?? this.documentId,
    payload: payload ?? this.payload,
    operation: operation ?? this.operation,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      payload: data.payload.present ? data.payload.value : this.payload,
      operation: data.operation.present ? data.operation.value : this.operation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('collection: $collection, ')
          ..write('documentId: $documentId, ')
          ..write('payload: $payload, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collection,
    documentId,
    payload,
    operation,
    createdAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.collection == this.collection &&
          other.documentId == this.documentId &&
          other.payload == this.payload &&
          other.operation == this.operation &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> collection;
  final Value<String> documentId;
  final Value<String> payload;
  final Value<String> operation;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.collection = const Value.absent(),
    this.documentId = const Value.absent(),
    this.payload = const Value.absent(),
    this.operation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String collection,
    required String documentId,
    required String payload,
    required String operation,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : collection = Value(collection),
       documentId = Value(documentId),
       payload = Value(payload),
       operation = Value(operation),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? collection,
    Expression<String>? documentId,
    Expression<String>? payload,
    Expression<String>? operation,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collection != null) 'collection': collection,
      if (documentId != null) 'document_id': documentId,
      if (payload != null) 'payload': payload,
      if (operation != null) 'operation': operation,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? collection,
    Value<String>? documentId,
    Value<String>? payload,
    Value<String>? operation,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      documentId: documentId ?? this.documentId,
      payload: payload ?? this.payload,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('collection: $collection, ')
          ..write('documentId: $documentId, ')
          ..write('payload: $payload, ')
          ..write('operation: $operation, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SerialCountersTable extends SerialCounters
    with TableInfo<$SerialCountersTable, SerialCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SerialCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idProdutoMeta = const VerificationMeta(
    'idProduto',
  );
  @override
  late final GeneratedColumn<String> idProduto = GeneratedColumn<String>(
    'id_produto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anoMeta = const VerificationMeta('ano');
  @override
  late final GeneratedColumn<String> ano = GeneratedColumn<String>(
    'ano',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSequencialMeta = const VerificationMeta(
    'lastSequencial',
  );
  @override
  late final GeneratedColumn<int> lastSequencial = GeneratedColumn<int>(
    'last_sequencial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idProduto,
    ano,
    lastSequencial,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'serial_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SerialCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_produto')) {
      context.handle(
        _idProdutoMeta,
        idProduto.isAcceptableOrUnknown(data['id_produto']!, _idProdutoMeta),
      );
    } else if (isInserting) {
      context.missing(_idProdutoMeta);
    }
    if (data.containsKey('ano')) {
      context.handle(
        _anoMeta,
        ano.isAcceptableOrUnknown(data['ano']!, _anoMeta),
      );
    } else if (isInserting) {
      context.missing(_anoMeta);
    }
    if (data.containsKey('last_sequencial')) {
      context.handle(
        _lastSequencialMeta,
        lastSequencial.isAcceptableOrUnknown(
          data['last_sequencial']!,
          _lastSequencialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSequencialMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idProduto, ano};
  @override
  SerialCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SerialCounter(
      idProduto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_produto'],
      )!,
      ano: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ano'],
      )!,
      lastSequencial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sequencial'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SerialCountersTable createAlias(String alias) {
    return $SerialCountersTable(attachedDatabase, alias);
  }
}

class SerialCounter extends DataClass implements Insertable<SerialCounter> {
  final String idProduto;
  final String ano;
  final int lastSequencial;
  final DateTime updatedAt;
  const SerialCounter({
    required this.idProduto,
    required this.ano,
    required this.lastSequencial,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_produto'] = Variable<String>(idProduto);
    map['ano'] = Variable<String>(ano);
    map['last_sequencial'] = Variable<int>(lastSequencial);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SerialCountersCompanion toCompanion(bool nullToAbsent) {
    return SerialCountersCompanion(
      idProduto: Value(idProduto),
      ano: Value(ano),
      lastSequencial: Value(lastSequencial),
      updatedAt: Value(updatedAt),
    );
  }

  factory SerialCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SerialCounter(
      idProduto: serializer.fromJson<String>(json['idProduto']),
      ano: serializer.fromJson<String>(json['ano']),
      lastSequencial: serializer.fromJson<int>(json['lastSequencial']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idProduto': serializer.toJson<String>(idProduto),
      'ano': serializer.toJson<String>(ano),
      'lastSequencial': serializer.toJson<int>(lastSequencial),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SerialCounter copyWith({
    String? idProduto,
    String? ano,
    int? lastSequencial,
    DateTime? updatedAt,
  }) => SerialCounter(
    idProduto: idProduto ?? this.idProduto,
    ano: ano ?? this.ano,
    lastSequencial: lastSequencial ?? this.lastSequencial,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SerialCounter copyWithCompanion(SerialCountersCompanion data) {
    return SerialCounter(
      idProduto: data.idProduto.present ? data.idProduto.value : this.idProduto,
      ano: data.ano.present ? data.ano.value : this.ano,
      lastSequencial: data.lastSequencial.present
          ? data.lastSequencial.value
          : this.lastSequencial,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SerialCounter(')
          ..write('idProduto: $idProduto, ')
          ..write('ano: $ano, ')
          ..write('lastSequencial: $lastSequencial, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idProduto, ano, lastSequencial, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SerialCounter &&
          other.idProduto == this.idProduto &&
          other.ano == this.ano &&
          other.lastSequencial == this.lastSequencial &&
          other.updatedAt == this.updatedAt);
}

class SerialCountersCompanion extends UpdateCompanion<SerialCounter> {
  final Value<String> idProduto;
  final Value<String> ano;
  final Value<int> lastSequencial;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SerialCountersCompanion({
    this.idProduto = const Value.absent(),
    this.ano = const Value.absent(),
    this.lastSequencial = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SerialCountersCompanion.insert({
    required String idProduto,
    required String ano,
    required int lastSequencial,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : idProduto = Value(idProduto),
       ano = Value(ano),
       lastSequencial = Value(lastSequencial),
       updatedAt = Value(updatedAt);
  static Insertable<SerialCounter> custom({
    Expression<String>? idProduto,
    Expression<String>? ano,
    Expression<int>? lastSequencial,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idProduto != null) 'id_produto': idProduto,
      if (ano != null) 'ano': ano,
      if (lastSequencial != null) 'last_sequencial': lastSequencial,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SerialCountersCompanion copyWith({
    Value<String>? idProduto,
    Value<String>? ano,
    Value<int>? lastSequencial,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SerialCountersCompanion(
      idProduto: idProduto ?? this.idProduto,
      ano: ano ?? this.ano,
      lastSequencial: lastSequencial ?? this.lastSequencial,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idProduto.present) {
      map['id_produto'] = Variable<String>(idProduto.value);
    }
    if (ano.present) {
      map['ano'] = Variable<String>(ano.value);
    }
    if (lastSequencial.present) {
      map['last_sequencial'] = Variable<int>(lastSequencial.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SerialCountersCompanion(')
          ..write('idProduto: $idProduto, ')
          ..write('ano: $ano, ')
          ..write('lastSequencial: $lastSequencial, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HardwareEventsTable extends HardwareEvents
    with TableInfo<$HardwareEventsTable, HardwareEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HardwareEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _falhaMeta = const VerificationMeta('falha');
  @override
  late final GeneratedColumn<String> falha = GeneratedColumn<String>(
    'falha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, deviceId, falha, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hardware_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<HardwareEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('falha')) {
      context.handle(
        _falhaMeta,
        falha.isAcceptableOrUnknown(data['falha']!, _falhaMeta),
      );
    } else if (isInserting) {
      context.missing(_falhaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HardwareEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HardwareEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      falha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}falha'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HardwareEventsTable createAlias(String alias) {
    return $HardwareEventsTable(attachedDatabase, alias);
  }
}

class HardwareEvent extends DataClass implements Insertable<HardwareEvent> {
  final int id;
  final String deviceId;
  final String falha;
  final DateTime createdAt;
  const HardwareEvent({
    required this.id,
    required this.deviceId,
    required this.falha,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['falha'] = Variable<String>(falha);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HardwareEventsCompanion toCompanion(bool nullToAbsent) {
    return HardwareEventsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      falha: Value(falha),
      createdAt: Value(createdAt),
    );
  }

  factory HardwareEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HardwareEvent(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      falha: serializer.fromJson<String>(json['falha']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'falha': serializer.toJson<String>(falha),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HardwareEvent copyWith({
    int? id,
    String? deviceId,
    String? falha,
    DateTime? createdAt,
  }) => HardwareEvent(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    falha: falha ?? this.falha,
    createdAt: createdAt ?? this.createdAt,
  );
  HardwareEvent copyWithCompanion(HardwareEventsCompanion data) {
    return HardwareEvent(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      falha: data.falha.present ? data.falha.value : this.falha,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HardwareEvent(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('falha: $falha, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, falha, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HardwareEvent &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.falha == this.falha &&
          other.createdAt == this.createdAt);
}

class HardwareEventsCompanion extends UpdateCompanion<HardwareEvent> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> falha;
  final Value<DateTime> createdAt;
  const HardwareEventsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.falha = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HardwareEventsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String falha,
    required DateTime createdAt,
  }) : deviceId = Value(deviceId),
       falha = Value(falha),
       createdAt = Value(createdAt);
  static Insertable<HardwareEvent> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? falha,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (falha != null) 'falha': falha,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HardwareEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String>? falha,
    Value<DateTime>? createdAt,
  }) {
    return HardwareEventsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      falha: falha ?? this.falha,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (falha.present) {
      map['falha'] = Variable<String>(falha.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HardwareEventsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('falha: $falha, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CalibrationHistoryTable extends CalibrationHistory
    with TableInfo<$CalibrationHistoryTable, CalibrationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalibrationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idProdutoMeta = const VerificationMeta(
    'idProduto',
  );
  @override
  late final GeneratedColumn<String> idProduto = GeneratedColumn<String>(
    'id_produto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _potenciaRefMeta = const VerificationMeta(
    'potenciaRef',
  );
  @override
  late final GeneratedColumn<double> potenciaRef = GeneratedColumn<double>(
    'potencia_ref',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idProduto,
    potenciaRef,
    deviceId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calibration_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalibrationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('id_produto')) {
      context.handle(
        _idProdutoMeta,
        idProduto.isAcceptableOrUnknown(data['id_produto']!, _idProdutoMeta),
      );
    } else if (isInserting) {
      context.missing(_idProdutoMeta);
    }
    if (data.containsKey('potencia_ref')) {
      context.handle(
        _potenciaRefMeta,
        potenciaRef.isAcceptableOrUnknown(
          data['potencia_ref']!,
          _potenciaRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_potenciaRefMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalibrationHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalibrationHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      idProduto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_produto'],
      )!,
      potenciaRef: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potencia_ref'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CalibrationHistoryTable createAlias(String alias) {
    return $CalibrationHistoryTable(attachedDatabase, alias);
  }
}

class CalibrationHistoryData extends DataClass
    implements Insertable<CalibrationHistoryData> {
  final int id;
  final String idProduto;
  final double potenciaRef;
  final String? deviceId;
  final DateTime createdAt;
  const CalibrationHistoryData({
    required this.id,
    required this.idProduto,
    required this.potenciaRef,
    this.deviceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['id_produto'] = Variable<String>(idProduto);
    map['potencia_ref'] = Variable<double>(potenciaRef);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CalibrationHistoryCompanion toCompanion(bool nullToAbsent) {
    return CalibrationHistoryCompanion(
      id: Value(id),
      idProduto: Value(idProduto),
      potenciaRef: Value(potenciaRef),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      createdAt: Value(createdAt),
    );
  }

  factory CalibrationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalibrationHistoryData(
      id: serializer.fromJson<int>(json['id']),
      idProduto: serializer.fromJson<String>(json['idProduto']),
      potenciaRef: serializer.fromJson<double>(json['potenciaRef']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idProduto': serializer.toJson<String>(idProduto),
      'potenciaRef': serializer.toJson<double>(potenciaRef),
      'deviceId': serializer.toJson<String?>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CalibrationHistoryData copyWith({
    int? id,
    String? idProduto,
    double? potenciaRef,
    Value<String?> deviceId = const Value.absent(),
    DateTime? createdAt,
  }) => CalibrationHistoryData(
    id: id ?? this.id,
    idProduto: idProduto ?? this.idProduto,
    potenciaRef: potenciaRef ?? this.potenciaRef,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    createdAt: createdAt ?? this.createdAt,
  );
  CalibrationHistoryData copyWithCompanion(CalibrationHistoryCompanion data) {
    return CalibrationHistoryData(
      id: data.id.present ? data.id.value : this.id,
      idProduto: data.idProduto.present ? data.idProduto.value : this.idProduto,
      potenciaRef: data.potenciaRef.present
          ? data.potenciaRef.value
          : this.potenciaRef,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationHistoryData(')
          ..write('id: $id, ')
          ..write('idProduto: $idProduto, ')
          ..write('potenciaRef: $potenciaRef, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, idProduto, potenciaRef, deviceId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalibrationHistoryData &&
          other.id == this.id &&
          other.idProduto == this.idProduto &&
          other.potenciaRef == this.potenciaRef &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt);
}

class CalibrationHistoryCompanion
    extends UpdateCompanion<CalibrationHistoryData> {
  final Value<int> id;
  final Value<String> idProduto;
  final Value<double> potenciaRef;
  final Value<String?> deviceId;
  final Value<DateTime> createdAt;
  const CalibrationHistoryCompanion({
    this.id = const Value.absent(),
    this.idProduto = const Value.absent(),
    this.potenciaRef = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CalibrationHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String idProduto,
    required double potenciaRef,
    this.deviceId = const Value.absent(),
    required DateTime createdAt,
  }) : idProduto = Value(idProduto),
       potenciaRef = Value(potenciaRef),
       createdAt = Value(createdAt);
  static Insertable<CalibrationHistoryData> custom({
    Expression<int>? id,
    Expression<String>? idProduto,
    Expression<double>? potenciaRef,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idProduto != null) 'id_produto': idProduto,
      if (potenciaRef != null) 'potencia_ref': potenciaRef,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CalibrationHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? idProduto,
    Value<double>? potenciaRef,
    Value<String?>? deviceId,
    Value<DateTime>? createdAt,
  }) {
    return CalibrationHistoryCompanion(
      id: id ?? this.id,
      idProduto: idProduto ?? this.idProduto,
      potenciaRef: potenciaRef ?? this.potenciaRef,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idProduto.present) {
      map['id_produto'] = Variable<String>(idProduto.value);
    }
    if (potenciaRef.present) {
      map['potencia_ref'] = Variable<double>(potenciaRef.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationHistoryCompanion(')
          ..write('id: $id, ')
          ..write('idProduto: $idProduto, ')
          ..write('potenciaRef: $potenciaRef, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OpLocksTable extends OpLocks with TableInfo<$OpLocksTable, OpLock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpLocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numeroOpMeta = const VerificationMeta(
    'numeroOp',
  );
  @override
  late final GeneratedColumn<String> numeroOp = GeneratedColumn<String>(
    'numero_op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [numeroOp, status, lockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'op_locks';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpLock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('numero_op')) {
      context.handle(
        _numeroOpMeta,
        numeroOp.isAcceptableOrUnknown(data['numero_op']!, _numeroOpMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroOpMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {numeroOp};
  @override
  OpLock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpLock(
      numeroOp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_op'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      )!,
    );
  }

  @override
  $OpLocksTable createAlias(String alias) {
    return $OpLocksTable(attachedDatabase, alias);
  }
}

class OpLock extends DataClass implements Insertable<OpLock> {
  final String numeroOp;
  final String status;
  final DateTime lockedAt;
  const OpLock({
    required this.numeroOp,
    required this.status,
    required this.lockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['numero_op'] = Variable<String>(numeroOp);
    map['status'] = Variable<String>(status);
    map['locked_at'] = Variable<DateTime>(lockedAt);
    return map;
  }

  OpLocksCompanion toCompanion(bool nullToAbsent) {
    return OpLocksCompanion(
      numeroOp: Value(numeroOp),
      status: Value(status),
      lockedAt: Value(lockedAt),
    );
  }

  factory OpLock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpLock(
      numeroOp: serializer.fromJson<String>(json['numeroOp']),
      status: serializer.fromJson<String>(json['status']),
      lockedAt: serializer.fromJson<DateTime>(json['lockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'numeroOp': serializer.toJson<String>(numeroOp),
      'status': serializer.toJson<String>(status),
      'lockedAt': serializer.toJson<DateTime>(lockedAt),
    };
  }

  OpLock copyWith({String? numeroOp, String? status, DateTime? lockedAt}) =>
      OpLock(
        numeroOp: numeroOp ?? this.numeroOp,
        status: status ?? this.status,
        lockedAt: lockedAt ?? this.lockedAt,
      );
  OpLock copyWithCompanion(OpLocksCompanion data) {
    return OpLock(
      numeroOp: data.numeroOp.present ? data.numeroOp.value : this.numeroOp,
      status: data.status.present ? data.status.value : this.status,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpLock(')
          ..write('numeroOp: $numeroOp, ')
          ..write('status: $status, ')
          ..write('lockedAt: $lockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(numeroOp, status, lockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpLock &&
          other.numeroOp == this.numeroOp &&
          other.status == this.status &&
          other.lockedAt == this.lockedAt);
}

class OpLocksCompanion extends UpdateCompanion<OpLock> {
  final Value<String> numeroOp;
  final Value<String> status;
  final Value<DateTime> lockedAt;
  final Value<int> rowid;
  const OpLocksCompanion({
    this.numeroOp = const Value.absent(),
    this.status = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpLocksCompanion.insert({
    required String numeroOp,
    required String status,
    required DateTime lockedAt,
    this.rowid = const Value.absent(),
  }) : numeroOp = Value(numeroOp),
       status = Value(status),
       lockedAt = Value(lockedAt);
  static Insertable<OpLock> custom({
    Expression<String>? numeroOp,
    Expression<String>? status,
    Expression<DateTime>? lockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (numeroOp != null) 'numero_op': numeroOp,
      if (status != null) 'status': status,
      if (lockedAt != null) 'locked_at': lockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpLocksCompanion copyWith({
    Value<String>? numeroOp,
    Value<String>? status,
    Value<DateTime>? lockedAt,
    Value<int>? rowid,
  }) {
    return OpLocksCompanion(
      numeroOp: numeroOp ?? this.numeroOp,
      status: status ?? this.status,
      lockedAt: lockedAt ?? this.lockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (numeroOp.present) {
      map['numero_op'] = Variable<String>(numeroOp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpLocksCompanion(')
          ..write('numeroOp: $numeroOp, ')
          ..write('status: $status, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperatorsTable extends Operators
    with TableInfo<$OperatorsTable, Operator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
    'ativo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ativo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, codigo, nome, ativo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Operator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('ativo')) {
      context.handle(
        _ativoMeta,
        ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Operator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Operator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      ativo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ativo'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OperatorsTable createAlias(String alias) {
    return $OperatorsTable(attachedDatabase, alias);
  }
}

class Operator extends DataClass implements Insertable<Operator> {
  final int id;
  final String codigo;
  final String nome;
  final bool ativo;
  final DateTime createdAt;
  const Operator({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ativo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['codigo'] = Variable<String>(codigo);
    map['nome'] = Variable<String>(nome);
    map['ativo'] = Variable<bool>(ativo);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OperatorsCompanion toCompanion(bool nullToAbsent) {
    return OperatorsCompanion(
      id: Value(id),
      codigo: Value(codigo),
      nome: Value(nome),
      ativo: Value(ativo),
      createdAt: Value(createdAt),
    );
  }

  factory Operator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Operator(
      id: serializer.fromJson<int>(json['id']),
      codigo: serializer.fromJson<String>(json['codigo']),
      nome: serializer.fromJson<String>(json['nome']),
      ativo: serializer.fromJson<bool>(json['ativo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'codigo': serializer.toJson<String>(codigo),
      'nome': serializer.toJson<String>(nome),
      'ativo': serializer.toJson<bool>(ativo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Operator copyWith({
    int? id,
    String? codigo,
    String? nome,
    bool? ativo,
    DateTime? createdAt,
  }) => Operator(
    id: id ?? this.id,
    codigo: codigo ?? this.codigo,
    nome: nome ?? this.nome,
    ativo: ativo ?? this.ativo,
    createdAt: createdAt ?? this.createdAt,
  );
  Operator copyWithCompanion(OperatorsCompanion data) {
    return Operator(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nome: data.nome.present ? data.nome.value : this.nome,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Operator(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, codigo, nome, ativo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Operator &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.nome == this.nome &&
          other.ativo == this.ativo &&
          other.createdAt == this.createdAt);
}

class OperatorsCompanion extends UpdateCompanion<Operator> {
  final Value<int> id;
  final Value<String> codigo;
  final Value<String> nome;
  final Value<bool> ativo;
  final Value<DateTime> createdAt;
  const OperatorsCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nome = const Value.absent(),
    this.ativo = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OperatorsCompanion.insert({
    this.id = const Value.absent(),
    required String codigo,
    required String nome,
    this.ativo = const Value.absent(),
    required DateTime createdAt,
  }) : codigo = Value(codigo),
       nome = Value(nome),
       createdAt = Value(createdAt);
  static Insertable<Operator> custom({
    Expression<int>? id,
    Expression<String>? codigo,
    Expression<String>? nome,
    Expression<bool>? ativo,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (nome != null) 'nome': nome,
      if (ativo != null) 'ativo': ativo,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OperatorsCompanion copyWith({
    Value<int>? id,
    Value<String>? codigo,
    Value<String>? nome,
    Value<bool>? ativo,
    Value<DateTime>? createdAt,
  }) {
    return OperatorsCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatorsCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TestResultsTable testResults = $TestResultsTable(this);
  late final $LabelBufferEntriesTable labelBufferEntries =
      $LabelBufferEntriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SerialCountersTable serialCounters = $SerialCountersTable(this);
  late final $HardwareEventsTable hardwareEvents = $HardwareEventsTable(this);
  late final $CalibrationHistoryTable calibrationHistory =
      $CalibrationHistoryTable(this);
  late final $OpLocksTable opLocks = $OpLocksTable(this);
  late final $OperatorsTable operators = $OperatorsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    testResults,
    labelBufferEntries,
    products,
    syncQueue,
    serialCounters,
    hardwareEvents,
    calibrationHistory,
    opLocks,
    operators,
  ];
}

typedef $$TestResultsTableCreateCompanionBuilder =
    TestResultsCompanion Function({
      Value<int> id,
      required String deviceId,
      required String numeroOp,
      required String veredito,
      required double potenciaMedia,
      required int sequencial,
      required int aprovadosNoLote,
      Value<String?> serial,
      Value<String?> operador,
      required DateTime createdAt,
    });
typedef $$TestResultsTableUpdateCompanionBuilder =
    TestResultsCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String> numeroOp,
      Value<String> veredito,
      Value<double> potenciaMedia,
      Value<int> sequencial,
      Value<int> aprovadosNoLote,
      Value<String?> serial,
      Value<String?> operador,
      Value<DateTime> createdAt,
    });

class $$TestResultsTableFilterComposer
    extends Composer<_$AppDatabase, $TestResultsTable> {
  $$TestResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get veredito => $composableBuilder(
    column: $table.veredito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potenciaMedia => $composableBuilder(
    column: $table.potenciaMedia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequencial => $composableBuilder(
    column: $table.sequencial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aprovadosNoLote => $composableBuilder(
    column: $table.aprovadosNoLote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operador => $composableBuilder(
    column: $table.operador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TestResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $TestResultsTable> {
  $$TestResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get veredito => $composableBuilder(
    column: $table.veredito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potenciaMedia => $composableBuilder(
    column: $table.potenciaMedia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequencial => $composableBuilder(
    column: $table.sequencial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aprovadosNoLote => $composableBuilder(
    column: $table.aprovadosNoLote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operador => $composableBuilder(
    column: $table.operador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TestResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TestResultsTable> {
  $$TestResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get numeroOp =>
      $composableBuilder(column: $table.numeroOp, builder: (column) => column);

  GeneratedColumn<String> get veredito =>
      $composableBuilder(column: $table.veredito, builder: (column) => column);

  GeneratedColumn<double> get potenciaMedia => $composableBuilder(
    column: $table.potenciaMedia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequencial => $composableBuilder(
    column: $table.sequencial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aprovadosNoLote => $composableBuilder(
    column: $table.aprovadosNoLote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get operador =>
      $composableBuilder(column: $table.operador, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TestResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TestResultsTable,
          TestResult,
          $$TestResultsTableFilterComposer,
          $$TestResultsTableOrderingComposer,
          $$TestResultsTableAnnotationComposer,
          $$TestResultsTableCreateCompanionBuilder,
          $$TestResultsTableUpdateCompanionBuilder,
          (
            TestResult,
            BaseReferences<_$AppDatabase, $TestResultsTable, TestResult>,
          ),
          TestResult,
          PrefetchHooks Function()
        > {
  $$TestResultsTableTableManager(_$AppDatabase db, $TestResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> numeroOp = const Value.absent(),
                Value<String> veredito = const Value.absent(),
                Value<double> potenciaMedia = const Value.absent(),
                Value<int> sequencial = const Value.absent(),
                Value<int> aprovadosNoLote = const Value.absent(),
                Value<String?> serial = const Value.absent(),
                Value<String?> operador = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TestResultsCompanion(
                id: id,
                deviceId: deviceId,
                numeroOp: numeroOp,
                veredito: veredito,
                potenciaMedia: potenciaMedia,
                sequencial: sequencial,
                aprovadosNoLote: aprovadosNoLote,
                serial: serial,
                operador: operador,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                required String numeroOp,
                required String veredito,
                required double potenciaMedia,
                required int sequencial,
                required int aprovadosNoLote,
                Value<String?> serial = const Value.absent(),
                Value<String?> operador = const Value.absent(),
                required DateTime createdAt,
              }) => TestResultsCompanion.insert(
                id: id,
                deviceId: deviceId,
                numeroOp: numeroOp,
                veredito: veredito,
                potenciaMedia: potenciaMedia,
                sequencial: sequencial,
                aprovadosNoLote: aprovadosNoLote,
                serial: serial,
                operador: operador,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TestResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TestResultsTable,
      TestResult,
      $$TestResultsTableFilterComposer,
      $$TestResultsTableOrderingComposer,
      $$TestResultsTableAnnotationComposer,
      $$TestResultsTableCreateCompanionBuilder,
      $$TestResultsTableUpdateCompanionBuilder,
      (
        TestResult,
        BaseReferences<_$AppDatabase, $TestResultsTable, TestResult>,
      ),
      TestResult,
      PrefetchHooks Function()
    >;
typedef $$LabelBufferEntriesTableCreateCompanionBuilder =
    LabelBufferEntriesCompanion Function({
      Value<int> id,
      required String serial,
      required String numeroOp,
      required DateTime createdAt,
    });
typedef $$LabelBufferEntriesTableUpdateCompanionBuilder =
    LabelBufferEntriesCompanion Function({
      Value<int> id,
      Value<String> serial,
      Value<String> numeroOp,
      Value<DateTime> createdAt,
    });

class $$LabelBufferEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LabelBufferEntriesTable> {
  $$LabelBufferEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LabelBufferEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LabelBufferEntriesTable> {
  $$LabelBufferEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabelBufferEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabelBufferEntriesTable> {
  $$LabelBufferEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get numeroOp =>
      $composableBuilder(column: $table.numeroOp, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LabelBufferEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabelBufferEntriesTable,
          LabelBufferEntry,
          $$LabelBufferEntriesTableFilterComposer,
          $$LabelBufferEntriesTableOrderingComposer,
          $$LabelBufferEntriesTableAnnotationComposer,
          $$LabelBufferEntriesTableCreateCompanionBuilder,
          $$LabelBufferEntriesTableUpdateCompanionBuilder,
          (
            LabelBufferEntry,
            BaseReferences<
              _$AppDatabase,
              $LabelBufferEntriesTable,
              LabelBufferEntry
            >,
          ),
          LabelBufferEntry,
          PrefetchHooks Function()
        > {
  $$LabelBufferEntriesTableTableManager(
    _$AppDatabase db,
    $LabelBufferEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabelBufferEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabelBufferEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabelBufferEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serial = const Value.absent(),
                Value<String> numeroOp = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LabelBufferEntriesCompanion(
                id: id,
                serial: serial,
                numeroOp: numeroOp,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serial,
                required String numeroOp,
                required DateTime createdAt,
              }) => LabelBufferEntriesCompanion.insert(
                id: id,
                serial: serial,
                numeroOp: numeroOp,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LabelBufferEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabelBufferEntriesTable,
      LabelBufferEntry,
      $$LabelBufferEntriesTableFilterComposer,
      $$LabelBufferEntriesTableOrderingComposer,
      $$LabelBufferEntriesTableAnnotationComposer,
      $$LabelBufferEntriesTableCreateCompanionBuilder,
      $$LabelBufferEntriesTableUpdateCompanionBuilder,
      (
        LabelBufferEntry,
        BaseReferences<
          _$AppDatabase,
          $LabelBufferEntriesTable,
          LabelBufferEntry
        >,
      ),
      LabelBufferEntry,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String idProduto,
      required String nome,
      required double potenciaRef,
      required double potenciaMin,
      required double potenciaMax,
      Value<double> toleranciaPct,
      Value<int> tempoTesteSec,
      Value<DateTime?> calibradoEm,
      Value<String?> calibradoDeviceId,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> idProduto,
      Value<String> nome,
      Value<double> potenciaRef,
      Value<double> potenciaMin,
      Value<double> potenciaMax,
      Value<double> toleranciaPct,
      Value<int> tempoTesteSec,
      Value<DateTime?> calibradoEm,
      Value<String?> calibradoDeviceId,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potenciaMin => $composableBuilder(
    column: $table.potenciaMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potenciaMax => $composableBuilder(
    column: $table.potenciaMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get toleranciaPct => $composableBuilder(
    column: $table.toleranciaPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tempoTesteSec => $composableBuilder(
    column: $table.tempoTesteSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get calibradoEm => $composableBuilder(
    column: $table.calibradoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibradoDeviceId => $composableBuilder(
    column: $table.calibradoDeviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potenciaMin => $composableBuilder(
    column: $table.potenciaMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potenciaMax => $composableBuilder(
    column: $table.potenciaMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get toleranciaPct => $composableBuilder(
    column: $table.toleranciaPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tempoTesteSec => $composableBuilder(
    column: $table.tempoTesteSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get calibradoEm => $composableBuilder(
    column: $table.calibradoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibradoDeviceId => $composableBuilder(
    column: $table.calibradoDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idProduto =>
      $composableBuilder(column: $table.idProduto, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => column,
  );

  GeneratedColumn<double> get potenciaMin => $composableBuilder(
    column: $table.potenciaMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get potenciaMax => $composableBuilder(
    column: $table.potenciaMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get toleranciaPct => $composableBuilder(
    column: $table.toleranciaPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tempoTesteSec => $composableBuilder(
    column: $table.tempoTesteSec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get calibradoEm => $composableBuilder(
    column: $table.calibradoEm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calibradoDeviceId => $composableBuilder(
    column: $table.calibradoDeviceId,
    builder: (column) => column,
  );
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idProduto = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<double> potenciaRef = const Value.absent(),
                Value<double> potenciaMin = const Value.absent(),
                Value<double> potenciaMax = const Value.absent(),
                Value<double> toleranciaPct = const Value.absent(),
                Value<int> tempoTesteSec = const Value.absent(),
                Value<DateTime?> calibradoEm = const Value.absent(),
                Value<String?> calibradoDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                idProduto: idProduto,
                nome: nome,
                potenciaRef: potenciaRef,
                potenciaMin: potenciaMin,
                potenciaMax: potenciaMax,
                toleranciaPct: toleranciaPct,
                tempoTesteSec: tempoTesteSec,
                calibradoEm: calibradoEm,
                calibradoDeviceId: calibradoDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idProduto,
                required String nome,
                required double potenciaRef,
                required double potenciaMin,
                required double potenciaMax,
                Value<double> toleranciaPct = const Value.absent(),
                Value<int> tempoTesteSec = const Value.absent(),
                Value<DateTime?> calibradoEm = const Value.absent(),
                Value<String?> calibradoDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                idProduto: idProduto,
                nome: nome,
                potenciaRef: potenciaRef,
                potenciaMin: potenciaMin,
                potenciaMax: potenciaMax,
                toleranciaPct: toleranciaPct,
                tempoTesteSec: tempoTesteSec,
                calibradoEm: calibradoEm,
                calibradoDeviceId: calibradoDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String collection,
      required String documentId,
      required String payload,
      required String operation,
      required DateTime createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> collection,
      Value<String> documentId,
      Value<String> payload,
      Value<String> operation,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                collection: collection,
                documentId: documentId,
                payload: payload,
                operation: operation,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String collection,
                required String documentId,
                required String payload,
                required String operation,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                collection: collection,
                documentId: documentId,
                payload: payload,
                operation: operation,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$SerialCountersTableCreateCompanionBuilder =
    SerialCountersCompanion Function({
      required String idProduto,
      required String ano,
      required int lastSequencial,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SerialCountersTableUpdateCompanionBuilder =
    SerialCountersCompanion Function({
      Value<String> idProduto,
      Value<String> ano,
      Value<int> lastSequencial,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SerialCountersTableFilterComposer
    extends Composer<_$AppDatabase, $SerialCountersTable> {
  $$SerialCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ano => $composableBuilder(
    column: $table.ano,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSequencial => $composableBuilder(
    column: $table.lastSequencial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SerialCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $SerialCountersTable> {
  $$SerialCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ano => $composableBuilder(
    column: $table.ano,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSequencial => $composableBuilder(
    column: $table.lastSequencial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SerialCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SerialCountersTable> {
  $$SerialCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idProduto =>
      $composableBuilder(column: $table.idProduto, builder: (column) => column);

  GeneratedColumn<String> get ano =>
      $composableBuilder(column: $table.ano, builder: (column) => column);

  GeneratedColumn<int> get lastSequencial => $composableBuilder(
    column: $table.lastSequencial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SerialCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SerialCountersTable,
          SerialCounter,
          $$SerialCountersTableFilterComposer,
          $$SerialCountersTableOrderingComposer,
          $$SerialCountersTableAnnotationComposer,
          $$SerialCountersTableCreateCompanionBuilder,
          $$SerialCountersTableUpdateCompanionBuilder,
          (
            SerialCounter,
            BaseReferences<_$AppDatabase, $SerialCountersTable, SerialCounter>,
          ),
          SerialCounter,
          PrefetchHooks Function()
        > {
  $$SerialCountersTableTableManager(
    _$AppDatabase db,
    $SerialCountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SerialCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SerialCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SerialCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idProduto = const Value.absent(),
                Value<String> ano = const Value.absent(),
                Value<int> lastSequencial = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SerialCountersCompanion(
                idProduto: idProduto,
                ano: ano,
                lastSequencial: lastSequencial,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idProduto,
                required String ano,
                required int lastSequencial,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SerialCountersCompanion.insert(
                idProduto: idProduto,
                ano: ano,
                lastSequencial: lastSequencial,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SerialCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SerialCountersTable,
      SerialCounter,
      $$SerialCountersTableFilterComposer,
      $$SerialCountersTableOrderingComposer,
      $$SerialCountersTableAnnotationComposer,
      $$SerialCountersTableCreateCompanionBuilder,
      $$SerialCountersTableUpdateCompanionBuilder,
      (
        SerialCounter,
        BaseReferences<_$AppDatabase, $SerialCountersTable, SerialCounter>,
      ),
      SerialCounter,
      PrefetchHooks Function()
    >;
typedef $$HardwareEventsTableCreateCompanionBuilder =
    HardwareEventsCompanion Function({
      Value<int> id,
      required String deviceId,
      required String falha,
      required DateTime createdAt,
    });
typedef $$HardwareEventsTableUpdateCompanionBuilder =
    HardwareEventsCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String> falha,
      Value<DateTime> createdAt,
    });

class $$HardwareEventsTableFilterComposer
    extends Composer<_$AppDatabase, $HardwareEventsTable> {
  $$HardwareEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get falha => $composableBuilder(
    column: $table.falha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HardwareEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $HardwareEventsTable> {
  $$HardwareEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get falha => $composableBuilder(
    column: $table.falha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HardwareEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HardwareEventsTable> {
  $$HardwareEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get falha =>
      $composableBuilder(column: $table.falha, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HardwareEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HardwareEventsTable,
          HardwareEvent,
          $$HardwareEventsTableFilterComposer,
          $$HardwareEventsTableOrderingComposer,
          $$HardwareEventsTableAnnotationComposer,
          $$HardwareEventsTableCreateCompanionBuilder,
          $$HardwareEventsTableUpdateCompanionBuilder,
          (
            HardwareEvent,
            BaseReferences<_$AppDatabase, $HardwareEventsTable, HardwareEvent>,
          ),
          HardwareEvent,
          PrefetchHooks Function()
        > {
  $$HardwareEventsTableTableManager(
    _$AppDatabase db,
    $HardwareEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HardwareEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HardwareEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HardwareEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> falha = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HardwareEventsCompanion(
                id: id,
                deviceId: deviceId,
                falha: falha,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                required String falha,
                required DateTime createdAt,
              }) => HardwareEventsCompanion.insert(
                id: id,
                deviceId: deviceId,
                falha: falha,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HardwareEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HardwareEventsTable,
      HardwareEvent,
      $$HardwareEventsTableFilterComposer,
      $$HardwareEventsTableOrderingComposer,
      $$HardwareEventsTableAnnotationComposer,
      $$HardwareEventsTableCreateCompanionBuilder,
      $$HardwareEventsTableUpdateCompanionBuilder,
      (
        HardwareEvent,
        BaseReferences<_$AppDatabase, $HardwareEventsTable, HardwareEvent>,
      ),
      HardwareEvent,
      PrefetchHooks Function()
    >;
typedef $$CalibrationHistoryTableCreateCompanionBuilder =
    CalibrationHistoryCompanion Function({
      Value<int> id,
      required String idProduto,
      required double potenciaRef,
      Value<String?> deviceId,
      required DateTime createdAt,
    });
typedef $$CalibrationHistoryTableUpdateCompanionBuilder =
    CalibrationHistoryCompanion Function({
      Value<int> id,
      Value<String> idProduto,
      Value<double> potenciaRef,
      Value<String?> deviceId,
      Value<DateTime> createdAt,
    });

class $$CalibrationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $CalibrationHistoryTable> {
  $$CalibrationHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalibrationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $CalibrationHistoryTable> {
  $$CalibrationHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idProduto => $composableBuilder(
    column: $table.idProduto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalibrationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalibrationHistoryTable> {
  $$CalibrationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idProduto =>
      $composableBuilder(column: $table.idProduto, builder: (column) => column);

  GeneratedColumn<double> get potenciaRef => $composableBuilder(
    column: $table.potenciaRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CalibrationHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalibrationHistoryTable,
          CalibrationHistoryData,
          $$CalibrationHistoryTableFilterComposer,
          $$CalibrationHistoryTableOrderingComposer,
          $$CalibrationHistoryTableAnnotationComposer,
          $$CalibrationHistoryTableCreateCompanionBuilder,
          $$CalibrationHistoryTableUpdateCompanionBuilder,
          (
            CalibrationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $CalibrationHistoryTable,
              CalibrationHistoryData
            >,
          ),
          CalibrationHistoryData,
          PrefetchHooks Function()
        > {
  $$CalibrationHistoryTableTableManager(
    _$AppDatabase db,
    $CalibrationHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalibrationHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalibrationHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalibrationHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> idProduto = const Value.absent(),
                Value<double> potenciaRef = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CalibrationHistoryCompanion(
                id: id,
                idProduto: idProduto,
                potenciaRef: potenciaRef,
                deviceId: deviceId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String idProduto,
                required double potenciaRef,
                Value<String?> deviceId = const Value.absent(),
                required DateTime createdAt,
              }) => CalibrationHistoryCompanion.insert(
                id: id,
                idProduto: idProduto,
                potenciaRef: potenciaRef,
                deviceId: deviceId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalibrationHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalibrationHistoryTable,
      CalibrationHistoryData,
      $$CalibrationHistoryTableFilterComposer,
      $$CalibrationHistoryTableOrderingComposer,
      $$CalibrationHistoryTableAnnotationComposer,
      $$CalibrationHistoryTableCreateCompanionBuilder,
      $$CalibrationHistoryTableUpdateCompanionBuilder,
      (
        CalibrationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $CalibrationHistoryTable,
          CalibrationHistoryData
        >,
      ),
      CalibrationHistoryData,
      PrefetchHooks Function()
    >;
typedef $$OpLocksTableCreateCompanionBuilder =
    OpLocksCompanion Function({
      required String numeroOp,
      required String status,
      required DateTime lockedAt,
      Value<int> rowid,
    });
typedef $$OpLocksTableUpdateCompanionBuilder =
    OpLocksCompanion Function({
      Value<String> numeroOp,
      Value<String> status,
      Value<DateTime> lockedAt,
      Value<int> rowid,
    });

class $$OpLocksTableFilterComposer
    extends Composer<_$AppDatabase, $OpLocksTable> {
  $$OpLocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpLocksTableOrderingComposer
    extends Composer<_$AppDatabase, $OpLocksTable> {
  $$OpLocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpLocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $OpLocksTable> {
  $$OpLocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get numeroOp =>
      $composableBuilder(column: $table.numeroOp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);
}

class $$OpLocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpLocksTable,
          OpLock,
          $$OpLocksTableFilterComposer,
          $$OpLocksTableOrderingComposer,
          $$OpLocksTableAnnotationComposer,
          $$OpLocksTableCreateCompanionBuilder,
          $$OpLocksTableUpdateCompanionBuilder,
          (OpLock, BaseReferences<_$AppDatabase, $OpLocksTable, OpLock>),
          OpLock,
          PrefetchHooks Function()
        > {
  $$OpLocksTableTableManager(_$AppDatabase db, $OpLocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpLocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpLocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpLocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> numeroOp = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> lockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpLocksCompanion(
                numeroOp: numeroOp,
                status: status,
                lockedAt: lockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String numeroOp,
                required String status,
                required DateTime lockedAt,
                Value<int> rowid = const Value.absent(),
              }) => OpLocksCompanion.insert(
                numeroOp: numeroOp,
                status: status,
                lockedAt: lockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpLocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpLocksTable,
      OpLock,
      $$OpLocksTableFilterComposer,
      $$OpLocksTableOrderingComposer,
      $$OpLocksTableAnnotationComposer,
      $$OpLocksTableCreateCompanionBuilder,
      $$OpLocksTableUpdateCompanionBuilder,
      (OpLock, BaseReferences<_$AppDatabase, $OpLocksTable, OpLock>),
      OpLock,
      PrefetchHooks Function()
    >;
typedef $$OperatorsTableCreateCompanionBuilder =
    OperatorsCompanion Function({
      Value<int> id,
      required String codigo,
      required String nome,
      Value<bool> ativo,
      required DateTime createdAt,
    });
typedef $$OperatorsTableUpdateCompanionBuilder =
    OperatorsCompanion Function({
      Value<int> id,
      Value<String> codigo,
      Value<String> nome,
      Value<bool> ativo,
      Value<DateTime> createdAt,
    });

class $$OperatorsTableFilterComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperatorsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ativo => $composableBuilder(
    column: $table.ativo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperatorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperatorsTable> {
  $$OperatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OperatorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperatorsTable,
          Operator,
          $$OperatorsTableFilterComposer,
          $$OperatorsTableOrderingComposer,
          $$OperatorsTableAnnotationComposer,
          $$OperatorsTableCreateCompanionBuilder,
          $$OperatorsTableUpdateCompanionBuilder,
          (Operator, BaseReferences<_$AppDatabase, $OperatorsTable, Operator>),
          Operator,
          PrefetchHooks Function()
        > {
  $$OperatorsTableTableManager(_$AppDatabase db, $OperatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<bool> ativo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OperatorsCompanion(
                id: id,
                codigo: codigo,
                nome: nome,
                ativo: ativo,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String codigo,
                required String nome,
                Value<bool> ativo = const Value.absent(),
                required DateTime createdAt,
              }) => OperatorsCompanion.insert(
                id: id,
                codigo: codigo,
                nome: nome,
                ativo: ativo,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperatorsTable,
      Operator,
      $$OperatorsTableFilterComposer,
      $$OperatorsTableOrderingComposer,
      $$OperatorsTableAnnotationComposer,
      $$OperatorsTableCreateCompanionBuilder,
      $$OperatorsTableUpdateCompanionBuilder,
      (Operator, BaseReferences<_$AppDatabase, $OperatorsTable, Operator>),
      Operator,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TestResultsTableTableManager get testResults =>
      $$TestResultsTableTableManager(_db, _db.testResults);
  $$LabelBufferEntriesTableTableManager get labelBufferEntries =>
      $$LabelBufferEntriesTableTableManager(_db, _db.labelBufferEntries);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SerialCountersTableTableManager get serialCounters =>
      $$SerialCountersTableTableManager(_db, _db.serialCounters);
  $$HardwareEventsTableTableManager get hardwareEvents =>
      $$HardwareEventsTableTableManager(_db, _db.hardwareEvents);
  $$CalibrationHistoryTableTableManager get calibrationHistory =>
      $$CalibrationHistoryTableTableManager(_db, _db.calibrationHistory);
  $$OpLocksTableTableManager get opLocks =>
      $$OpLocksTableTableManager(_db, _db.opLocks);
  $$OperatorsTableTableManager get operators =>
      $$OperatorsTableTableManager(_db, _db.operators);
}
