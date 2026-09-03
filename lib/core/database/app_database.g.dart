// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bikeNameMeta = const VerificationMeta(
    'bikeName',
  );
  @override
  late final GeneratedColumn<String> bikeName = GeneratedColumn<String>(
    'bike_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgSpeedKmhMeta = const VerificationMeta(
    'avgSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> avgSpeedKmh = GeneratedColumn<double>(
    'avg_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxSpeedKmhMeta = const VerificationMeta(
    'maxSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> maxSpeedKmh = GeneratedColumn<double>(
    'max_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationGainMetersMeta =
      const VerificationMeta('elevationGainMeters');
  @override
  late final GeneratedColumn<double> elevationGainMeters =
      GeneratedColumn<double>(
        'elevation_gain_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _avgHeartRateMeta = const VerificationMeta(
    'avgHeartRate',
  );
  @override
  late final GeneratedColumn<int> avgHeartRate = GeneratedColumn<int>(
    'avg_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHeartRateMeta = const VerificationMeta(
    'maxHeartRate',
  );
  @override
  late final GeneratedColumn<int> maxHeartRate = GeneratedColumn<int>(
    'max_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgPowerMeta = const VerificationMeta(
    'avgPower',
  );
  @override
  late final GeneratedColumn<int> avgPower = GeneratedColumn<int>(
    'avg_power',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxPowerMeta = const VerificationMeta(
    'maxPower',
  );
  @override
  late final GeneratedColumn<int> maxPower = GeneratedColumn<int>(
    'max_power',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgCadenceMeta = const VerificationMeta(
    'avgCadence',
  );
  @override
  late final GeneratedColumn<int> avgCadence = GeneratedColumn<int>(
    'avg_cadence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxCadenceMeta = const VerificationMeta(
    'maxCadence',
  );
  @override
  late final GeneratedColumn<int> maxCadence = GeneratedColumn<int>(
    'max_cadence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routePointsJsonMeta = const VerificationMeta(
    'routePointsJson',
  );
  @override
  late final GeneratedColumn<String> routePointsJson = GeneratedColumn<String>(
    'route_points_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _photoPathsJsonMeta = const VerificationMeta(
    'photoPathsJson',
  );
  @override
  late final GeneratedColumn<String> photoPathsJson = GeneratedColumn<String>(
    'photo_paths_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    activityType,
    bikeName,
    startedAt,
    endedAt,
    durationSeconds,
    distanceMeters,
    avgSpeedKmh,
    maxSpeedKmh,
    elevationGainMeters,
    avgHeartRate,
    maxHeartRate,
    avgPower,
    maxPower,
    avgCadence,
    maxCadence,
    notes,
    routePointsJson,
    photoPathsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('bike_name')) {
      context.handle(
        _bikeNameMeta,
        bikeName.isAcceptableOrUnknown(data['bike_name']!, _bikeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bikeNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('avg_speed_kmh')) {
      context.handle(
        _avgSpeedKmhMeta,
        avgSpeedKmh.isAcceptableOrUnknown(
          data['avg_speed_kmh']!,
          _avgSpeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgSpeedKmhMeta);
    }
    if (data.containsKey('max_speed_kmh')) {
      context.handle(
        _maxSpeedKmhMeta,
        maxSpeedKmh.isAcceptableOrUnknown(
          data['max_speed_kmh']!,
          _maxSpeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxSpeedKmhMeta);
    }
    if (data.containsKey('elevation_gain_meters')) {
      context.handle(
        _elevationGainMetersMeta,
        elevationGainMeters.isAcceptableOrUnknown(
          data['elevation_gain_meters']!,
          _elevationGainMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationGainMetersMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
        _avgHeartRateMeta,
        avgHeartRate.isAcceptableOrUnknown(
          data['avg_heart_rate']!,
          _avgHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
        _maxHeartRateMeta,
        maxHeartRate.isAcceptableOrUnknown(
          data['max_heart_rate']!,
          _maxHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('avg_power')) {
      context.handle(
        _avgPowerMeta,
        avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta),
      );
    }
    if (data.containsKey('max_power')) {
      context.handle(
        _maxPowerMeta,
        maxPower.isAcceptableOrUnknown(data['max_power']!, _maxPowerMeta),
      );
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
        _avgCadenceMeta,
        avgCadence.isAcceptableOrUnknown(data['avg_cadence']!, _avgCadenceMeta),
      );
    }
    if (data.containsKey('max_cadence')) {
      context.handle(
        _maxCadenceMeta,
        maxCadence.isAcceptableOrUnknown(data['max_cadence']!, _maxCadenceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('route_points_json')) {
      context.handle(
        _routePointsJsonMeta,
        routePointsJson.isAcceptableOrUnknown(
          data['route_points_json']!,
          _routePointsJsonMeta,
        ),
      );
    }
    if (data.containsKey('photo_paths_json')) {
      context.handle(
        _photoPathsJsonMeta,
        photoPathsJson.isAcceptableOrUnknown(
          data['photo_paths_json']!,
          _photoPathsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
      bikeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bike_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      avgSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed_kmh'],
      )!,
      maxSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed_kmh'],
      )!,
      elevationGainMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_meters'],
      )!,
      avgHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_heart_rate'],
      ),
      maxHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_heart_rate'],
      ),
      avgPower: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_power'],
      ),
      maxPower: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_power'],
      ),
      avgCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_cadence'],
      ),
      maxCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_cadence'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      routePointsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_points_json'],
      )!,
      photoPathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_paths_json'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final int id;
  final String title;

  /// 'race' o 'training'.
  final String activityType;
  final String bikeName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainMeters;
  final int? avgHeartRate;
  final int? maxHeartRate;

  /// Null si no hubo medidor de potencia conectado durante la grabación.
  final int? avgPower;
  final int? maxPower;

  /// Cadencia redondeada a RPM entero para el resumen -- el detalle por
  /// punto (RoutePointSnapshot) sí guarda el valor sin redondear.
  final int? avgCadence;
  final int? maxCadence;
  final String? notes;
  final String routePointsJson;
  final String photoPathsJson;
  const Activity({
    required this.id,
    required this.title,
    required this.activityType,
    required this.bikeName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPower,
    this.maxPower,
    this.avgCadence,
    this.maxCadence,
    this.notes,
    required this.routePointsJson,
    required this.photoPathsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['activity_type'] = Variable<String>(activityType);
    map['bike_name'] = Variable<String>(bikeName);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh);
    map['max_speed_kmh'] = Variable<double>(maxSpeedKmh);
    map['elevation_gain_meters'] = Variable<double>(elevationGainMeters);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate);
    }
    if (!nullToAbsent || avgPower != null) {
      map['avg_power'] = Variable<int>(avgPower);
    }
    if (!nullToAbsent || maxPower != null) {
      map['max_power'] = Variable<int>(maxPower);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<int>(avgCadence);
    }
    if (!nullToAbsent || maxCadence != null) {
      map['max_cadence'] = Variable<int>(maxCadence);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['route_points_json'] = Variable<String>(routePointsJson);
    map['photo_paths_json'] = Variable<String>(photoPathsJson);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      title: Value(title),
      activityType: Value(activityType),
      bikeName: Value(bikeName),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      durationSeconds: Value(durationSeconds),
      distanceMeters: Value(distanceMeters),
      avgSpeedKmh: Value(avgSpeedKmh),
      maxSpeedKmh: Value(maxSpeedKmh),
      elevationGainMeters: Value(elevationGainMeters),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      avgPower: avgPower == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPower),
      maxPower: maxPower == null && nullToAbsent
          ? const Value.absent()
          : Value(maxPower),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      maxCadence: maxCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(maxCadence),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      routePointsJson: Value(routePointsJson),
      photoPathsJson: Value(photoPathsJson),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      activityType: serializer.fromJson<String>(json['activityType']),
      bikeName: serializer.fromJson<String>(json['bikeName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      avgSpeedKmh: serializer.fromJson<double>(json['avgSpeedKmh']),
      maxSpeedKmh: serializer.fromJson<double>(json['maxSpeedKmh']),
      elevationGainMeters: serializer.fromJson<double>(
        json['elevationGainMeters'],
      ),
      avgHeartRate: serializer.fromJson<int?>(json['avgHeartRate']),
      maxHeartRate: serializer.fromJson<int?>(json['maxHeartRate']),
      avgPower: serializer.fromJson<int?>(json['avgPower']),
      maxPower: serializer.fromJson<int?>(json['maxPower']),
      avgCadence: serializer.fromJson<int?>(json['avgCadence']),
      maxCadence: serializer.fromJson<int?>(json['maxCadence']),
      notes: serializer.fromJson<String?>(json['notes']),
      routePointsJson: serializer.fromJson<String>(json['routePointsJson']),
      photoPathsJson: serializer.fromJson<String>(json['photoPathsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'activityType': serializer.toJson<String>(activityType),
      'bikeName': serializer.toJson<String>(bikeName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'avgSpeedKmh': serializer.toJson<double>(avgSpeedKmh),
      'maxSpeedKmh': serializer.toJson<double>(maxSpeedKmh),
      'elevationGainMeters': serializer.toJson<double>(elevationGainMeters),
      'avgHeartRate': serializer.toJson<int?>(avgHeartRate),
      'maxHeartRate': serializer.toJson<int?>(maxHeartRate),
      'avgPower': serializer.toJson<int?>(avgPower),
      'maxPower': serializer.toJson<int?>(maxPower),
      'avgCadence': serializer.toJson<int?>(avgCadence),
      'maxCadence': serializer.toJson<int?>(maxCadence),
      'notes': serializer.toJson<String?>(notes),
      'routePointsJson': serializer.toJson<String>(routePointsJson),
      'photoPathsJson': serializer.toJson<String>(photoPathsJson),
    };
  }

  Activity copyWith({
    int? id,
    String? title,
    String? activityType,
    String? bikeName,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    double? distanceMeters,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    double? elevationGainMeters,
    Value<int?> avgHeartRate = const Value.absent(),
    Value<int?> maxHeartRate = const Value.absent(),
    Value<int?> avgPower = const Value.absent(),
    Value<int?> maxPower = const Value.absent(),
    Value<int?> avgCadence = const Value.absent(),
    Value<int?> maxCadence = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? routePointsJson,
    String? photoPathsJson,
  }) => Activity(
    id: id ?? this.id,
    title: title ?? this.title,
    activityType: activityType ?? this.activityType,
    bikeName: bikeName ?? this.bikeName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
    elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
    avgHeartRate: avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
    maxHeartRate: maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
    avgPower: avgPower.present ? avgPower.value : this.avgPower,
    maxPower: maxPower.present ? maxPower.value : this.maxPower,
    avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
    maxCadence: maxCadence.present ? maxCadence.value : this.maxCadence,
    notes: notes.present ? notes.value : this.notes,
    routePointsJson: routePointsJson ?? this.routePointsJson,
    photoPathsJson: photoPathsJson ?? this.photoPathsJson,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      bikeName: data.bikeName.present ? data.bikeName.value : this.bikeName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      avgSpeedKmh: data.avgSpeedKmh.present
          ? data.avgSpeedKmh.value
          : this.avgSpeedKmh,
      maxSpeedKmh: data.maxSpeedKmh.present
          ? data.maxSpeedKmh.value
          : this.maxSpeedKmh,
      elevationGainMeters: data.elevationGainMeters.present
          ? data.elevationGainMeters.value
          : this.elevationGainMeters,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      maxPower: data.maxPower.present ? data.maxPower.value : this.maxPower,
      avgCadence: data.avgCadence.present
          ? data.avgCadence.value
          : this.avgCadence,
      maxCadence: data.maxCadence.present
          ? data.maxCadence.value
          : this.maxCadence,
      notes: data.notes.present ? data.notes.value : this.notes,
      routePointsJson: data.routePointsJson.present
          ? data.routePointsJson.value
          : this.routePointsJson,
      photoPathsJson: data.photoPathsJson.present
          ? data.photoPathsJson.value
          : this.photoPathsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('activityType: $activityType, ')
          ..write('bikeName: $bikeName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('maxSpeedKmh: $maxSpeedKmh, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('maxPower: $maxPower, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('maxCadence: $maxCadence, ')
          ..write('notes: $notes, ')
          ..write('routePointsJson: $routePointsJson, ')
          ..write('photoPathsJson: $photoPathsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    activityType,
    bikeName,
    startedAt,
    endedAt,
    durationSeconds,
    distanceMeters,
    avgSpeedKmh,
    maxSpeedKmh,
    elevationGainMeters,
    avgHeartRate,
    maxHeartRate,
    avgPower,
    maxPower,
    avgCadence,
    maxCadence,
    notes,
    routePointsJson,
    photoPathsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.title == this.title &&
          other.activityType == this.activityType &&
          other.bikeName == this.bikeName &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.avgSpeedKmh == this.avgSpeedKmh &&
          other.maxSpeedKmh == this.maxSpeedKmh &&
          other.elevationGainMeters == this.elevationGainMeters &&
          other.avgHeartRate == this.avgHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.avgPower == this.avgPower &&
          other.maxPower == this.maxPower &&
          other.avgCadence == this.avgCadence &&
          other.maxCadence == this.maxCadence &&
          other.notes == this.notes &&
          other.routePointsJson == this.routePointsJson &&
          other.photoPathsJson == this.photoPathsJson);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> activityType;
  final Value<String> bikeName;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> durationSeconds;
  final Value<double> distanceMeters;
  final Value<double> avgSpeedKmh;
  final Value<double> maxSpeedKmh;
  final Value<double> elevationGainMeters;
  final Value<int?> avgHeartRate;
  final Value<int?> maxHeartRate;
  final Value<int?> avgPower;
  final Value<int?> maxPower;
  final Value<int?> avgCadence;
  final Value<int?> maxCadence;
  final Value<String?> notes;
  final Value<String> routePointsJson;
  final Value<String> photoPathsJson;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.activityType = const Value.absent(),
    this.bikeName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.maxSpeedKmh = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.maxCadence = const Value.absent(),
    this.notes = const Value.absent(),
    this.routePointsJson = const Value.absent(),
    this.photoPathsJson = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String activityType,
    required String bikeName,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required double distanceMeters,
    required double avgSpeedKmh,
    required double maxSpeedKmh,
    required double elevationGainMeters,
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.maxCadence = const Value.absent(),
    this.notes = const Value.absent(),
    this.routePointsJson = const Value.absent(),
    this.photoPathsJson = const Value.absent(),
  }) : title = Value(title),
       activityType = Value(activityType),
       bikeName = Value(bikeName),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       durationSeconds = Value(durationSeconds),
       distanceMeters = Value(distanceMeters),
       avgSpeedKmh = Value(avgSpeedKmh),
       maxSpeedKmh = Value(maxSpeedKmh),
       elevationGainMeters = Value(elevationGainMeters);
  static Insertable<Activity> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? activityType,
    Expression<String>? bikeName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<double>? avgSpeedKmh,
    Expression<double>? maxSpeedKmh,
    Expression<double>? elevationGainMeters,
    Expression<int>? avgHeartRate,
    Expression<int>? maxHeartRate,
    Expression<int>? avgPower,
    Expression<int>? maxPower,
    Expression<int>? avgCadence,
    Expression<int>? maxCadence,
    Expression<String>? notes,
    Expression<String>? routePointsJson,
    Expression<String>? photoPathsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (activityType != null) 'activity_type': activityType,
      if (bikeName != null) 'bike_name': bikeName,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
      if (maxSpeedKmh != null) 'max_speed_kmh': maxSpeedKmh,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgPower != null) 'avg_power': avgPower,
      if (maxPower != null) 'max_power': maxPower,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (maxCadence != null) 'max_cadence': maxCadence,
      if (notes != null) 'notes': notes,
      if (routePointsJson != null) 'route_points_json': routePointsJson,
      if (photoPathsJson != null) 'photo_paths_json': photoPathsJson,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? activityType,
    Value<String>? bikeName,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? durationSeconds,
    Value<double>? distanceMeters,
    Value<double>? avgSpeedKmh,
    Value<double>? maxSpeedKmh,
    Value<double>? elevationGainMeters,
    Value<int?>? avgHeartRate,
    Value<int?>? maxHeartRate,
    Value<int?>? avgPower,
    Value<int?>? maxPower,
    Value<int?>? avgCadence,
    Value<int?>? maxCadence,
    Value<String?>? notes,
    Value<String>? routePointsJson,
    Value<String>? photoPathsJson,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      activityType: activityType ?? this.activityType,
      bikeName: bikeName ?? this.bikeName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgPower: avgPower ?? this.avgPower,
      maxPower: maxPower ?? this.maxPower,
      avgCadence: avgCadence ?? this.avgCadence,
      maxCadence: maxCadence ?? this.maxCadence,
      notes: notes ?? this.notes,
      routePointsJson: routePointsJson ?? this.routePointsJson,
      photoPathsJson: photoPathsJson ?? this.photoPathsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (bikeName.present) {
      map['bike_name'] = Variable<String>(bikeName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (avgSpeedKmh.present) {
      map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh.value);
    }
    if (maxSpeedKmh.present) {
      map['max_speed_kmh'] = Variable<double>(maxSpeedKmh.value);
    }
    if (elevationGainMeters.present) {
      map['elevation_gain_meters'] = Variable<double>(
        elevationGainMeters.value,
      );
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<int>(avgPower.value);
    }
    if (maxPower.present) {
      map['max_power'] = Variable<int>(maxPower.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<int>(avgCadence.value);
    }
    if (maxCadence.present) {
      map['max_cadence'] = Variable<int>(maxCadence.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (routePointsJson.present) {
      map['route_points_json'] = Variable<String>(routePointsJson.value);
    }
    if (photoPathsJson.present) {
      map['photo_paths_json'] = Variable<String>(photoPathsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('activityType: $activityType, ')
          ..write('bikeName: $bikeName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('maxSpeedKmh: $maxSpeedKmh, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('maxPower: $maxPower, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('maxCadence: $maxCadence, ')
          ..write('notes: $notes, ')
          ..write('routePointsJson: $routePointsJson, ')
          ..write('photoPathsJson: $photoPathsJson')
          ..write(')'))
        .toString();
  }
}

class $DownloadedElevationTilesTable extends DownloadedElevationTiles
    with TableInfo<$DownloadedElevationTilesTable, DownloadedElevationTile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedElevationTilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tileNameMeta = const VerificationMeta(
    'tileName',
  );
  @override
  late final GeneratedColumn<String> tileName = GeneratedColumn<String>(
    'tile_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tileName,
    filePath,
    sizeBytes,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_elevation_tiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedElevationTile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tile_name')) {
      context.handle(
        _tileNameMeta,
        tileName.isAcceptableOrUnknown(data['tile_name']!, _tileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_tileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tileName};
  @override
  DownloadedElevationTile map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedElevationTile(
      tileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tile_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $DownloadedElevationTilesTable createAlias(String alias) {
    return $DownloadedElevationTilesTable(attachedDatabase, alias);
  }
}

class DownloadedElevationTile extends DataClass
    implements Insertable<DownloadedElevationTile> {
  /// Nombre estándar de la tesela, ej. "N04W075.hgt".
  final String tileName;
  final String filePath;
  final int sizeBytes;
  final DateTime downloadedAt;
  const DownloadedElevationTile({
    required this.tileName,
    required this.filePath,
    required this.sizeBytes,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tile_name'] = Variable<String>(tileName);
    map['file_path'] = Variable<String>(filePath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  DownloadedElevationTilesCompanion toCompanion(bool nullToAbsent) {
    return DownloadedElevationTilesCompanion(
      tileName: Value(tileName),
      filePath: Value(filePath),
      sizeBytes: Value(sizeBytes),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory DownloadedElevationTile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedElevationTile(
      tileName: serializer.fromJson<String>(json['tileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tileName': serializer.toJson<String>(tileName),
      'filePath': serializer.toJson<String>(filePath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  DownloadedElevationTile copyWith({
    String? tileName,
    String? filePath,
    int? sizeBytes,
    DateTime? downloadedAt,
  }) => DownloadedElevationTile(
    tileName: tileName ?? this.tileName,
    filePath: filePath ?? this.filePath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  DownloadedElevationTile copyWithCompanion(
    DownloadedElevationTilesCompanion data,
  ) {
    return DownloadedElevationTile(
      tileName: data.tileName.present ? data.tileName.value : this.tileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedElevationTile(')
          ..write('tileName: $tileName, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tileName, filePath, sizeBytes, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedElevationTile &&
          other.tileName == this.tileName &&
          other.filePath == this.filePath &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadedElevationTilesCompanion
    extends UpdateCompanion<DownloadedElevationTile> {
  final Value<String> tileName;
  final Value<String> filePath;
  final Value<int> sizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const DownloadedElevationTilesCompanion({
    this.tileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedElevationTilesCompanion.insert({
    required String tileName,
    required String filePath,
    required int sizeBytes,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  }) : tileName = Value(tileName),
       filePath = Value(filePath),
       sizeBytes = Value(sizeBytes),
       downloadedAt = Value(downloadedAt);
  static Insertable<DownloadedElevationTile> custom({
    Expression<String>? tileName,
    Expression<String>? filePath,
    Expression<int>? sizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tileName != null) 'tile_name': tileName,
      if (filePath != null) 'file_path': filePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedElevationTilesCompanion copyWith({
    Value<String>? tileName,
    Value<String>? filePath,
    Value<int>? sizeBytes,
    Value<DateTime>? downloadedAt,
    Value<int>? rowid,
  }) {
    return DownloadedElevationTilesCompanion(
      tileName: tileName ?? this.tileName,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tileName.present) {
      map['tile_name'] = Variable<String>(tileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedElevationTilesCompanion(')
          ..write('tileName: $tileName, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments with TableInfo<$SegmentsTable, Segment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activity'),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLngMeta = const VerificationMeta(
    'startLng',
  );
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
    'start_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
    'end_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
    'end_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startBearingDegreesMeta =
      const VerificationMeta('startBearingDegrees');
  @override
  late final GeneratedColumn<double> startBearingDegrees =
      GeneratedColumn<double>(
        'start_bearing_degrees',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationGainMetersMeta =
      const VerificationMeta('elevationGainMeters');
  @override
  late final GeneratedColumn<double> elevationGainMeters =
      GeneratedColumn<double>(
        'elevation_gain_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _avgSlopePercentMeta = const VerificationMeta(
    'avgSlopePercent',
  );
  @override
  late final GeneratedColumn<double> avgSlopePercent = GeneratedColumn<double>(
    'avg_slope_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxSlopePercentMeta = const VerificationMeta(
    'maxSlopePercent',
  );
  @override
  late final GeneratedColumn<double> maxSlopePercent = GeneratedColumn<double>(
    'max_slope_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
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
  static const VerificationMeta _sourceActivityIdMeta = const VerificationMeta(
    'sourceActivityId',
  );
  @override
  late final GeneratedColumn<int> sourceActivityId = GeneratedColumn<int>(
    'source_activity_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    source,
    remoteId,
    isPublic,
    isActive,
    startLat,
    startLng,
    endLat,
    endLng,
    startBearingDegrees,
    distanceMeters,
    elevationGainMeters,
    avgSlopePercent,
    maxSlopePercent,
    profileJson,
    createdAt,
    sourceActivityId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Segment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    } else if (isInserting) {
      context.missing(_startLatMeta);
    }
    if (data.containsKey('start_lng')) {
      context.handle(
        _startLngMeta,
        startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta),
      );
    } else if (isInserting) {
      context.missing(_startLngMeta);
    }
    if (data.containsKey('end_lat')) {
      context.handle(
        _endLatMeta,
        endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta),
      );
    } else if (isInserting) {
      context.missing(_endLatMeta);
    }
    if (data.containsKey('end_lng')) {
      context.handle(
        _endLngMeta,
        endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta),
      );
    } else if (isInserting) {
      context.missing(_endLngMeta);
    }
    if (data.containsKey('start_bearing_degrees')) {
      context.handle(
        _startBearingDegreesMeta,
        startBearingDegrees.isAcceptableOrUnknown(
          data['start_bearing_degrees']!,
          _startBearingDegreesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startBearingDegreesMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('elevation_gain_meters')) {
      context.handle(
        _elevationGainMetersMeta,
        elevationGainMeters.isAcceptableOrUnknown(
          data['elevation_gain_meters']!,
          _elevationGainMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationGainMetersMeta);
    }
    if (data.containsKey('avg_slope_percent')) {
      context.handle(
        _avgSlopePercentMeta,
        avgSlopePercent.isAcceptableOrUnknown(
          data['avg_slope_percent']!,
          _avgSlopePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgSlopePercentMeta);
    }
    if (data.containsKey('max_slope_percent')) {
      context.handle(
        _maxSlopePercentMeta,
        maxSlopePercent.isAcceptableOrUnknown(
          data['max_slope_percent']!,
          _maxSlopePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxSlopePercentMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source_activity_id')) {
      context.handle(
        _sourceActivityIdMeta,
        sourceActivityId.isAcceptableOrUnknown(
          data['source_activity_id']!,
          _sourceActivityIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Segment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Segment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_public'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      )!,
      startLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lng'],
      )!,
      endLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lat'],
      )!,
      endLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lng'],
      )!,
      startBearingDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_bearing_degrees'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      elevationGainMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_meters'],
      )!,
      avgSlopePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_slope_percent'],
      )!,
      maxSlopePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_slope_percent'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sourceActivityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_activity_id'],
      ),
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class Segment extends DataClass implements Insertable<Segment> {
  final int id;
  final String name;

  /// De dónde nació el segmento:
  ///  - `activity`      : recortado de una actividad propia ya aplanada
  ///                      contra HGT (`SegmentCreationScreen`).
  ///  - `gpxImport`     : importado de un archivo GPX que subió el
  ///                      usuario (altitud barométrica de un
  ///                      ciclocomputador -- prioridad 1 sobre HGT).
  ///  - `nativeCatalog` : descargado del catálogo remoto de segmentos
  ///                      "nativos" de la app (mismo patrón que las
  ///                      teselas de elevación y el grafo vial).
  final String source;

  /// Id del segmento en el catálogo remoto -- solo para `nativeCatalog`.
  /// Sirve para no volver a importar el mismo segmento oficial si el
  /// usuario toca "descargar" dos veces. `null` para segmentos locales.
  final String? remoteId;

  /// Reservado para cuando exista backend real (ver notas del
  /// proyecto: por ahora todo es local, así que esto siempre queda en
  /// `false`). El campo ya existe para no requerir otra migración
  /// cuando llegue la sincronización en la nube.
  final bool isPublic;

  /// Si `SegmentDetectionService` debe vigilar este segmento mientras
  /// se pedalea. El usuario lo prende/apaga desde el menú de
  /// segmentos (Fase 4) -- si está activo, arranca solo al pasar por
  /// su inicio con el rumbo correcto; si no, se ignora por completo.
  final bool isActive;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  /// Rumbo de referencia (grados, 0-360) en el arranque del segmento,
  /// calculado sobre los primeros metros del tramo al crearlo. Se usa
  /// para exigir que el ciclista vaya en el sentido correcto y no
  /// disparar el segmento si pasa en contravía o por una calle
  /// paralela.
  final double startBearingDegrees;
  final double distanceMeters;
  final double elevationGainMeters;
  final double avgSlopePercent;
  final double maxSlopePercent;

  /// Perfil congelado del tramo, serializado en JSON: lista de
  /// `{dist, lat, lng, alt, slope}` en orden desde el inicio hasta el
  /// fin del segmento.
  final String profileJson;
  final DateTime createdAt;

  /// De qué actividad salió este segmento -- trazabilidad, y permite
  /// regenerar el perfil más adelante si cambia el método de
  /// aplanado sin perder el segmento.
  final int? sourceActivityId;
  const Segment({
    required this.id,
    required this.name,
    required this.source,
    this.remoteId,
    required this.isPublic,
    required this.isActive,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startBearingDegrees,
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.avgSlopePercent,
    required this.maxSlopePercent,
    required this.profileJson,
    required this.createdAt,
    this.sourceActivityId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['is_public'] = Variable<bool>(isPublic);
    map['is_active'] = Variable<bool>(isActive);
    map['start_lat'] = Variable<double>(startLat);
    map['start_lng'] = Variable<double>(startLng);
    map['end_lat'] = Variable<double>(endLat);
    map['end_lng'] = Variable<double>(endLng);
    map['start_bearing_degrees'] = Variable<double>(startBearingDegrees);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['elevation_gain_meters'] = Variable<double>(elevationGainMeters);
    map['avg_slope_percent'] = Variable<double>(avgSlopePercent);
    map['max_slope_percent'] = Variable<double>(maxSlopePercent);
    map['profile_json'] = Variable<String>(profileJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || sourceActivityId != null) {
      map['source_activity_id'] = Variable<int>(sourceActivityId);
    }
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      id: Value(id),
      name: Value(name),
      source: Value(source),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      isPublic: Value(isPublic),
      isActive: Value(isActive),
      startLat: Value(startLat),
      startLng: Value(startLng),
      endLat: Value(endLat),
      endLng: Value(endLng),
      startBearingDegrees: Value(startBearingDegrees),
      distanceMeters: Value(distanceMeters),
      elevationGainMeters: Value(elevationGainMeters),
      avgSlopePercent: Value(avgSlopePercent),
      maxSlopePercent: Value(maxSlopePercent),
      profileJson: Value(profileJson),
      createdAt: Value(createdAt),
      sourceActivityId: sourceActivityId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceActivityId),
    );
  }

  factory Segment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Segment(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      startLat: serializer.fromJson<double>(json['startLat']),
      startLng: serializer.fromJson<double>(json['startLng']),
      endLat: serializer.fromJson<double>(json['endLat']),
      endLng: serializer.fromJson<double>(json['endLng']),
      startBearingDegrees: serializer.fromJson<double>(
        json['startBearingDegrees'],
      ),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      elevationGainMeters: serializer.fromJson<double>(
        json['elevationGainMeters'],
      ),
      avgSlopePercent: serializer.fromJson<double>(json['avgSlopePercent']),
      maxSlopePercent: serializer.fromJson<double>(json['maxSlopePercent']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sourceActivityId: serializer.fromJson<int?>(json['sourceActivityId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'remoteId': serializer.toJson<String?>(remoteId),
      'isPublic': serializer.toJson<bool>(isPublic),
      'isActive': serializer.toJson<bool>(isActive),
      'startLat': serializer.toJson<double>(startLat),
      'startLng': serializer.toJson<double>(startLng),
      'endLat': serializer.toJson<double>(endLat),
      'endLng': serializer.toJson<double>(endLng),
      'startBearingDegrees': serializer.toJson<double>(startBearingDegrees),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'elevationGainMeters': serializer.toJson<double>(elevationGainMeters),
      'avgSlopePercent': serializer.toJson<double>(avgSlopePercent),
      'maxSlopePercent': serializer.toJson<double>(maxSlopePercent),
      'profileJson': serializer.toJson<String>(profileJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sourceActivityId': serializer.toJson<int?>(sourceActivityId),
    };
  }

  Segment copyWith({
    int? id,
    String? name,
    String? source,
    Value<String?> remoteId = const Value.absent(),
    bool? isPublic,
    bool? isActive,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? startBearingDegrees,
    double? distanceMeters,
    double? elevationGainMeters,
    double? avgSlopePercent,
    double? maxSlopePercent,
    String? profileJson,
    DateTime? createdAt,
    Value<int?> sourceActivityId = const Value.absent(),
  }) => Segment(
    id: id ?? this.id,
    name: name ?? this.name,
    source: source ?? this.source,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    isPublic: isPublic ?? this.isPublic,
    isActive: isActive ?? this.isActive,
    startLat: startLat ?? this.startLat,
    startLng: startLng ?? this.startLng,
    endLat: endLat ?? this.endLat,
    endLng: endLng ?? this.endLng,
    startBearingDegrees: startBearingDegrees ?? this.startBearingDegrees,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
    avgSlopePercent: avgSlopePercent ?? this.avgSlopePercent,
    maxSlopePercent: maxSlopePercent ?? this.maxSlopePercent,
    profileJson: profileJson ?? this.profileJson,
    createdAt: createdAt ?? this.createdAt,
    sourceActivityId: sourceActivityId.present
        ? sourceActivityId.value
        : this.sourceActivityId,
  );
  Segment copyWithCompanion(SegmentsCompanion data) {
    return Segment(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      startBearingDegrees: data.startBearingDegrees.present
          ? data.startBearingDegrees.value
          : this.startBearingDegrees,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      elevationGainMeters: data.elevationGainMeters.present
          ? data.elevationGainMeters.value
          : this.elevationGainMeters,
      avgSlopePercent: data.avgSlopePercent.present
          ? data.avgSlopePercent.value
          : this.avgSlopePercent,
      maxSlopePercent: data.maxSlopePercent.present
          ? data.maxSlopePercent.value
          : this.maxSlopePercent,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sourceActivityId: data.sourceActivityId.present
          ? data.sourceActivityId.value
          : this.sourceActivityId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Segment(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('remoteId: $remoteId, ')
          ..write('isPublic: $isPublic, ')
          ..write('isActive: $isActive, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('startBearingDegrees: $startBearingDegrees, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('avgSlopePercent: $avgSlopePercent, ')
          ..write('maxSlopePercent: $maxSlopePercent, ')
          ..write('profileJson: $profileJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceActivityId: $sourceActivityId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    source,
    remoteId,
    isPublic,
    isActive,
    startLat,
    startLng,
    endLat,
    endLng,
    startBearingDegrees,
    distanceMeters,
    elevationGainMeters,
    avgSlopePercent,
    maxSlopePercent,
    profileJson,
    createdAt,
    sourceActivityId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Segment &&
          other.id == this.id &&
          other.name == this.name &&
          other.source == this.source &&
          other.remoteId == this.remoteId &&
          other.isPublic == this.isPublic &&
          other.isActive == this.isActive &&
          other.startLat == this.startLat &&
          other.startLng == this.startLng &&
          other.endLat == this.endLat &&
          other.endLng == this.endLng &&
          other.startBearingDegrees == this.startBearingDegrees &&
          other.distanceMeters == this.distanceMeters &&
          other.elevationGainMeters == this.elevationGainMeters &&
          other.avgSlopePercent == this.avgSlopePercent &&
          other.maxSlopePercent == this.maxSlopePercent &&
          other.profileJson == this.profileJson &&
          other.createdAt == this.createdAt &&
          other.sourceActivityId == this.sourceActivityId);
}

class SegmentsCompanion extends UpdateCompanion<Segment> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> source;
  final Value<String?> remoteId;
  final Value<bool> isPublic;
  final Value<bool> isActive;
  final Value<double> startLat;
  final Value<double> startLng;
  final Value<double> endLat;
  final Value<double> endLng;
  final Value<double> startBearingDegrees;
  final Value<double> distanceMeters;
  final Value<double> elevationGainMeters;
  final Value<double> avgSlopePercent;
  final Value<double> maxSlopePercent;
  final Value<String> profileJson;
  final Value<DateTime> createdAt;
  final Value<int?> sourceActivityId;
  const SegmentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.isActive = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.startBearingDegrees = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.avgSlopePercent = const Value.absent(),
    this.maxSlopePercent = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sourceActivityId = const Value.absent(),
  });
  SegmentsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.source = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.isActive = const Value.absent(),
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double startBearingDegrees,
    required double distanceMeters,
    required double elevationGainMeters,
    required double avgSlopePercent,
    required double maxSlopePercent,
    required String profileJson,
    required DateTime createdAt,
    this.sourceActivityId = const Value.absent(),
  }) : name = Value(name),
       startLat = Value(startLat),
       startLng = Value(startLng),
       endLat = Value(endLat),
       endLng = Value(endLng),
       startBearingDegrees = Value(startBearingDegrees),
       distanceMeters = Value(distanceMeters),
       elevationGainMeters = Value(elevationGainMeters),
       avgSlopePercent = Value(avgSlopePercent),
       maxSlopePercent = Value(maxSlopePercent),
       profileJson = Value(profileJson),
       createdAt = Value(createdAt);
  static Insertable<Segment> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? source,
    Expression<String>? remoteId,
    Expression<bool>? isPublic,
    Expression<bool>? isActive,
    Expression<double>? startLat,
    Expression<double>? startLng,
    Expression<double>? endLat,
    Expression<double>? endLng,
    Expression<double>? startBearingDegrees,
    Expression<double>? distanceMeters,
    Expression<double>? elevationGainMeters,
    Expression<double>? avgSlopePercent,
    Expression<double>? maxSlopePercent,
    Expression<String>? profileJson,
    Expression<DateTime>? createdAt,
    Expression<int>? sourceActivityId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (remoteId != null) 'remote_id': remoteId,
      if (isPublic != null) 'is_public': isPublic,
      if (isActive != null) 'is_active': isActive,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
      if (endLat != null) 'end_lat': endLat,
      if (endLng != null) 'end_lng': endLng,
      if (startBearingDegrees != null)
        'start_bearing_degrees': startBearingDegrees,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (avgSlopePercent != null) 'avg_slope_percent': avgSlopePercent,
      if (maxSlopePercent != null) 'max_slope_percent': maxSlopePercent,
      if (profileJson != null) 'profile_json': profileJson,
      if (createdAt != null) 'created_at': createdAt,
      if (sourceActivityId != null) 'source_activity_id': sourceActivityId,
    });
  }

  SegmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? source,
    Value<String?>? remoteId,
    Value<bool>? isPublic,
    Value<bool>? isActive,
    Value<double>? startLat,
    Value<double>? startLng,
    Value<double>? endLat,
    Value<double>? endLng,
    Value<double>? startBearingDegrees,
    Value<double>? distanceMeters,
    Value<double>? elevationGainMeters,
    Value<double>? avgSlopePercent,
    Value<double>? maxSlopePercent,
    Value<String>? profileJson,
    Value<DateTime>? createdAt,
    Value<int?>? sourceActivityId,
  }) {
    return SegmentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      remoteId: remoteId ?? this.remoteId,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      startBearingDegrees: startBearingDegrees ?? this.startBearingDegrees,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      avgSlopePercent: avgSlopePercent ?? this.avgSlopePercent,
      maxSlopePercent: maxSlopePercent ?? this.maxSlopePercent,
      profileJson: profileJson ?? this.profileJson,
      createdAt: createdAt ?? this.createdAt,
      sourceActivityId: sourceActivityId ?? this.sourceActivityId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLng.present) {
      map['start_lng'] = Variable<double>(startLng.value);
    }
    if (endLat.present) {
      map['end_lat'] = Variable<double>(endLat.value);
    }
    if (endLng.present) {
      map['end_lng'] = Variable<double>(endLng.value);
    }
    if (startBearingDegrees.present) {
      map['start_bearing_degrees'] = Variable<double>(
        startBearingDegrees.value,
      );
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (elevationGainMeters.present) {
      map['elevation_gain_meters'] = Variable<double>(
        elevationGainMeters.value,
      );
    }
    if (avgSlopePercent.present) {
      map['avg_slope_percent'] = Variable<double>(avgSlopePercent.value);
    }
    if (maxSlopePercent.present) {
      map['max_slope_percent'] = Variable<double>(maxSlopePercent.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sourceActivityId.present) {
      map['source_activity_id'] = Variable<int>(sourceActivityId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('remoteId: $remoteId, ')
          ..write('isPublic: $isPublic, ')
          ..write('isActive: $isActive, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('startBearingDegrees: $startBearingDegrees, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('avgSlopePercent: $avgSlopePercent, ')
          ..write('maxSlopePercent: $maxSlopePercent, ')
          ..write('profileJson: $profileJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceActivityId: $sourceActivityId')
          ..write(')'))
        .toString();
  }
}

class $SegmentEffortsTable extends SegmentEfforts
    with TableInfo<$SegmentEffortsTable, SegmentEffort> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentEffortsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<int> segmentId = GeneratedColumn<int>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgSpeedKmhMeta = const VerificationMeta(
    'avgSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> avgSpeedKmh = GeneratedColumn<double>(
    'avg_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHeartRateMeta = const VerificationMeta(
    'avgHeartRate',
  );
  @override
  late final GeneratedColumn<int> avgHeartRate = GeneratedColumn<int>(
    'avg_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgPowerMeta = const VerificationMeta(
    'avgPower',
  );
  @override
  late final GeneratedColumn<int> avgPower = GeneratedColumn<int>(
    'avg_power',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitsJsonMeta = const VerificationMeta(
    'splitsJson',
  );
  @override
  late final GeneratedColumn<String> splitsJson = GeneratedColumn<String>(
    'splits_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    segmentId,
    activityId,
    durationSeconds,
    avgSpeedKmh,
    avgHeartRate,
    avgPower,
    completedAt,
    splitsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segment_efforts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SegmentEffort> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('avg_speed_kmh')) {
      context.handle(
        _avgSpeedKmhMeta,
        avgSpeedKmh.isAcceptableOrUnknown(
          data['avg_speed_kmh']!,
          _avgSpeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgSpeedKmhMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
        _avgHeartRateMeta,
        avgHeartRate.isAcceptableOrUnknown(
          data['avg_heart_rate']!,
          _avgHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('avg_power')) {
      context.handle(
        _avgPowerMeta,
        avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('splits_json')) {
      context.handle(
        _splitsJsonMeta,
        splitsJson.isAcceptableOrUnknown(data['splits_json']!, _splitsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SegmentEffort map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SegmentEffort(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      avgSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed_kmh'],
      )!,
      avgHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_heart_rate'],
      ),
      avgPower: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_power'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      splitsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}splits_json'],
      )!,
    );
  }

  @override
  $SegmentEffortsTable createAlias(String alias) {
    return $SegmentEffortsTable(attachedDatabase, alias);
  }
}

class SegmentEffort extends DataClass implements Insertable<SegmentEffort> {
  final int id;
  final int segmentId;
  final int activityId;
  final int durationSeconds;
  final double avgSpeedKmh;
  final int? avgHeartRate;
  final int? avgPower;
  final DateTime completedAt;

  /// Curva tiempo-vs-distancia REAL de este esfuerzo, serializada como
  /// JSON: `[{d: <metros desde el inicio>, t: <segundos>}]`. Es lo que
  /// alimenta el "fantasma" de la mejor marca en la pantalla de
  /// segmento en vivo (Fase D) -- el fantasma se mueve a la velocidad
  /// real que llevaba el ciclista en cada punto, no a un ritmo
  /// promedio constante. `'[]'` para esfuerzos grabados antes de la
  /// Fase C.
  final String splitsJson;
  const SegmentEffort({
    required this.id,
    required this.segmentId,
    required this.activityId,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    this.avgHeartRate,
    this.avgPower,
    required this.completedAt,
    required this.splitsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['segment_id'] = Variable<int>(segmentId);
    map['activity_id'] = Variable<int>(activityId);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate);
    }
    if (!nullToAbsent || avgPower != null) {
      map['avg_power'] = Variable<int>(avgPower);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['splits_json'] = Variable<String>(splitsJson);
    return map;
  }

  SegmentEffortsCompanion toCompanion(bool nullToAbsent) {
    return SegmentEffortsCompanion(
      id: Value(id),
      segmentId: Value(segmentId),
      activityId: Value(activityId),
      durationSeconds: Value(durationSeconds),
      avgSpeedKmh: Value(avgSpeedKmh),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      avgPower: avgPower == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPower),
      completedAt: Value(completedAt),
      splitsJson: Value(splitsJson),
    );
  }

  factory SegmentEffort.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SegmentEffort(
      id: serializer.fromJson<int>(json['id']),
      segmentId: serializer.fromJson<int>(json['segmentId']),
      activityId: serializer.fromJson<int>(json['activityId']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      avgSpeedKmh: serializer.fromJson<double>(json['avgSpeedKmh']),
      avgHeartRate: serializer.fromJson<int?>(json['avgHeartRate']),
      avgPower: serializer.fromJson<int?>(json['avgPower']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      splitsJson: serializer.fromJson<String>(json['splitsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'segmentId': serializer.toJson<int>(segmentId),
      'activityId': serializer.toJson<int>(activityId),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'avgSpeedKmh': serializer.toJson<double>(avgSpeedKmh),
      'avgHeartRate': serializer.toJson<int?>(avgHeartRate),
      'avgPower': serializer.toJson<int?>(avgPower),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'splitsJson': serializer.toJson<String>(splitsJson),
    };
  }

  SegmentEffort copyWith({
    int? id,
    int? segmentId,
    int? activityId,
    int? durationSeconds,
    double? avgSpeedKmh,
    Value<int?> avgHeartRate = const Value.absent(),
    Value<int?> avgPower = const Value.absent(),
    DateTime? completedAt,
    String? splitsJson,
  }) => SegmentEffort(
    id: id ?? this.id,
    segmentId: segmentId ?? this.segmentId,
    activityId: activityId ?? this.activityId,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    avgHeartRate: avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
    avgPower: avgPower.present ? avgPower.value : this.avgPower,
    completedAt: completedAt ?? this.completedAt,
    splitsJson: splitsJson ?? this.splitsJson,
  );
  SegmentEffort copyWithCompanion(SegmentEffortsCompanion data) {
    return SegmentEffort(
      id: data.id.present ? data.id.value : this.id,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      avgSpeedKmh: data.avgSpeedKmh.present
          ? data.avgSpeedKmh.value
          : this.avgSpeedKmh,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      splitsJson: data.splitsJson.present
          ? data.splitsJson.value
          : this.splitsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SegmentEffort(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('activityId: $activityId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('completedAt: $completedAt, ')
          ..write('splitsJson: $splitsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    segmentId,
    activityId,
    durationSeconds,
    avgSpeedKmh,
    avgHeartRate,
    avgPower,
    completedAt,
    splitsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SegmentEffort &&
          other.id == this.id &&
          other.segmentId == this.segmentId &&
          other.activityId == this.activityId &&
          other.durationSeconds == this.durationSeconds &&
          other.avgSpeedKmh == this.avgSpeedKmh &&
          other.avgHeartRate == this.avgHeartRate &&
          other.avgPower == this.avgPower &&
          other.completedAt == this.completedAt &&
          other.splitsJson == this.splitsJson);
}

class SegmentEffortsCompanion extends UpdateCompanion<SegmentEffort> {
  final Value<int> id;
  final Value<int> segmentId;
  final Value<int> activityId;
  final Value<int> durationSeconds;
  final Value<double> avgSpeedKmh;
  final Value<int?> avgHeartRate;
  final Value<int?> avgPower;
  final Value<DateTime> completedAt;
  final Value<String> splitsJson;
  const SegmentEffortsCompanion({
    this.id = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.avgSpeedKmh = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.splitsJson = const Value.absent(),
  });
  SegmentEffortsCompanion.insert({
    this.id = const Value.absent(),
    required int segmentId,
    required int activityId,
    required int durationSeconds,
    required double avgSpeedKmh,
    this.avgHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    required DateTime completedAt,
    this.splitsJson = const Value.absent(),
  }) : segmentId = Value(segmentId),
       activityId = Value(activityId),
       durationSeconds = Value(durationSeconds),
       avgSpeedKmh = Value(avgSpeedKmh),
       completedAt = Value(completedAt);
  static Insertable<SegmentEffort> custom({
    Expression<int>? id,
    Expression<int>? segmentId,
    Expression<int>? activityId,
    Expression<int>? durationSeconds,
    Expression<double>? avgSpeedKmh,
    Expression<int>? avgHeartRate,
    Expression<int>? avgPower,
    Expression<DateTime>? completedAt,
    Expression<String>? splitsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (segmentId != null) 'segment_id': segmentId,
      if (activityId != null) 'activity_id': activityId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (avgPower != null) 'avg_power': avgPower,
      if (completedAt != null) 'completed_at': completedAt,
      if (splitsJson != null) 'splits_json': splitsJson,
    });
  }

  SegmentEffortsCompanion copyWith({
    Value<int>? id,
    Value<int>? segmentId,
    Value<int>? activityId,
    Value<int>? durationSeconds,
    Value<double>? avgSpeedKmh,
    Value<int?>? avgHeartRate,
    Value<int?>? avgPower,
    Value<DateTime>? completedAt,
    Value<String>? splitsJson,
  }) {
    return SegmentEffortsCompanion(
      id: id ?? this.id,
      segmentId: segmentId ?? this.segmentId,
      activityId: activityId ?? this.activityId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      avgPower: avgPower ?? this.avgPower,
      completedAt: completedAt ?? this.completedAt,
      splitsJson: splitsJson ?? this.splitsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<int>(segmentId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (avgSpeedKmh.present) {
      map['avg_speed_kmh'] = Variable<double>(avgSpeedKmh.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<int>(avgHeartRate.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<int>(avgPower.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (splitsJson.present) {
      map['splits_json'] = Variable<String>(splitsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentEffortsCompanion(')
          ..write('id: $id, ')
          ..write('segmentId: $segmentId, ')
          ..write('activityId: $activityId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('avgSpeedKmh: $avgSpeedKmh, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('completedAt: $completedAt, ')
          ..write('splitsJson: $splitsJson')
          ..write(')'))
        .toString();
  }
}

class $DownloadedRoadRegionsTable extends DownloadedRoadRegions
    with TableInfo<$DownloadedRoadRegionsTable, DownloadedRoadRegion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedRoadRegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _regionIdMeta = const VerificationMeta(
    'regionId',
  );
  @override
  late final GeneratedColumn<String> regionId = GeneratedColumn<String>(
    'region_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    regionId,
    filePath,
    sizeBytes,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_road_regions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedRoadRegion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('region_id')) {
      context.handle(
        _regionIdMeta,
        regionId.isAcceptableOrUnknown(data['region_id']!, _regionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_regionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {regionId};
  @override
  DownloadedRoadRegion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedRoadRegion(
      regionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $DownloadedRoadRegionsTable createAlias(String alias) {
    return $DownloadedRoadRegionsTable(attachedDatabase, alias);
  }
}

class DownloadedRoadRegion extends DataClass
    implements Insertable<DownloadedRoadRegion> {
  /// Id de la región en el catálogo de `RoadRegionId`, ej.
  /// "norte_de_santander".
  final String regionId;
  final String filePath;
  final int sizeBytes;
  final DateTime downloadedAt;
  const DownloadedRoadRegion({
    required this.regionId,
    required this.filePath,
    required this.sizeBytes,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['region_id'] = Variable<String>(regionId);
    map['file_path'] = Variable<String>(filePath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  DownloadedRoadRegionsCompanion toCompanion(bool nullToAbsent) {
    return DownloadedRoadRegionsCompanion(
      regionId: Value(regionId),
      filePath: Value(filePath),
      sizeBytes: Value(sizeBytes),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory DownloadedRoadRegion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedRoadRegion(
      regionId: serializer.fromJson<String>(json['regionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'regionId': serializer.toJson<String>(regionId),
      'filePath': serializer.toJson<String>(filePath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  DownloadedRoadRegion copyWith({
    String? regionId,
    String? filePath,
    int? sizeBytes,
    DateTime? downloadedAt,
  }) => DownloadedRoadRegion(
    regionId: regionId ?? this.regionId,
    filePath: filePath ?? this.filePath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  DownloadedRoadRegion copyWithCompanion(DownloadedRoadRegionsCompanion data) {
    return DownloadedRoadRegion(
      regionId: data.regionId.present ? data.regionId.value : this.regionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedRoadRegion(')
          ..write('regionId: $regionId, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(regionId, filePath, sizeBytes, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedRoadRegion &&
          other.regionId == this.regionId &&
          other.filePath == this.filePath &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadedRoadRegionsCompanion
    extends UpdateCompanion<DownloadedRoadRegion> {
  final Value<String> regionId;
  final Value<String> filePath;
  final Value<int> sizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const DownloadedRoadRegionsCompanion({
    this.regionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedRoadRegionsCompanion.insert({
    required String regionId,
    required String filePath,
    required int sizeBytes,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  }) : regionId = Value(regionId),
       filePath = Value(filePath),
       sizeBytes = Value(sizeBytes),
       downloadedAt = Value(downloadedAt);
  static Insertable<DownloadedRoadRegion> custom({
    Expression<String>? regionId,
    Expression<String>? filePath,
    Expression<int>? sizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (regionId != null) 'region_id': regionId,
      if (filePath != null) 'file_path': filePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedRoadRegionsCompanion copyWith({
    Value<String>? regionId,
    Value<String>? filePath,
    Value<int>? sizeBytes,
    Value<DateTime>? downloadedAt,
    Value<int>? rowid,
  }) {
    return DownloadedRoadRegionsCompanion(
      regionId: regionId ?? this.regionId,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (regionId.present) {
      map['region_id'] = Variable<String>(regionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedRoadRegionsCompanion(')
          ..write('regionId: $regionId, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedPlacesTable extends SavedPlaces
    with TableInfo<$SavedPlacesTable, SavedPlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlacesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('generic'),
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
    name,
    latitude,
    longitude,
    kind,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedPlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
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
  SavedPlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedPlacesTable createAlias(String alias) {
    return $SavedPlacesTable(attachedDatabase, alias);
  }
}

class SavedPlace extends DataClass implements Insertable<SavedPlace> {
  final int id;
  final String name;
  final double latitude;
  final double longitude;

  /// 'home' | 'peak' | 'generic' -- decide el ícono. 'peak' se sugiere
  /// solo cuando el nombre parece un alto (ver `climb_detection.dart`).
  final String kind;
  final DateTime createdAt;
  const SavedPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.kind,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedPlacesCompanion toCompanion(bool nullToAbsent) {
    return SavedPlacesCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      kind: Value(kind),
      createdAt: Value(createdAt),
    );
  }

  factory SavedPlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlace(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedPlace copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    String? kind,
    DateTime? createdAt,
  }) => SavedPlace(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedPlace copyWithCompanion(SavedPlacesCompanion data) {
    return SavedPlace(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlace(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, latitude, longitude, kind, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlace &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt);
}

class SavedPlacesCompanion extends UpdateCompanion<SavedPlace> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  const SavedPlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SavedPlacesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double latitude,
    required double longitude,
    this.kind = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       createdAt = Value(createdAt);
  static Insertable<SavedPlace> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SavedPlacesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? kind,
    Value<DateTime>? createdAt,
  }) {
    return SavedPlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $DownloadedElevationTilesTable downloadedElevationTiles =
      $DownloadedElevationTilesTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final $SegmentEffortsTable segmentEfforts = $SegmentEffortsTable(this);
  late final $DownloadedRoadRegionsTable downloadedRoadRegions =
      $DownloadedRoadRegionsTable(this);
  late final $SavedPlacesTable savedPlaces = $SavedPlacesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    downloadedElevationTiles,
    segments,
    segmentEfforts,
    downloadedRoadRegions,
    savedPlaces,
  ];
}

typedef $$ActivitiesTableCreateCompanionBuilder =
    ActivitiesCompanion Function({
      Value<int> id,
      required String title,
      required String activityType,
      required String bikeName,
      required DateTime startedAt,
      required DateTime endedAt,
      required int durationSeconds,
      required double distanceMeters,
      required double avgSpeedKmh,
      required double maxSpeedKmh,
      required double elevationGainMeters,
      Value<int?> avgHeartRate,
      Value<int?> maxHeartRate,
      Value<int?> avgPower,
      Value<int?> maxPower,
      Value<int?> avgCadence,
      Value<int?> maxCadence,
      Value<String?> notes,
      Value<String> routePointsJson,
      Value<String> photoPathsJson,
    });
typedef $$ActivitiesTableUpdateCompanionBuilder =
    ActivitiesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> activityType,
      Value<String> bikeName,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> durationSeconds,
      Value<double> distanceMeters,
      Value<double> avgSpeedKmh,
      Value<double> maxSpeedKmh,
      Value<double> elevationGainMeters,
      Value<int?> avgHeartRate,
      Value<int?> maxHeartRate,
      Value<int?> avgPower,
      Value<int?> maxPower,
      Value<int?> avgCadence,
      Value<int?> maxCadence,
      Value<String?> notes,
      Value<String> routePointsJson,
      Value<String> photoPathsJson,
    });

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bikeName => $composableBuilder(
    column: $table.bikeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgPower => $composableBuilder(
    column: $table.avgPower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxPower => $composableBuilder(
    column: $table.maxPower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxCadence => $composableBuilder(
    column: $table.maxCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routePointsJson => $composableBuilder(
    column: $table.routePointsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bikeName => $composableBuilder(
    column: $table.bikeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgPower => $composableBuilder(
    column: $table.avgPower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxPower => $composableBuilder(
    column: $table.maxPower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxCadence => $composableBuilder(
    column: $table.maxCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routePointsJson => $composableBuilder(
    column: $table.routePointsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bikeName =>
      $composableBuilder(column: $table.bikeName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<int> get maxPower =>
      $composableBuilder(column: $table.maxPower, builder: (column) => column);

  GeneratedColumn<int> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxCadence => $composableBuilder(
    column: $table.maxCadence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get routePointsJson => $composableBuilder(
    column: $table.routePointsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => column,
  );
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
          Activity,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<String> bikeName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double> avgSpeedKmh = const Value.absent(),
                Value<double> maxSpeedKmh = const Value.absent(),
                Value<double> elevationGainMeters = const Value.absent(),
                Value<int?> avgHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<int?> avgPower = const Value.absent(),
                Value<int?> maxPower = const Value.absent(),
                Value<int?> avgCadence = const Value.absent(),
                Value<int?> maxCadence = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> routePointsJson = const Value.absent(),
                Value<String> photoPathsJson = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                title: title,
                activityType: activityType,
                bikeName: bikeName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                avgSpeedKmh: avgSpeedKmh,
                maxSpeedKmh: maxSpeedKmh,
                elevationGainMeters: elevationGainMeters,
                avgHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                avgPower: avgPower,
                maxPower: maxPower,
                avgCadence: avgCadence,
                maxCadence: maxCadence,
                notes: notes,
                routePointsJson: routePointsJson,
                photoPathsJson: photoPathsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String activityType,
                required String bikeName,
                required DateTime startedAt,
                required DateTime endedAt,
                required int durationSeconds,
                required double distanceMeters,
                required double avgSpeedKmh,
                required double maxSpeedKmh,
                required double elevationGainMeters,
                Value<int?> avgHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<int?> avgPower = const Value.absent(),
                Value<int?> maxPower = const Value.absent(),
                Value<int?> avgCadence = const Value.absent(),
                Value<int?> maxCadence = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> routePointsJson = const Value.absent(),
                Value<String> photoPathsJson = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                title: title,
                activityType: activityType,
                bikeName: bikeName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                avgSpeedKmh: avgSpeedKmh,
                maxSpeedKmh: maxSpeedKmh,
                elevationGainMeters: elevationGainMeters,
                avgHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                avgPower: avgPower,
                maxPower: maxPower,
                avgCadence: avgCadence,
                maxCadence: maxCadence,
                notes: notes,
                routePointsJson: routePointsJson,
                photoPathsJson: photoPathsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
      Activity,
      PrefetchHooks Function()
    >;
typedef $$DownloadedElevationTilesTableCreateCompanionBuilder =
    DownloadedElevationTilesCompanion Function({
      required String tileName,
      required String filePath,
      required int sizeBytes,
      required DateTime downloadedAt,
      Value<int> rowid,
    });
typedef $$DownloadedElevationTilesTableUpdateCompanionBuilder =
    DownloadedElevationTilesCompanion Function({
      Value<String> tileName,
      Value<String> filePath,
      Value<int> sizeBytes,
      Value<DateTime> downloadedAt,
      Value<int> rowid,
    });

class $$DownloadedElevationTilesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedElevationTilesTable> {
  $$DownloadedElevationTilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tileName => $composableBuilder(
    column: $table.tileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedElevationTilesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedElevationTilesTable> {
  $$DownloadedElevationTilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tileName => $composableBuilder(
    column: $table.tileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedElevationTilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedElevationTilesTable> {
  $$DownloadedElevationTilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tileName =>
      $composableBuilder(column: $table.tileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadedElevationTilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedElevationTilesTable,
          DownloadedElevationTile,
          $$DownloadedElevationTilesTableFilterComposer,
          $$DownloadedElevationTilesTableOrderingComposer,
          $$DownloadedElevationTilesTableAnnotationComposer,
          $$DownloadedElevationTilesTableCreateCompanionBuilder,
          $$DownloadedElevationTilesTableUpdateCompanionBuilder,
          (
            DownloadedElevationTile,
            BaseReferences<
              _$AppDatabase,
              $DownloadedElevationTilesTable,
              DownloadedElevationTile
            >,
          ),
          DownloadedElevationTile,
          PrefetchHooks Function()
        > {
  $$DownloadedElevationTilesTableTableManager(
    _$AppDatabase db,
    $DownloadedElevationTilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedElevationTilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DownloadedElevationTilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadedElevationTilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedElevationTilesCompanion(
                tileName: tileName,
                filePath: filePath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tileName,
                required String filePath,
                required int sizeBytes,
                required DateTime downloadedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadedElevationTilesCompanion.insert(
                tileName: tileName,
                filePath: filePath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedElevationTilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedElevationTilesTable,
      DownloadedElevationTile,
      $$DownloadedElevationTilesTableFilterComposer,
      $$DownloadedElevationTilesTableOrderingComposer,
      $$DownloadedElevationTilesTableAnnotationComposer,
      $$DownloadedElevationTilesTableCreateCompanionBuilder,
      $$DownloadedElevationTilesTableUpdateCompanionBuilder,
      (
        DownloadedElevationTile,
        BaseReferences<
          _$AppDatabase,
          $DownloadedElevationTilesTable,
          DownloadedElevationTile
        >,
      ),
      DownloadedElevationTile,
      PrefetchHooks Function()
    >;
typedef $$SegmentsTableCreateCompanionBuilder =
    SegmentsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> source,
      Value<String?> remoteId,
      Value<bool> isPublic,
      Value<bool> isActive,
      required double startLat,
      required double startLng,
      required double endLat,
      required double endLng,
      required double startBearingDegrees,
      required double distanceMeters,
      required double elevationGainMeters,
      required double avgSlopePercent,
      required double maxSlopePercent,
      required String profileJson,
      required DateTime createdAt,
      Value<int?> sourceActivityId,
    });
typedef $$SegmentsTableUpdateCompanionBuilder =
    SegmentsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> source,
      Value<String?> remoteId,
      Value<bool> isPublic,
      Value<bool> isActive,
      Value<double> startLat,
      Value<double> startLng,
      Value<double> endLat,
      Value<double> endLng,
      Value<double> startBearingDegrees,
      Value<double> distanceMeters,
      Value<double> elevationGainMeters,
      Value<double> avgSlopePercent,
      Value<double> maxSlopePercent,
      Value<String> profileJson,
      Value<DateTime> createdAt,
      Value<int?> sourceActivityId,
    });

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startBearingDegrees => $composableBuilder(
    column: $table.startBearingDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSlopePercent => $composableBuilder(
    column: $table.avgSlopePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSlopePercent => $composableBuilder(
    column: $table.maxSlopePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceActivityId => $composableBuilder(
    column: $table.sourceActivityId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startBearingDegrees => $composableBuilder(
    column: $table.startBearingDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSlopePercent => $composableBuilder(
    column: $table.avgSlopePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSlopePercent => $composableBuilder(
    column: $table.maxSlopePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceActivityId => $composableBuilder(
    column: $table.sourceActivityId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<double> get startBearingDegrees => $composableBuilder(
    column: $table.startBearingDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationGainMeters => $composableBuilder(
    column: $table.elevationGainMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSlopePercent => $composableBuilder(
    column: $table.avgSlopePercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSlopePercent => $composableBuilder(
    column: $table.maxSlopePercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sourceActivityId => $composableBuilder(
    column: $table.sourceActivityId,
    builder: (column) => column,
  );
}

class $$SegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentsTable,
          Segment,
          $$SegmentsTableFilterComposer,
          $$SegmentsTableOrderingComposer,
          $$SegmentsTableAnnotationComposer,
          $$SegmentsTableCreateCompanionBuilder,
          $$SegmentsTableUpdateCompanionBuilder,
          (Segment, BaseReferences<_$AppDatabase, $SegmentsTable, Segment>),
          Segment,
          PrefetchHooks Function()
        > {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<double> startLat = const Value.absent(),
                Value<double> startLng = const Value.absent(),
                Value<double> endLat = const Value.absent(),
                Value<double> endLng = const Value.absent(),
                Value<double> startBearingDegrees = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double> elevationGainMeters = const Value.absent(),
                Value<double> avgSlopePercent = const Value.absent(),
                Value<double> maxSlopePercent = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> sourceActivityId = const Value.absent(),
              }) => SegmentsCompanion(
                id: id,
                name: name,
                source: source,
                remoteId: remoteId,
                isPublic: isPublic,
                isActive: isActive,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                startBearingDegrees: startBearingDegrees,
                distanceMeters: distanceMeters,
                elevationGainMeters: elevationGainMeters,
                avgSlopePercent: avgSlopePercent,
                maxSlopePercent: maxSlopePercent,
                profileJson: profileJson,
                createdAt: createdAt,
                sourceActivityId: sourceActivityId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> source = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required double startLat,
                required double startLng,
                required double endLat,
                required double endLng,
                required double startBearingDegrees,
                required double distanceMeters,
                required double elevationGainMeters,
                required double avgSlopePercent,
                required double maxSlopePercent,
                required String profileJson,
                required DateTime createdAt,
                Value<int?> sourceActivityId = const Value.absent(),
              }) => SegmentsCompanion.insert(
                id: id,
                name: name,
                source: source,
                remoteId: remoteId,
                isPublic: isPublic,
                isActive: isActive,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                startBearingDegrees: startBearingDegrees,
                distanceMeters: distanceMeters,
                elevationGainMeters: elevationGainMeters,
                avgSlopePercent: avgSlopePercent,
                maxSlopePercent: maxSlopePercent,
                profileJson: profileJson,
                createdAt: createdAt,
                sourceActivityId: sourceActivityId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentsTable,
      Segment,
      $$SegmentsTableFilterComposer,
      $$SegmentsTableOrderingComposer,
      $$SegmentsTableAnnotationComposer,
      $$SegmentsTableCreateCompanionBuilder,
      $$SegmentsTableUpdateCompanionBuilder,
      (Segment, BaseReferences<_$AppDatabase, $SegmentsTable, Segment>),
      Segment,
      PrefetchHooks Function()
    >;
typedef $$SegmentEffortsTableCreateCompanionBuilder =
    SegmentEffortsCompanion Function({
      Value<int> id,
      required int segmentId,
      required int activityId,
      required int durationSeconds,
      required double avgSpeedKmh,
      Value<int?> avgHeartRate,
      Value<int?> avgPower,
      required DateTime completedAt,
      Value<String> splitsJson,
    });
typedef $$SegmentEffortsTableUpdateCompanionBuilder =
    SegmentEffortsCompanion Function({
      Value<int> id,
      Value<int> segmentId,
      Value<int> activityId,
      Value<int> durationSeconds,
      Value<double> avgSpeedKmh,
      Value<int?> avgHeartRate,
      Value<int?> avgPower,
      Value<DateTime> completedAt,
      Value<String> splitsJson,
    });

class $$SegmentEffortsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentEffortsTable> {
  $$SegmentEffortsTableFilterComposer({
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

  ColumnFilters<int> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgPower => $composableBuilder(
    column: $table.avgPower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SegmentEffortsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentEffortsTable> {
  $$SegmentEffortsTableOrderingComposer({
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

  ColumnOrderings<int> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgPower => $composableBuilder(
    column: $table.avgPower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SegmentEffortsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentEffortsTable> {
  $$SegmentEffortsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgSpeedKmh => $composableBuilder(
    column: $table.avgSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitsJson => $composableBuilder(
    column: $table.splitsJson,
    builder: (column) => column,
  );
}

class $$SegmentEffortsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentEffortsTable,
          SegmentEffort,
          $$SegmentEffortsTableFilterComposer,
          $$SegmentEffortsTableOrderingComposer,
          $$SegmentEffortsTableAnnotationComposer,
          $$SegmentEffortsTableCreateCompanionBuilder,
          $$SegmentEffortsTableUpdateCompanionBuilder,
          (
            SegmentEffort,
            BaseReferences<_$AppDatabase, $SegmentEffortsTable, SegmentEffort>,
          ),
          SegmentEffort,
          PrefetchHooks Function()
        > {
  $$SegmentEffortsTableTableManager(
    _$AppDatabase db,
    $SegmentEffortsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentEffortsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentEffortsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentEffortsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> segmentId = const Value.absent(),
                Value<int> activityId = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> avgSpeedKmh = const Value.absent(),
                Value<int?> avgHeartRate = const Value.absent(),
                Value<int?> avgPower = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> splitsJson = const Value.absent(),
              }) => SegmentEffortsCompanion(
                id: id,
                segmentId: segmentId,
                activityId: activityId,
                durationSeconds: durationSeconds,
                avgSpeedKmh: avgSpeedKmh,
                avgHeartRate: avgHeartRate,
                avgPower: avgPower,
                completedAt: completedAt,
                splitsJson: splitsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int segmentId,
                required int activityId,
                required int durationSeconds,
                required double avgSpeedKmh,
                Value<int?> avgHeartRate = const Value.absent(),
                Value<int?> avgPower = const Value.absent(),
                required DateTime completedAt,
                Value<String> splitsJson = const Value.absent(),
              }) => SegmentEffortsCompanion.insert(
                id: id,
                segmentId: segmentId,
                activityId: activityId,
                durationSeconds: durationSeconds,
                avgSpeedKmh: avgSpeedKmh,
                avgHeartRate: avgHeartRate,
                avgPower: avgPower,
                completedAt: completedAt,
                splitsJson: splitsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SegmentEffortsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentEffortsTable,
      SegmentEffort,
      $$SegmentEffortsTableFilterComposer,
      $$SegmentEffortsTableOrderingComposer,
      $$SegmentEffortsTableAnnotationComposer,
      $$SegmentEffortsTableCreateCompanionBuilder,
      $$SegmentEffortsTableUpdateCompanionBuilder,
      (
        SegmentEffort,
        BaseReferences<_$AppDatabase, $SegmentEffortsTable, SegmentEffort>,
      ),
      SegmentEffort,
      PrefetchHooks Function()
    >;
typedef $$DownloadedRoadRegionsTableCreateCompanionBuilder =
    DownloadedRoadRegionsCompanion Function({
      required String regionId,
      required String filePath,
      required int sizeBytes,
      required DateTime downloadedAt,
      Value<int> rowid,
    });
typedef $$DownloadedRoadRegionsTableUpdateCompanionBuilder =
    DownloadedRoadRegionsCompanion Function({
      Value<String> regionId,
      Value<String> filePath,
      Value<int> sizeBytes,
      Value<DateTime> downloadedAt,
      Value<int> rowid,
    });

class $$DownloadedRoadRegionsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedRoadRegionsTable> {
  $$DownloadedRoadRegionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedRoadRegionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedRoadRegionsTable> {
  $$DownloadedRoadRegionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedRoadRegionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedRoadRegionsTable> {
  $$DownloadedRoadRegionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get regionId =>
      $composableBuilder(column: $table.regionId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadedRoadRegionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedRoadRegionsTable,
          DownloadedRoadRegion,
          $$DownloadedRoadRegionsTableFilterComposer,
          $$DownloadedRoadRegionsTableOrderingComposer,
          $$DownloadedRoadRegionsTableAnnotationComposer,
          $$DownloadedRoadRegionsTableCreateCompanionBuilder,
          $$DownloadedRoadRegionsTableUpdateCompanionBuilder,
          (
            DownloadedRoadRegion,
            BaseReferences<
              _$AppDatabase,
              $DownloadedRoadRegionsTable,
              DownloadedRoadRegion
            >,
          ),
          DownloadedRoadRegion,
          PrefetchHooks Function()
        > {
  $$DownloadedRoadRegionsTableTableManager(
    _$AppDatabase db,
    $DownloadedRoadRegionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedRoadRegionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DownloadedRoadRegionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadedRoadRegionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> regionId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedRoadRegionsCompanion(
                regionId: regionId,
                filePath: filePath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String regionId,
                required String filePath,
                required int sizeBytes,
                required DateTime downloadedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadedRoadRegionsCompanion.insert(
                regionId: regionId,
                filePath: filePath,
                sizeBytes: sizeBytes,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedRoadRegionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedRoadRegionsTable,
      DownloadedRoadRegion,
      $$DownloadedRoadRegionsTableFilterComposer,
      $$DownloadedRoadRegionsTableOrderingComposer,
      $$DownloadedRoadRegionsTableAnnotationComposer,
      $$DownloadedRoadRegionsTableCreateCompanionBuilder,
      $$DownloadedRoadRegionsTableUpdateCompanionBuilder,
      (
        DownloadedRoadRegion,
        BaseReferences<
          _$AppDatabase,
          $DownloadedRoadRegionsTable,
          DownloadedRoadRegion
        >,
      ),
      DownloadedRoadRegion,
      PrefetchHooks Function()
    >;
typedef $$SavedPlacesTableCreateCompanionBuilder =
    SavedPlacesCompanion Function({
      Value<int> id,
      required String name,
      required double latitude,
      required double longitude,
      Value<String> kind,
      required DateTime createdAt,
    });
typedef $$SavedPlacesTableUpdateCompanionBuilder =
    SavedPlacesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> kind,
      Value<DateTime> createdAt,
    });

class $$SavedPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedPlacesTable> {
  $$SavedPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedPlacesTable,
          SavedPlace,
          $$SavedPlacesTableFilterComposer,
          $$SavedPlacesTableOrderingComposer,
          $$SavedPlacesTableAnnotationComposer,
          $$SavedPlacesTableCreateCompanionBuilder,
          $$SavedPlacesTableUpdateCompanionBuilder,
          (
            SavedPlace,
            BaseReferences<_$AppDatabase, $SavedPlacesTable, SavedPlace>,
          ),
          SavedPlace,
          PrefetchHooks Function()
        > {
  $$SavedPlacesTableTableManager(_$AppDatabase db, $SavedPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SavedPlacesCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                kind: kind,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double latitude,
                required double longitude,
                Value<String> kind = const Value.absent(),
                required DateTime createdAt,
              }) => SavedPlacesCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                kind: kind,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedPlacesTable,
      SavedPlace,
      $$SavedPlacesTableFilterComposer,
      $$SavedPlacesTableOrderingComposer,
      $$SavedPlacesTableAnnotationComposer,
      $$SavedPlacesTableCreateCompanionBuilder,
      $$SavedPlacesTableUpdateCompanionBuilder,
      (
        SavedPlace,
        BaseReferences<_$AppDatabase, $SavedPlacesTable, SavedPlace>,
      ),
      SavedPlace,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$DownloadedElevationTilesTableTableManager get downloadedElevationTiles =>
      $$DownloadedElevationTilesTableTableManager(
        _db,
        _db.downloadedElevationTiles,
      );
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
  $$SegmentEffortsTableTableManager get segmentEfforts =>
      $$SegmentEffortsTableTableManager(_db, _db.segmentEfforts);
  $$DownloadedRoadRegionsTableTableManager get downloadedRoadRegions =>
      $$DownloadedRoadRegionsTableTableManager(_db, _db.downloadedRoadRegions);
  $$SavedPlacesTableTableManager get savedPlaces =>
      $$SavedPlacesTableTableManager(_db, _db.savedPlaces);
}
