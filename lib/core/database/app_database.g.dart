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
  static const VerificationMeta _bikeIdMeta = const VerificationMeta('bikeId');
  @override
  late final GeneratedColumn<int> bikeId = GeneratedColumn<int>(
    'bike_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    bikeId,
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
    if (data.containsKey('bike_id')) {
      context.handle(
        _bikeIdMeta,
        bikeId.isAcceptableOrUnknown(data['bike_id']!, _bikeIdMeta),
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
      bikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bike_id'],
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

  /// Bicicleta con la que se hizo, si el ciclista la tenía registrada.
  /// El nombre se sigue guardando en [bikeName] para que una actividad
  /// vieja (o una bici borrada) siga diciendo con qué se hizo.
  final int? bikeId;
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
    this.bikeId,
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
    if (!nullToAbsent || bikeId != null) {
      map['bike_id'] = Variable<int>(bikeId);
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
      bikeId: bikeId == null && nullToAbsent
          ? const Value.absent()
          : Value(bikeId),
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
      bikeId: serializer.fromJson<int?>(json['bikeId']),
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
      'bikeId': serializer.toJson<int?>(bikeId),
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
    Value<int?> bikeId = const Value.absent(),
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
    bikeId: bikeId.present ? bikeId.value : this.bikeId,
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
      bikeId: data.bikeId.present ? data.bikeId.value : this.bikeId,
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
          ..write('bikeId: $bikeId, ')
          ..write('routePointsJson: $routePointsJson, ')
          ..write('photoPathsJson: $photoPathsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    bikeId,
    routePointsJson,
    photoPathsJson,
  ]);
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
          other.bikeId == this.bikeId &&
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
  final Value<int?> bikeId;
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
    this.bikeId = const Value.absent(),
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
    this.bikeId = const Value.absent(),
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
    Expression<int>? bikeId,
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
      if (bikeId != null) 'bike_id': bikeId,
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
    Value<int?>? bikeId,
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
      bikeId: bikeId ?? this.bikeId,
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
    if (bikeId.present) {
      map['bike_id'] = Variable<int>(bikeId.value);
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
          ..write('bikeId: $bikeId, ')
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

class $RecordingSessionsTable extends RecordingSessions
    with TableInfo<$RecordingSessionsTable, RecordingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _movingMillisMeta = const VerificationMeta(
    'movingMillis',
  );
  @override
  late final GeneratedColumn<int> movingMillis = GeneratedColumn<int>(
    'moving_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPausedMeta = const VerificationMeta(
    'isPaused',
  );
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
    'is_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    id,
    startedAt,
    movingMillis,
    isPaused,
    endedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('moving_millis')) {
      context.handle(
        _movingMillisMeta,
        movingMillis.isAcceptableOrUnknown(
          data['moving_millis']!,
          _movingMillisMeta,
        ),
      );
    }
    if (data.containsKey('is_paused')) {
      context.handle(
        _isPausedMeta,
        isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      movingMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_millis'],
      )!,
      isPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paused'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecordingSessionsTable createAlias(String alias) {
    return $RecordingSessionsTable(attachedDatabase, alias);
  }
}

class RecordingSession extends DataClass
    implements Insertable<RecordingSession> {
  final int id;
  final DateTime startedAt;

  /// Tiempo en movimiento (sin pausas) acumulado hasta la última
  /// escritura, en milisegundos. Lo que pase entre esa escritura y la
  /// reapertura de la app se trata como pausa.
  final int movingMillis;
  final bool isPaused;

  /// Cuándo se tocó "Terminar". `null` mientras se sigue grabando; con
  /// valor, la app se cerró ya en la pantalla de guardar.
  final DateTime? endedAt;
  final DateTime updatedAt;
  const RecordingSession({
    required this.id,
    required this.startedAt,
    required this.movingMillis,
    required this.isPaused,
    this.endedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['moving_millis'] = Variable<int>(movingMillis);
    map['is_paused'] = Variable<bool>(isPaused);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecordingSessionsCompanion toCompanion(bool nullToAbsent) {
    return RecordingSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      movingMillis: Value(movingMillis),
      isPaused: Value(isPaused),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecordingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingSession(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      movingMillis: serializer.fromJson<int>(json['movingMillis']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'movingMillis': serializer.toJson<int>(movingMillis),
      'isPaused': serializer.toJson<bool>(isPaused),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecordingSession copyWith({
    int? id,
    DateTime? startedAt,
    int? movingMillis,
    bool? isPaused,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => RecordingSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    movingMillis: movingMillis ?? this.movingMillis,
    isPaused: isPaused ?? this.isPaused,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecordingSession copyWithCompanion(RecordingSessionsCompanion data) {
    return RecordingSession(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      movingMillis: data.movingMillis.present
          ? data.movingMillis.value
          : this.movingMillis,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSession(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('movingMillis: $movingMillis, ')
          ..write('isPaused: $isPaused, ')
          ..write('endedAt: $endedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, movingMillis, isPaused, endedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingSession &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.movingMillis == this.movingMillis &&
          other.isPaused == this.isPaused &&
          other.endedAt == this.endedAt &&
          other.updatedAt == this.updatedAt);
}

class RecordingSessionsCompanion extends UpdateCompanion<RecordingSession> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<int> movingMillis;
  final Value<bool> isPaused;
  final Value<DateTime?> endedAt;
  final Value<DateTime> updatedAt;
  const RecordingSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.movingMillis = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecordingSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.movingMillis = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.endedAt = const Value.absent(),
    required DateTime updatedAt,
  }) : startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecordingSession> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? movingMillis,
    Expression<bool>? isPaused,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (movingMillis != null) 'moving_millis': movingMillis,
      if (isPaused != null) 'is_paused': isPaused,
      if (endedAt != null) 'ended_at': endedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecordingSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<int>? movingMillis,
    Value<bool>? isPaused,
    Value<DateTime?>? endedAt,
    Value<DateTime>? updatedAt,
  }) {
    return RecordingSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      movingMillis: movingMillis ?? this.movingMillis,
      isPaused: isPaused ?? this.isPaused,
      endedAt: endedAt ?? this.endedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (movingMillis.present) {
      map['moving_millis'] = Variable<int>(movingMillis.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('movingMillis: $movingMillis, ')
          ..write('isPaused: $isPaused, ')
          ..write('endedAt: $endedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RecordingPointsTable extends RecordingPoints
    with TableInfo<$RecordingPointsTable, RecordingPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMetersPerSecondMeta =
      const VerificationMeta('speedMetersPerSecond');
  @override
  late final GeneratedColumn<double> speedMetersPerSecond =
      GeneratedColumn<double>(
        'speed_meters_per_second',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bearingDegreesMeta = const VerificationMeta(
    'bearingDegrees',
  );
  @override
  late final GeneratedColumn<double> bearingDegrees = GeneratedColumn<double>(
    'bearing_degrees',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMetersMeta = const VerificationMeta(
    'accuracyMeters',
  );
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
    'accuracy_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMillisMeta = const VerificationMeta(
    'timestampMillis',
  );
  @override
  late final GeneratedColumn<int> timestampMillis = GeneratedColumn<int>(
    'timestamp_millis',
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
  static const VerificationMeta _speedKmhMeta = const VerificationMeta(
    'speedKmh',
  );
  @override
  late final GeneratedColumn<double> speedKmh = GeneratedColumn<double>(
    'speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    latitude,
    longitude,
    altitude,
    speedMetersPerSecond,
    bearingDegrees,
    accuracyMeters,
    timestampMillis,
    distanceMeters,
    speedKmh,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
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
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_altitudeMeta);
    }
    if (data.containsKey('speed_meters_per_second')) {
      context.handle(
        _speedMetersPerSecondMeta,
        speedMetersPerSecond.isAcceptableOrUnknown(
          data['speed_meters_per_second']!,
          _speedMetersPerSecondMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_speedMetersPerSecondMeta);
    }
    if (data.containsKey('bearing_degrees')) {
      context.handle(
        _bearingDegreesMeta,
        bearingDegrees.isAcceptableOrUnknown(
          data['bearing_degrees']!,
          _bearingDegreesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bearingDegreesMeta);
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
        _accuracyMetersMeta,
        accuracyMeters.isAcceptableOrUnknown(
          data['accuracy_meters']!,
          _accuracyMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accuracyMetersMeta);
    }
    if (data.containsKey('timestamp_millis')) {
      context.handle(
        _timestampMillisMeta,
        timestampMillis.isAcceptableOrUnknown(
          data['timestamp_millis']!,
          _timestampMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMillisMeta);
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
    if (data.containsKey('speed_kmh')) {
      context.handle(
        _speedKmhMeta,
        speedKmh.isAcceptableOrUnknown(data['speed_kmh']!, _speedKmhMeta),
      );
    } else if (isInserting) {
      context.missing(_speedKmhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      )!,
      speedMetersPerSecond: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_meters_per_second'],
      )!,
      bearingDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bearing_degrees'],
      )!,
      accuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_meters'],
      )!,
      timestampMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_millis'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      speedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_kmh'],
      )!,
    );
  }

  @override
  $RecordingPointsTable createAlias(String alias) {
    return $RecordingPointsTable(attachedDatabase, alias);
  }
}

class RecordingPoint extends DataClass implements Insertable<RecordingPoint> {
  final int id;
  final int sessionId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedMetersPerSecond;
  final double bearingDegrees;
  final double accuracyMeters;
  final int timestampMillis;
  final double distanceMeters;
  final double speedKmh;
  const RecordingPoint({
    required this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedMetersPerSecond,
    required this.bearingDegrees,
    required this.accuracyMeters,
    required this.timestampMillis,
    required this.distanceMeters,
    required this.speedKmh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['altitude'] = Variable<double>(altitude);
    map['speed_meters_per_second'] = Variable<double>(speedMetersPerSecond);
    map['bearing_degrees'] = Variable<double>(bearingDegrees);
    map['accuracy_meters'] = Variable<double>(accuracyMeters);
    map['timestamp_millis'] = Variable<int>(timestampMillis);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['speed_kmh'] = Variable<double>(speedKmh);
    return map;
  }

  RecordingPointsCompanion toCompanion(bool nullToAbsent) {
    return RecordingPointsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitude: Value(altitude),
      speedMetersPerSecond: Value(speedMetersPerSecond),
      bearingDegrees: Value(bearingDegrees),
      accuracyMeters: Value(accuracyMeters),
      timestampMillis: Value(timestampMillis),
      distanceMeters: Value(distanceMeters),
      speedKmh: Value(speedKmh),
    );
  }

  factory RecordingPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingPoint(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitude: serializer.fromJson<double>(json['altitude']),
      speedMetersPerSecond: serializer.fromJson<double>(
        json['speedMetersPerSecond'],
      ),
      bearingDegrees: serializer.fromJson<double>(json['bearingDegrees']),
      accuracyMeters: serializer.fromJson<double>(json['accuracyMeters']),
      timestampMillis: serializer.fromJson<int>(json['timestampMillis']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      speedKmh: serializer.fromJson<double>(json['speedKmh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitude': serializer.toJson<double>(altitude),
      'speedMetersPerSecond': serializer.toJson<double>(speedMetersPerSecond),
      'bearingDegrees': serializer.toJson<double>(bearingDegrees),
      'accuracyMeters': serializer.toJson<double>(accuracyMeters),
      'timestampMillis': serializer.toJson<int>(timestampMillis),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'speedKmh': serializer.toJson<double>(speedKmh),
    };
  }

  RecordingPoint copyWith({
    int? id,
    int? sessionId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speedMetersPerSecond,
    double? bearingDegrees,
    double? accuracyMeters,
    int? timestampMillis,
    double? distanceMeters,
    double? speedKmh,
  }) => RecordingPoint(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude ?? this.altitude,
    speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
    bearingDegrees: bearingDegrees ?? this.bearingDegrees,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    timestampMillis: timestampMillis ?? this.timestampMillis,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    speedKmh: speedKmh ?? this.speedKmh,
  );
  RecordingPoint copyWithCompanion(RecordingPointsCompanion data) {
    return RecordingPoint(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speedMetersPerSecond: data.speedMetersPerSecond.present
          ? data.speedMetersPerSecond.value
          : this.speedMetersPerSecond,
      bearingDegrees: data.bearingDegrees.present
          ? data.bearingDegrees.value
          : this.bearingDegrees,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
      timestampMillis: data.timestampMillis.present
          ? data.timestampMillis.value
          : this.timestampMillis,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      speedKmh: data.speedKmh.present ? data.speedKmh.value : this.speedKmh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingPoint(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('speedMetersPerSecond: $speedMetersPerSecond, ')
          ..write('bearingDegrees: $bearingDegrees, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestampMillis: $timestampMillis, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('speedKmh: $speedKmh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    latitude,
    longitude,
    altitude,
    speedMetersPerSecond,
    bearingDegrees,
    accuracyMeters,
    timestampMillis,
    distanceMeters,
    speedKmh,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingPoint &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.speedMetersPerSecond == this.speedMetersPerSecond &&
          other.bearingDegrees == this.bearingDegrees &&
          other.accuracyMeters == this.accuracyMeters &&
          other.timestampMillis == this.timestampMillis &&
          other.distanceMeters == this.distanceMeters &&
          other.speedKmh == this.speedKmh);
}

class RecordingPointsCompanion extends UpdateCompanion<RecordingPoint> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> altitude;
  final Value<double> speedMetersPerSecond;
  final Value<double> bearingDegrees;
  final Value<double> accuracyMeters;
  final Value<int> timestampMillis;
  final Value<double> distanceMeters;
  final Value<double> speedKmh;
  const RecordingPointsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speedMetersPerSecond = const Value.absent(),
    this.bearingDegrees = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.timestampMillis = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.speedKmh = const Value.absent(),
  });
  RecordingPointsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required double latitude,
    required double longitude,
    required double altitude,
    required double speedMetersPerSecond,
    required double bearingDegrees,
    required double accuracyMeters,
    required int timestampMillis,
    required double distanceMeters,
    required double speedKmh,
  }) : sessionId = Value(sessionId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       altitude = Value(altitude),
       speedMetersPerSecond = Value(speedMetersPerSecond),
       bearingDegrees = Value(bearingDegrees),
       accuracyMeters = Value(accuracyMeters),
       timestampMillis = Value(timestampMillis),
       distanceMeters = Value(distanceMeters),
       speedKmh = Value(speedKmh);
  static Insertable<RecordingPoint> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? speedMetersPerSecond,
    Expression<double>? bearingDegrees,
    Expression<double>? accuracyMeters,
    Expression<int>? timestampMillis,
    Expression<double>? distanceMeters,
    Expression<double>? speedKmh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (speedMetersPerSecond != null)
        'speed_meters_per_second': speedMetersPerSecond,
      if (bearingDegrees != null) 'bearing_degrees': bearingDegrees,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (timestampMillis != null) 'timestamp_millis': timestampMillis,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (speedKmh != null) 'speed_kmh': speedKmh,
    });
  }

  RecordingPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? altitude,
    Value<double>? speedMetersPerSecond,
    Value<double>? bearingDegrees,
    Value<double>? accuracyMeters,
    Value<int>? timestampMillis,
    Value<double>? distanceMeters,
    Value<double>? speedKmh,
  }) {
    return RecordingPointsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      bearingDegrees: bearingDegrees ?? this.bearingDegrees,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestampMillis: timestampMillis ?? this.timestampMillis,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speedMetersPerSecond.present) {
      map['speed_meters_per_second'] = Variable<double>(
        speedMetersPerSecond.value,
      );
    }
    if (bearingDegrees.present) {
      map['bearing_degrees'] = Variable<double>(bearingDegrees.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (timestampMillis.present) {
      map['timestamp_millis'] = Variable<int>(timestampMillis.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (speedKmh.present) {
      map['speed_kmh'] = Variable<double>(speedKmh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingPointsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('speedMetersPerSecond: $speedMetersPerSecond, ')
          ..write('bearingDegrees: $bearingDegrees, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('timestampMillis: $timestampMillis, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('speedKmh: $speedKmh')
          ..write(')'))
        .toString();
  }
}

class $RecordingSensorSamplesTable extends RecordingSensorSamples
    with TableInfo<$RecordingSensorSamplesTable, RecordingSensorSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingSensorSamplesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMillisMeta = const VerificationMeta(
    'timestampMillis',
  );
  @override
  late final GeneratedColumn<int> timestampMillis = GeneratedColumn<int>(
    'timestamp_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    kind,
    timestampMillis,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_sensor_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingSensorSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('timestamp_millis')) {
      context.handle(
        _timestampMillisMeta,
        timestampMillis.isAcceptableOrUnknown(
          data['timestamp_millis']!,
          _timestampMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMillisMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingSensorSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingSensorSample(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      timestampMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_millis'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $RecordingSensorSamplesTable createAlias(String alias) {
    return $RecordingSensorSamplesTable(attachedDatabase, alias);
  }
}

class RecordingSensorSample extends DataClass
    implements Insertable<RecordingSensorSample> {
  final int id;
  final int sessionId;

  /// 'hr' | 'power' | 'cadence' -- ver `RecordingSampleKind`.
  final String kind;
  final int timestampMillis;
  final double value;
  const RecordingSensorSample({
    required this.id,
    required this.sessionId,
    required this.kind,
    required this.timestampMillis,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['kind'] = Variable<String>(kind);
    map['timestamp_millis'] = Variable<int>(timestampMillis);
    map['value'] = Variable<double>(value);
    return map;
  }

  RecordingSensorSamplesCompanion toCompanion(bool nullToAbsent) {
    return RecordingSensorSamplesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kind: Value(kind),
      timestampMillis: Value(timestampMillis),
      value: Value(value),
    );
  }

  factory RecordingSensorSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingSensorSample(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      kind: serializer.fromJson<String>(json['kind']),
      timestampMillis: serializer.fromJson<int>(json['timestampMillis']),
      value: serializer.fromJson<double>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'kind': serializer.toJson<String>(kind),
      'timestampMillis': serializer.toJson<int>(timestampMillis),
      'value': serializer.toJson<double>(value),
    };
  }

  RecordingSensorSample copyWith({
    int? id,
    int? sessionId,
    String? kind,
    int? timestampMillis,
    double? value,
  }) => RecordingSensorSample(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    kind: kind ?? this.kind,
    timestampMillis: timestampMillis ?? this.timestampMillis,
    value: value ?? this.value,
  );
  RecordingSensorSample copyWithCompanion(
    RecordingSensorSamplesCompanion data,
  ) {
    return RecordingSensorSample(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      timestampMillis: data.timestampMillis.present
          ? data.timestampMillis.value
          : this.timestampMillis,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSensorSample(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('timestampMillis: $timestampMillis, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, kind, timestampMillis, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingSensorSample &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.timestampMillis == this.timestampMillis &&
          other.value == this.value);
}

class RecordingSensorSamplesCompanion
    extends UpdateCompanion<RecordingSensorSample> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> kind;
  final Value<int> timestampMillis;
  final Value<double> value;
  const RecordingSensorSamplesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.timestampMillis = const Value.absent(),
    this.value = const Value.absent(),
  });
  RecordingSensorSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String kind,
    required int timestampMillis,
    required double value,
  }) : sessionId = Value(sessionId),
       kind = Value(kind),
       timestampMillis = Value(timestampMillis),
       value = Value(value);
  static Insertable<RecordingSensorSample> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? kind,
    Expression<int>? timestampMillis,
    Expression<double>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (timestampMillis != null) 'timestamp_millis': timestampMillis,
      if (value != null) 'value': value,
    });
  }

  RecordingSensorSamplesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? kind,
    Value<int>? timestampMillis,
    Value<double>? value,
  }) {
    return RecordingSensorSamplesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      timestampMillis: timestampMillis ?? this.timestampMillis,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (timestampMillis.present) {
      map['timestamp_millis'] = Variable<int>(timestampMillis.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingSensorSamplesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('timestampMillis: $timestampMillis, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $ActivityCurvesTable extends ActivityCurves
    with TableInfo<$ActivityCurvesTable, ActivityCurve> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityCurvesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movingSecondsMeta = const VerificationMeta(
    'movingSeconds',
  );
  @override
  late final GeneratedColumn<int> movingSeconds = GeneratedColumn<int>(
    'moving_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _powerSecondsMeta = const VerificationMeta(
    'powerSeconds',
  );
  @override
  late final GeneratedColumn<int> powerSeconds = GeneratedColumn<int>(
    'power_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heartRateSecondsMeta = const VerificationMeta(
    'heartRateSeconds',
  );
  @override
  late final GeneratedColumn<int> heartRateSeconds = GeneratedColumn<int>(
    'heart_rate_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _climbingCadenceMeta = const VerificationMeta(
    'climbingCadence',
  );
  @override
  late final GeneratedColumn<double> climbingCadence = GeneratedColumn<double>(
    'climbing_cadence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    activityId,
    version,
    movingSeconds,
    powerSeconds,
    heartRateSeconds,
    climbingCadence,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_curves';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityCurve> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('moving_seconds')) {
      context.handle(
        _movingSecondsMeta,
        movingSeconds.isAcceptableOrUnknown(
          data['moving_seconds']!,
          _movingSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movingSecondsMeta);
    }
    if (data.containsKey('power_seconds')) {
      context.handle(
        _powerSecondsMeta,
        powerSeconds.isAcceptableOrUnknown(
          data['power_seconds']!,
          _powerSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_powerSecondsMeta);
    }
    if (data.containsKey('heart_rate_seconds')) {
      context.handle(
        _heartRateSecondsMeta,
        heartRateSeconds.isAcceptableOrUnknown(
          data['heart_rate_seconds']!,
          _heartRateSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heartRateSecondsMeta);
    }
    if (data.containsKey('climbing_cadence')) {
      context.handle(
        _climbingCadenceMeta,
        climbingCadence.isAcceptableOrUnknown(
          data['climbing_cadence']!,
          _climbingCadenceMeta,
        ),
      );
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityId};
  @override
  ActivityCurve map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityCurve(
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      movingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_seconds'],
      )!,
      powerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}power_seconds'],
      )!,
      heartRateSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate_seconds'],
      )!,
      climbingCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}climbing_cadence'],
      ),
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $ActivityCurvesTable createAlias(String alias) {
    return $ActivityCurvesTable(attachedDatabase, alias);
  }
}

class ActivityCurve extends DataClass implements Insertable<ActivityCurve> {
  final int activityId;
  final int version;

  /// Largo de la serie de 1 Hz (tiempo en movimiento) y cuántos de esos
  /// segundos tuvieron lectura de cada sensor.
  final int movingSeconds;
  final int powerSeconds;
  final int heartRateSeconds;

  /// Mediana de la cadencia subiendo (rpm). De acá sale la referencia
  /// con la que el coach mide el torque. `null` si la salida no trajo
  /// subida con cadencia.
  final double? climbingCadence;
  final DateTime computedAt;
  const ActivityCurve({
    required this.activityId,
    required this.version,
    required this.movingSeconds,
    required this.powerSeconds,
    required this.heartRateSeconds,
    this.climbingCadence,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_id'] = Variable<int>(activityId);
    map['version'] = Variable<int>(version);
    map['moving_seconds'] = Variable<int>(movingSeconds);
    map['power_seconds'] = Variable<int>(powerSeconds);
    map['heart_rate_seconds'] = Variable<int>(heartRateSeconds);
    if (!nullToAbsent || climbingCadence != null) {
      map['climbing_cadence'] = Variable<double>(climbingCadence);
    }
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  ActivityCurvesCompanion toCompanion(bool nullToAbsent) {
    return ActivityCurvesCompanion(
      activityId: Value(activityId),
      version: Value(version),
      movingSeconds: Value(movingSeconds),
      powerSeconds: Value(powerSeconds),
      heartRateSeconds: Value(heartRateSeconds),
      climbingCadence: climbingCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(climbingCadence),
      computedAt: Value(computedAt),
    );
  }

  factory ActivityCurve.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityCurve(
      activityId: serializer.fromJson<int>(json['activityId']),
      version: serializer.fromJson<int>(json['version']),
      movingSeconds: serializer.fromJson<int>(json['movingSeconds']),
      powerSeconds: serializer.fromJson<int>(json['powerSeconds']),
      heartRateSeconds: serializer.fromJson<int>(json['heartRateSeconds']),
      climbingCadence: serializer.fromJson<double?>(json['climbingCadence']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityId': serializer.toJson<int>(activityId),
      'version': serializer.toJson<int>(version),
      'movingSeconds': serializer.toJson<int>(movingSeconds),
      'powerSeconds': serializer.toJson<int>(powerSeconds),
      'heartRateSeconds': serializer.toJson<int>(heartRateSeconds),
      'climbingCadence': serializer.toJson<double?>(climbingCadence),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  ActivityCurve copyWith({
    int? activityId,
    int? version,
    int? movingSeconds,
    int? powerSeconds,
    int? heartRateSeconds,
    Value<double?> climbingCadence = const Value.absent(),
    DateTime? computedAt,
  }) => ActivityCurve(
    activityId: activityId ?? this.activityId,
    version: version ?? this.version,
    movingSeconds: movingSeconds ?? this.movingSeconds,
    powerSeconds: powerSeconds ?? this.powerSeconds,
    heartRateSeconds: heartRateSeconds ?? this.heartRateSeconds,
    climbingCadence: climbingCadence.present
        ? climbingCadence.value
        : this.climbingCadence,
    computedAt: computedAt ?? this.computedAt,
  );
  ActivityCurve copyWithCompanion(ActivityCurvesCompanion data) {
    return ActivityCurve(
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      version: data.version.present ? data.version.value : this.version,
      movingSeconds: data.movingSeconds.present
          ? data.movingSeconds.value
          : this.movingSeconds,
      powerSeconds: data.powerSeconds.present
          ? data.powerSeconds.value
          : this.powerSeconds,
      heartRateSeconds: data.heartRateSeconds.present
          ? data.heartRateSeconds.value
          : this.heartRateSeconds,
      climbingCadence: data.climbingCadence.present
          ? data.climbingCadence.value
          : this.climbingCadence,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityCurve(')
          ..write('activityId: $activityId, ')
          ..write('version: $version, ')
          ..write('movingSeconds: $movingSeconds, ')
          ..write('powerSeconds: $powerSeconds, ')
          ..write('heartRateSeconds: $heartRateSeconds, ')
          ..write('climbingCadence: $climbingCadence, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    activityId,
    version,
    movingSeconds,
    powerSeconds,
    heartRateSeconds,
    climbingCadence,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityCurve &&
          other.activityId == this.activityId &&
          other.version == this.version &&
          other.movingSeconds == this.movingSeconds &&
          other.powerSeconds == this.powerSeconds &&
          other.heartRateSeconds == this.heartRateSeconds &&
          other.climbingCadence == this.climbingCadence &&
          other.computedAt == this.computedAt);
}

class ActivityCurvesCompanion extends UpdateCompanion<ActivityCurve> {
  final Value<int> activityId;
  final Value<int> version;
  final Value<int> movingSeconds;
  final Value<int> powerSeconds;
  final Value<int> heartRateSeconds;
  final Value<double?> climbingCadence;
  final Value<DateTime> computedAt;
  const ActivityCurvesCompanion({
    this.activityId = const Value.absent(),
    this.version = const Value.absent(),
    this.movingSeconds = const Value.absent(),
    this.powerSeconds = const Value.absent(),
    this.heartRateSeconds = const Value.absent(),
    this.climbingCadence = const Value.absent(),
    this.computedAt = const Value.absent(),
  });
  ActivityCurvesCompanion.insert({
    this.activityId = const Value.absent(),
    required int version,
    required int movingSeconds,
    required int powerSeconds,
    required int heartRateSeconds,
    this.climbingCadence = const Value.absent(),
    required DateTime computedAt,
  }) : version = Value(version),
       movingSeconds = Value(movingSeconds),
       powerSeconds = Value(powerSeconds),
       heartRateSeconds = Value(heartRateSeconds),
       computedAt = Value(computedAt);
  static Insertable<ActivityCurve> custom({
    Expression<int>? activityId,
    Expression<int>? version,
    Expression<int>? movingSeconds,
    Expression<int>? powerSeconds,
    Expression<int>? heartRateSeconds,
    Expression<double>? climbingCadence,
    Expression<DateTime>? computedAt,
  }) {
    return RawValuesInsertable({
      if (activityId != null) 'activity_id': activityId,
      if (version != null) 'version': version,
      if (movingSeconds != null) 'moving_seconds': movingSeconds,
      if (powerSeconds != null) 'power_seconds': powerSeconds,
      if (heartRateSeconds != null) 'heart_rate_seconds': heartRateSeconds,
      if (climbingCadence != null) 'climbing_cadence': climbingCadence,
      if (computedAt != null) 'computed_at': computedAt,
    });
  }

  ActivityCurvesCompanion copyWith({
    Value<int>? activityId,
    Value<int>? version,
    Value<int>? movingSeconds,
    Value<int>? powerSeconds,
    Value<int>? heartRateSeconds,
    Value<double?>? climbingCadence,
    Value<DateTime>? computedAt,
  }) {
    return ActivityCurvesCompanion(
      activityId: activityId ?? this.activityId,
      version: version ?? this.version,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      powerSeconds: powerSeconds ?? this.powerSeconds,
      heartRateSeconds: heartRateSeconds ?? this.heartRateSeconds,
      climbingCadence: climbingCadence ?? this.climbingCadence,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (movingSeconds.present) {
      map['moving_seconds'] = Variable<int>(movingSeconds.value);
    }
    if (powerSeconds.present) {
      map['power_seconds'] = Variable<int>(powerSeconds.value);
    }
    if (heartRateSeconds.present) {
      map['heart_rate_seconds'] = Variable<int>(heartRateSeconds.value);
    }
    if (climbingCadence.present) {
      map['climbing_cadence'] = Variable<double>(climbingCadence.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityCurvesCompanion(')
          ..write('activityId: $activityId, ')
          ..write('version: $version, ')
          ..write('movingSeconds: $movingSeconds, ')
          ..write('powerSeconds: $powerSeconds, ')
          ..write('heartRateSeconds: $heartRateSeconds, ')
          ..write('climbingCadence: $climbingCadence, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityCurvePointsTable extends ActivityCurvePoints
    with TableInfo<$ActivityCurvePointsTable, ActivityCurvePoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityCurvePointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startSecondMeta = const VerificationMeta(
    'startSecond',
  );
  @override
  late final GeneratedColumn<int> startSecond = GeneratedColumn<int>(
    'start_second',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    activityId,
    kind,
    durationSeconds,
    value,
    startSecond,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_curve_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityCurvePoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('start_second')) {
      context.handle(
        _startSecondMeta,
        startSecond.isAcceptableOrUnknown(
          data['start_second']!,
          _startSecondMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSecondMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {activityId, kind, durationSeconds};
  @override
  ActivityCurvePoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityCurvePoint(
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      startSecond: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_second'],
      )!,
    );
  }

  @override
  $ActivityCurvePointsTable createAlias(String alias) {
    return $ActivityCurvePointsTable(attachedDatabase, alias);
  }
}

class ActivityCurvePoint extends DataClass
    implements Insertable<ActivityCurvePoint> {
  final int activityId;

  /// 'power' | 'heartRate' -- ver `CurveKind` en stats.
  final String kind;
  final int durationSeconds;
  final double value;

  /// Segundo (en movimiento) donde empieza ese mejor esfuerzo.
  final int startSecond;
  const ActivityCurvePoint({
    required this.activityId,
    required this.kind,
    required this.durationSeconds,
    required this.value,
    required this.startSecond,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['activity_id'] = Variable<int>(activityId);
    map['kind'] = Variable<String>(kind);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['value'] = Variable<double>(value);
    map['start_second'] = Variable<int>(startSecond);
    return map;
  }

  ActivityCurvePointsCompanion toCompanion(bool nullToAbsent) {
    return ActivityCurvePointsCompanion(
      activityId: Value(activityId),
      kind: Value(kind),
      durationSeconds: Value(durationSeconds),
      value: Value(value),
      startSecond: Value(startSecond),
    );
  }

  factory ActivityCurvePoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityCurvePoint(
      activityId: serializer.fromJson<int>(json['activityId']),
      kind: serializer.fromJson<String>(json['kind']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      value: serializer.fromJson<double>(json['value']),
      startSecond: serializer.fromJson<int>(json['startSecond']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'activityId': serializer.toJson<int>(activityId),
      'kind': serializer.toJson<String>(kind),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'value': serializer.toJson<double>(value),
      'startSecond': serializer.toJson<int>(startSecond),
    };
  }

  ActivityCurvePoint copyWith({
    int? activityId,
    String? kind,
    int? durationSeconds,
    double? value,
    int? startSecond,
  }) => ActivityCurvePoint(
    activityId: activityId ?? this.activityId,
    kind: kind ?? this.kind,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    value: value ?? this.value,
    startSecond: startSecond ?? this.startSecond,
  );
  ActivityCurvePoint copyWithCompanion(ActivityCurvePointsCompanion data) {
    return ActivityCurvePoint(
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      value: data.value.present ? data.value.value : this.value,
      startSecond: data.startSecond.present
          ? data.startSecond.value
          : this.startSecond,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityCurvePoint(')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('value: $value, ')
          ..write('startSecond: $startSecond')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(activityId, kind, durationSeconds, value, startSecond);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityCurvePoint &&
          other.activityId == this.activityId &&
          other.kind == this.kind &&
          other.durationSeconds == this.durationSeconds &&
          other.value == this.value &&
          other.startSecond == this.startSecond);
}

class ActivityCurvePointsCompanion extends UpdateCompanion<ActivityCurvePoint> {
  final Value<int> activityId;
  final Value<String> kind;
  final Value<int> durationSeconds;
  final Value<double> value;
  final Value<int> startSecond;
  final Value<int> rowid;
  const ActivityCurvePointsCompanion({
    this.activityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.value = const Value.absent(),
    this.startSecond = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityCurvePointsCompanion.insert({
    required int activityId,
    required String kind,
    required int durationSeconds,
    required double value,
    required int startSecond,
    this.rowid = const Value.absent(),
  }) : activityId = Value(activityId),
       kind = Value(kind),
       durationSeconds = Value(durationSeconds),
       value = Value(value),
       startSecond = Value(startSecond);
  static Insertable<ActivityCurvePoint> custom({
    Expression<int>? activityId,
    Expression<String>? kind,
    Expression<int>? durationSeconds,
    Expression<double>? value,
    Expression<int>? startSecond,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (activityId != null) 'activity_id': activityId,
      if (kind != null) 'kind': kind,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (value != null) 'value': value,
      if (startSecond != null) 'start_second': startSecond,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityCurvePointsCompanion copyWith({
    Value<int>? activityId,
    Value<String>? kind,
    Value<int>? durationSeconds,
    Value<double>? value,
    Value<int>? startSecond,
    Value<int>? rowid,
  }) {
    return ActivityCurvePointsCompanion(
      activityId: activityId ?? this.activityId,
      kind: kind ?? this.kind,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      value: value ?? this.value,
      startSecond: startSecond ?? this.startSecond,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (startSecond.present) {
      map['start_second'] = Variable<int>(startSecond.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityCurvePointsCompanion(')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('value: $value, ')
          ..write('startSecond: $startSecond, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoachingAdvicesTable extends CoachingAdvices
    with TableInfo<$CoachingAdvicesTable, CoachingAdvice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachingAdvicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rideStartedAtMeta = const VerificationMeta(
    'rideStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rideStartedAt =
      GeneratedColumn<DateTime>(
        'ride_started_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
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
  static const VerificationMeta _secondMeta = const VerificationMeta('second');
  @override
  late final GeneratedColumn<int> second = GeneratedColumn<int>(
    'second',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alongMetersMeta = const VerificationMeta(
    'alongMeters',
  );
  @override
  late final GeneratedColumn<double> alongMeters = GeneratedColumn<double>(
    'along_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registerMeta = const VerificationMeta(
    'register',
  );
  @override
  late final GeneratedColumn<String> register = GeneratedColumn<String>(
    'register',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _situationMeta = const VerificationMeta(
    'situation',
  );
  @override
  late final GeneratedColumn<String> situation = GeneratedColumn<String>(
    'situation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjustmentLoMeta = const VerificationMeta(
    'adjustmentLo',
  );
  @override
  late final GeneratedColumn<double> adjustmentLo = GeneratedColumn<double>(
    'adjustment_lo',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjustmentHiMeta = const VerificationMeta(
    'adjustmentHi',
  );
  @override
  late final GeneratedColumn<double> adjustmentHi = GeneratedColumn<double>(
    'adjustment_hi',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgencyLoMeta = const VerificationMeta(
    'urgencyLo',
  );
  @override
  late final GeneratedColumn<double> urgencyLo = GeneratedColumn<double>(
    'urgency_lo',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgencyHiMeta = const VerificationMeta(
    'urgencyHi',
  );
  @override
  late final GeneratedColumn<double> urgencyHi = GeneratedColumn<double>(
    'urgency_hi',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPowerMeta = const VerificationMeta(
    'targetPower',
  );
  @override
  late final GeneratedColumn<double> targetPower = GeneratedColumn<double>(
    'target_power',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetCadenceMeta = const VerificationMeta(
    'targetCadence',
  );
  @override
  late final GeneratedColumn<double> targetCadence = GeneratedColumn<double>(
    'target_cadence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestedPowerMeta = const VerificationMeta(
    'requestedPower',
  );
  @override
  late final GeneratedColumn<double> requestedPower = GeneratedColumn<double>(
    'requested_power',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sustainablePowerMeta = const VerificationMeta(
    'sustainablePower',
  );
  @override
  late final GeneratedColumn<double> sustainablePower = GeneratedColumn<double>(
    'sustainable_power',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _physicsGapPercentMeta = const VerificationMeta(
    'physicsGapPercent',
  );
  @override
  late final GeneratedColumn<double> physicsGapPercent =
      GeneratedColumn<double>(
        'physics_gap_percent',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rideStartedAt,
    segmentId,
    second,
    alongMeters,
    recordedAt,
    mode,
    register,
    situation,
    diagnosis,
    adjustmentLo,
    adjustmentHi,
    urgencyLo,
    urgencyHi,
    targetPower,
    targetCadence,
    message,
    requestedPower,
    sustainablePower,
    physicsGapPercent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coaching_advices';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachingAdvice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ride_started_at')) {
      context.handle(
        _rideStartedAtMeta,
        rideStartedAt.isAcceptableOrUnknown(
          data['ride_started_at']!,
          _rideStartedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rideStartedAtMeta);
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('second')) {
      context.handle(
        _secondMeta,
        second.isAcceptableOrUnknown(data['second']!, _secondMeta),
      );
    } else if (isInserting) {
      context.missing(_secondMeta);
    }
    if (data.containsKey('along_meters')) {
      context.handle(
        _alongMetersMeta,
        alongMeters.isAcceptableOrUnknown(
          data['along_meters']!,
          _alongMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_alongMetersMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('register')) {
      context.handle(
        _registerMeta,
        register.isAcceptableOrUnknown(data['register']!, _registerMeta),
      );
    } else if (isInserting) {
      context.missing(_registerMeta);
    }
    if (data.containsKey('situation')) {
      context.handle(
        _situationMeta,
        situation.isAcceptableOrUnknown(data['situation']!, _situationMeta),
      );
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    }
    if (data.containsKey('adjustment_lo')) {
      context.handle(
        _adjustmentLoMeta,
        adjustmentLo.isAcceptableOrUnknown(
          data['adjustment_lo']!,
          _adjustmentLoMeta,
        ),
      );
    }
    if (data.containsKey('adjustment_hi')) {
      context.handle(
        _adjustmentHiMeta,
        adjustmentHi.isAcceptableOrUnknown(
          data['adjustment_hi']!,
          _adjustmentHiMeta,
        ),
      );
    }
    if (data.containsKey('urgency_lo')) {
      context.handle(
        _urgencyLoMeta,
        urgencyLo.isAcceptableOrUnknown(data['urgency_lo']!, _urgencyLoMeta),
      );
    }
    if (data.containsKey('urgency_hi')) {
      context.handle(
        _urgencyHiMeta,
        urgencyHi.isAcceptableOrUnknown(data['urgency_hi']!, _urgencyHiMeta),
      );
    }
    if (data.containsKey('target_power')) {
      context.handle(
        _targetPowerMeta,
        targetPower.isAcceptableOrUnknown(
          data['target_power']!,
          _targetPowerMeta,
        ),
      );
    }
    if (data.containsKey('target_cadence')) {
      context.handle(
        _targetCadenceMeta,
        targetCadence.isAcceptableOrUnknown(
          data['target_cadence']!,
          _targetCadenceMeta,
        ),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('requested_power')) {
      context.handle(
        _requestedPowerMeta,
        requestedPower.isAcceptableOrUnknown(
          data['requested_power']!,
          _requestedPowerMeta,
        ),
      );
    }
    if (data.containsKey('sustainable_power')) {
      context.handle(
        _sustainablePowerMeta,
        sustainablePower.isAcceptableOrUnknown(
          data['sustainable_power']!,
          _sustainablePowerMeta,
        ),
      );
    }
    if (data.containsKey('physics_gap_percent')) {
      context.handle(
        _physicsGapPercentMeta,
        physicsGapPercent.isAcceptableOrUnknown(
          data['physics_gap_percent']!,
          _physicsGapPercentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoachingAdvice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachingAdvice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rideStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ride_started_at'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_id'],
      )!,
      second: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}second'],
      )!,
      alongMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}along_meters'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      register: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register'],
      )!,
      situation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situation'],
      ),
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      ),
      adjustmentLo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adjustment_lo'],
      ),
      adjustmentHi: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adjustment_hi'],
      ),
      urgencyLo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}urgency_lo'],
      ),
      urgencyHi: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}urgency_hi'],
      ),
      targetPower: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_power'],
      ),
      targetCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_cadence'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      requestedPower: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}requested_power'],
      ),
      sustainablePower: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sustainable_power'],
      ),
      physicsGapPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}physics_gap_percent'],
      ),
    );
  }

  @override
  $CoachingAdvicesTable createAlias(String alias) {
    return $CoachingAdvicesTable(attachedDatabase, alias);
  }
}

class CoachingAdvice extends DataClass implements Insertable<CoachingAdvice> {
  final int id;
  final DateTime rideStartedAt;
  final int segmentId;

  /// Segundos en movimiento desde que empezó el segmento, y metros
  /// recorridos dentro de él.
  final int second;
  final double alongMeters;
  final DateTime recordedAt;

  /// 'type1' | 'type2'.
  final String mode;

  /// Tono del mensaje (`Register`) y celda del tensor de situaciones
  /// ('estado/demanda/fase').
  final String register;
  final String? situation;

  /// Regla que explica el aviso (id de la base de reglas).
  final String? diagnosis;

  /// Centroides de intervalo del ajuste y de la urgencia.
  final double? adjustmentLo;
  final double? adjustmentHi;
  final double? urgencyLo;
  final double? urgencyHi;

  /// Números dichos en voz alta.
  final double? targetPower;
  final double? targetCadence;

  /// Frase que se dijo (la arma el compositor de mensajes).
  final String? message;

  /// Verificación física independiente (F12): los vatios que pidieron
  /// las reglas sin recortar, los que dice la ecuación de la reserva, y
  /// cuánto se separaron en puntos porcentuales. Se guarda para poder
  /// revisar después si la base de reglas se está yendo de la física.
  final double? requestedPower;
  final double? sustainablePower;
  final double? physicsGapPercent;
  const CoachingAdvice({
    required this.id,
    required this.rideStartedAt,
    required this.segmentId,
    required this.second,
    required this.alongMeters,
    required this.recordedAt,
    required this.mode,
    required this.register,
    this.situation,
    this.diagnosis,
    this.adjustmentLo,
    this.adjustmentHi,
    this.urgencyLo,
    this.urgencyHi,
    this.targetPower,
    this.targetCadence,
    this.message,
    this.requestedPower,
    this.sustainablePower,
    this.physicsGapPercent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ride_started_at'] = Variable<DateTime>(rideStartedAt);
    map['segment_id'] = Variable<int>(segmentId);
    map['second'] = Variable<int>(second);
    map['along_meters'] = Variable<double>(alongMeters);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['mode'] = Variable<String>(mode);
    map['register'] = Variable<String>(register);
    if (!nullToAbsent || situation != null) {
      map['situation'] = Variable<String>(situation);
    }
    if (!nullToAbsent || diagnosis != null) {
      map['diagnosis'] = Variable<String>(diagnosis);
    }
    if (!nullToAbsent || adjustmentLo != null) {
      map['adjustment_lo'] = Variable<double>(adjustmentLo);
    }
    if (!nullToAbsent || adjustmentHi != null) {
      map['adjustment_hi'] = Variable<double>(adjustmentHi);
    }
    if (!nullToAbsent || urgencyLo != null) {
      map['urgency_lo'] = Variable<double>(urgencyLo);
    }
    if (!nullToAbsent || urgencyHi != null) {
      map['urgency_hi'] = Variable<double>(urgencyHi);
    }
    if (!nullToAbsent || targetPower != null) {
      map['target_power'] = Variable<double>(targetPower);
    }
    if (!nullToAbsent || targetCadence != null) {
      map['target_cadence'] = Variable<double>(targetCadence);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || requestedPower != null) {
      map['requested_power'] = Variable<double>(requestedPower);
    }
    if (!nullToAbsent || sustainablePower != null) {
      map['sustainable_power'] = Variable<double>(sustainablePower);
    }
    if (!nullToAbsent || physicsGapPercent != null) {
      map['physics_gap_percent'] = Variable<double>(physicsGapPercent);
    }
    return map;
  }

  CoachingAdvicesCompanion toCompanion(bool nullToAbsent) {
    return CoachingAdvicesCompanion(
      id: Value(id),
      rideStartedAt: Value(rideStartedAt),
      segmentId: Value(segmentId),
      second: Value(second),
      alongMeters: Value(alongMeters),
      recordedAt: Value(recordedAt),
      mode: Value(mode),
      register: Value(register),
      situation: situation == null && nullToAbsent
          ? const Value.absent()
          : Value(situation),
      diagnosis: diagnosis == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosis),
      adjustmentLo: adjustmentLo == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentLo),
      adjustmentHi: adjustmentHi == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentHi),
      urgencyLo: urgencyLo == null && nullToAbsent
          ? const Value.absent()
          : Value(urgencyLo),
      urgencyHi: urgencyHi == null && nullToAbsent
          ? const Value.absent()
          : Value(urgencyHi),
      targetPower: targetPower == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPower),
      targetCadence: targetCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCadence),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      requestedPower: requestedPower == null && nullToAbsent
          ? const Value.absent()
          : Value(requestedPower),
      sustainablePower: sustainablePower == null && nullToAbsent
          ? const Value.absent()
          : Value(sustainablePower),
      physicsGapPercent: physicsGapPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(physicsGapPercent),
    );
  }

  factory CoachingAdvice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachingAdvice(
      id: serializer.fromJson<int>(json['id']),
      rideStartedAt: serializer.fromJson<DateTime>(json['rideStartedAt']),
      segmentId: serializer.fromJson<int>(json['segmentId']),
      second: serializer.fromJson<int>(json['second']),
      alongMeters: serializer.fromJson<double>(json['alongMeters']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      mode: serializer.fromJson<String>(json['mode']),
      register: serializer.fromJson<String>(json['register']),
      situation: serializer.fromJson<String?>(json['situation']),
      diagnosis: serializer.fromJson<String?>(json['diagnosis']),
      adjustmentLo: serializer.fromJson<double?>(json['adjustmentLo']),
      adjustmentHi: serializer.fromJson<double?>(json['adjustmentHi']),
      urgencyLo: serializer.fromJson<double?>(json['urgencyLo']),
      urgencyHi: serializer.fromJson<double?>(json['urgencyHi']),
      targetPower: serializer.fromJson<double?>(json['targetPower']),
      targetCadence: serializer.fromJson<double?>(json['targetCadence']),
      message: serializer.fromJson<String?>(json['message']),
      requestedPower: serializer.fromJson<double?>(json['requestedPower']),
      sustainablePower: serializer.fromJson<double?>(json['sustainablePower']),
      physicsGapPercent: serializer.fromJson<double?>(
        json['physicsGapPercent'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rideStartedAt': serializer.toJson<DateTime>(rideStartedAt),
      'segmentId': serializer.toJson<int>(segmentId),
      'second': serializer.toJson<int>(second),
      'alongMeters': serializer.toJson<double>(alongMeters),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'mode': serializer.toJson<String>(mode),
      'register': serializer.toJson<String>(register),
      'situation': serializer.toJson<String?>(situation),
      'diagnosis': serializer.toJson<String?>(diagnosis),
      'adjustmentLo': serializer.toJson<double?>(adjustmentLo),
      'adjustmentHi': serializer.toJson<double?>(adjustmentHi),
      'urgencyLo': serializer.toJson<double?>(urgencyLo),
      'urgencyHi': serializer.toJson<double?>(urgencyHi),
      'targetPower': serializer.toJson<double?>(targetPower),
      'targetCadence': serializer.toJson<double?>(targetCadence),
      'message': serializer.toJson<String?>(message),
      'requestedPower': serializer.toJson<double?>(requestedPower),
      'sustainablePower': serializer.toJson<double?>(sustainablePower),
      'physicsGapPercent': serializer.toJson<double?>(physicsGapPercent),
    };
  }

  CoachingAdvice copyWith({
    int? id,
    DateTime? rideStartedAt,
    int? segmentId,
    int? second,
    double? alongMeters,
    DateTime? recordedAt,
    String? mode,
    String? register,
    Value<String?> situation = const Value.absent(),
    Value<String?> diagnosis = const Value.absent(),
    Value<double?> adjustmentLo = const Value.absent(),
    Value<double?> adjustmentHi = const Value.absent(),
    Value<double?> urgencyLo = const Value.absent(),
    Value<double?> urgencyHi = const Value.absent(),
    Value<double?> targetPower = const Value.absent(),
    Value<double?> targetCadence = const Value.absent(),
    Value<String?> message = const Value.absent(),
    Value<double?> requestedPower = const Value.absent(),
    Value<double?> sustainablePower = const Value.absent(),
    Value<double?> physicsGapPercent = const Value.absent(),
  }) => CoachingAdvice(
    id: id ?? this.id,
    rideStartedAt: rideStartedAt ?? this.rideStartedAt,
    segmentId: segmentId ?? this.segmentId,
    second: second ?? this.second,
    alongMeters: alongMeters ?? this.alongMeters,
    recordedAt: recordedAt ?? this.recordedAt,
    mode: mode ?? this.mode,
    register: register ?? this.register,
    situation: situation.present ? situation.value : this.situation,
    diagnosis: diagnosis.present ? diagnosis.value : this.diagnosis,
    adjustmentLo: adjustmentLo.present ? adjustmentLo.value : this.adjustmentLo,
    adjustmentHi: adjustmentHi.present ? adjustmentHi.value : this.adjustmentHi,
    urgencyLo: urgencyLo.present ? urgencyLo.value : this.urgencyLo,
    urgencyHi: urgencyHi.present ? urgencyHi.value : this.urgencyHi,
    targetPower: targetPower.present ? targetPower.value : this.targetPower,
    targetCadence: targetCadence.present
        ? targetCadence.value
        : this.targetCadence,
    message: message.present ? message.value : this.message,
    requestedPower: requestedPower.present
        ? requestedPower.value
        : this.requestedPower,
    sustainablePower: sustainablePower.present
        ? sustainablePower.value
        : this.sustainablePower,
    physicsGapPercent: physicsGapPercent.present
        ? physicsGapPercent.value
        : this.physicsGapPercent,
  );
  CoachingAdvice copyWithCompanion(CoachingAdvicesCompanion data) {
    return CoachingAdvice(
      id: data.id.present ? data.id.value : this.id,
      rideStartedAt: data.rideStartedAt.present
          ? data.rideStartedAt.value
          : this.rideStartedAt,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      second: data.second.present ? data.second.value : this.second,
      alongMeters: data.alongMeters.present
          ? data.alongMeters.value
          : this.alongMeters,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      mode: data.mode.present ? data.mode.value : this.mode,
      register: data.register.present ? data.register.value : this.register,
      situation: data.situation.present ? data.situation.value : this.situation,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      adjustmentLo: data.adjustmentLo.present
          ? data.adjustmentLo.value
          : this.adjustmentLo,
      adjustmentHi: data.adjustmentHi.present
          ? data.adjustmentHi.value
          : this.adjustmentHi,
      urgencyLo: data.urgencyLo.present ? data.urgencyLo.value : this.urgencyLo,
      urgencyHi: data.urgencyHi.present ? data.urgencyHi.value : this.urgencyHi,
      targetPower: data.targetPower.present
          ? data.targetPower.value
          : this.targetPower,
      targetCadence: data.targetCadence.present
          ? data.targetCadence.value
          : this.targetCadence,
      message: data.message.present ? data.message.value : this.message,
      requestedPower: data.requestedPower.present
          ? data.requestedPower.value
          : this.requestedPower,
      sustainablePower: data.sustainablePower.present
          ? data.sustainablePower.value
          : this.sustainablePower,
      physicsGapPercent: data.physicsGapPercent.present
          ? data.physicsGapPercent.value
          : this.physicsGapPercent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachingAdvice(')
          ..write('id: $id, ')
          ..write('rideStartedAt: $rideStartedAt, ')
          ..write('segmentId: $segmentId, ')
          ..write('second: $second, ')
          ..write('alongMeters: $alongMeters, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('mode: $mode, ')
          ..write('register: $register, ')
          ..write('situation: $situation, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('adjustmentLo: $adjustmentLo, ')
          ..write('adjustmentHi: $adjustmentHi, ')
          ..write('urgencyLo: $urgencyLo, ')
          ..write('urgencyHi: $urgencyHi, ')
          ..write('targetPower: $targetPower, ')
          ..write('targetCadence: $targetCadence, ')
          ..write('message: $message, ')
          ..write('requestedPower: $requestedPower, ')
          ..write('sustainablePower: $sustainablePower, ')
          ..write('physicsGapPercent: $physicsGapPercent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rideStartedAt,
    segmentId,
    second,
    alongMeters,
    recordedAt,
    mode,
    register,
    situation,
    diagnosis,
    adjustmentLo,
    adjustmentHi,
    urgencyLo,
    urgencyHi,
    targetPower,
    targetCadence,
    message,
    requestedPower,
    sustainablePower,
    physicsGapPercent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachingAdvice &&
          other.id == this.id &&
          other.rideStartedAt == this.rideStartedAt &&
          other.segmentId == this.segmentId &&
          other.second == this.second &&
          other.alongMeters == this.alongMeters &&
          other.recordedAt == this.recordedAt &&
          other.mode == this.mode &&
          other.register == this.register &&
          other.situation == this.situation &&
          other.diagnosis == this.diagnosis &&
          other.adjustmentLo == this.adjustmentLo &&
          other.adjustmentHi == this.adjustmentHi &&
          other.urgencyLo == this.urgencyLo &&
          other.urgencyHi == this.urgencyHi &&
          other.targetPower == this.targetPower &&
          other.targetCadence == this.targetCadence &&
          other.message == this.message &&
          other.requestedPower == this.requestedPower &&
          other.sustainablePower == this.sustainablePower &&
          other.physicsGapPercent == this.physicsGapPercent);
}

class CoachingAdvicesCompanion extends UpdateCompanion<CoachingAdvice> {
  final Value<int> id;
  final Value<DateTime> rideStartedAt;
  final Value<int> segmentId;
  final Value<int> second;
  final Value<double> alongMeters;
  final Value<DateTime> recordedAt;
  final Value<String> mode;
  final Value<String> register;
  final Value<String?> situation;
  final Value<String?> diagnosis;
  final Value<double?> adjustmentLo;
  final Value<double?> adjustmentHi;
  final Value<double?> urgencyLo;
  final Value<double?> urgencyHi;
  final Value<double?> targetPower;
  final Value<double?> targetCadence;
  final Value<String?> message;
  final Value<double?> requestedPower;
  final Value<double?> sustainablePower;
  final Value<double?> physicsGapPercent;
  const CoachingAdvicesCompanion({
    this.id = const Value.absent(),
    this.rideStartedAt = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.second = const Value.absent(),
    this.alongMeters = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.mode = const Value.absent(),
    this.register = const Value.absent(),
    this.situation = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.adjustmentLo = const Value.absent(),
    this.adjustmentHi = const Value.absent(),
    this.urgencyLo = const Value.absent(),
    this.urgencyHi = const Value.absent(),
    this.targetPower = const Value.absent(),
    this.targetCadence = const Value.absent(),
    this.message = const Value.absent(),
    this.requestedPower = const Value.absent(),
    this.sustainablePower = const Value.absent(),
    this.physicsGapPercent = const Value.absent(),
  });
  CoachingAdvicesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime rideStartedAt,
    required int segmentId,
    required int second,
    required double alongMeters,
    required DateTime recordedAt,
    required String mode,
    required String register,
    this.situation = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.adjustmentLo = const Value.absent(),
    this.adjustmentHi = const Value.absent(),
    this.urgencyLo = const Value.absent(),
    this.urgencyHi = const Value.absent(),
    this.targetPower = const Value.absent(),
    this.targetCadence = const Value.absent(),
    this.message = const Value.absent(),
    this.requestedPower = const Value.absent(),
    this.sustainablePower = const Value.absent(),
    this.physicsGapPercent = const Value.absent(),
  }) : rideStartedAt = Value(rideStartedAt),
       segmentId = Value(segmentId),
       second = Value(second),
       alongMeters = Value(alongMeters),
       recordedAt = Value(recordedAt),
       mode = Value(mode),
       register = Value(register);
  static Insertable<CoachingAdvice> custom({
    Expression<int>? id,
    Expression<DateTime>? rideStartedAt,
    Expression<int>? segmentId,
    Expression<int>? second,
    Expression<double>? alongMeters,
    Expression<DateTime>? recordedAt,
    Expression<String>? mode,
    Expression<String>? register,
    Expression<String>? situation,
    Expression<String>? diagnosis,
    Expression<double>? adjustmentLo,
    Expression<double>? adjustmentHi,
    Expression<double>? urgencyLo,
    Expression<double>? urgencyHi,
    Expression<double>? targetPower,
    Expression<double>? targetCadence,
    Expression<String>? message,
    Expression<double>? requestedPower,
    Expression<double>? sustainablePower,
    Expression<double>? physicsGapPercent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rideStartedAt != null) 'ride_started_at': rideStartedAt,
      if (segmentId != null) 'segment_id': segmentId,
      if (second != null) 'second': second,
      if (alongMeters != null) 'along_meters': alongMeters,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (mode != null) 'mode': mode,
      if (register != null) 'register': register,
      if (situation != null) 'situation': situation,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (adjustmentLo != null) 'adjustment_lo': adjustmentLo,
      if (adjustmentHi != null) 'adjustment_hi': adjustmentHi,
      if (urgencyLo != null) 'urgency_lo': urgencyLo,
      if (urgencyHi != null) 'urgency_hi': urgencyHi,
      if (targetPower != null) 'target_power': targetPower,
      if (targetCadence != null) 'target_cadence': targetCadence,
      if (message != null) 'message': message,
      if (requestedPower != null) 'requested_power': requestedPower,
      if (sustainablePower != null) 'sustainable_power': sustainablePower,
      if (physicsGapPercent != null) 'physics_gap_percent': physicsGapPercent,
    });
  }

  CoachingAdvicesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? rideStartedAt,
    Value<int>? segmentId,
    Value<int>? second,
    Value<double>? alongMeters,
    Value<DateTime>? recordedAt,
    Value<String>? mode,
    Value<String>? register,
    Value<String?>? situation,
    Value<String?>? diagnosis,
    Value<double?>? adjustmentLo,
    Value<double?>? adjustmentHi,
    Value<double?>? urgencyLo,
    Value<double?>? urgencyHi,
    Value<double?>? targetPower,
    Value<double?>? targetCadence,
    Value<String?>? message,
    Value<double?>? requestedPower,
    Value<double?>? sustainablePower,
    Value<double?>? physicsGapPercent,
  }) {
    return CoachingAdvicesCompanion(
      id: id ?? this.id,
      rideStartedAt: rideStartedAt ?? this.rideStartedAt,
      segmentId: segmentId ?? this.segmentId,
      second: second ?? this.second,
      alongMeters: alongMeters ?? this.alongMeters,
      recordedAt: recordedAt ?? this.recordedAt,
      mode: mode ?? this.mode,
      register: register ?? this.register,
      situation: situation ?? this.situation,
      diagnosis: diagnosis ?? this.diagnosis,
      adjustmentLo: adjustmentLo ?? this.adjustmentLo,
      adjustmentHi: adjustmentHi ?? this.adjustmentHi,
      urgencyLo: urgencyLo ?? this.urgencyLo,
      urgencyHi: urgencyHi ?? this.urgencyHi,
      targetPower: targetPower ?? this.targetPower,
      targetCadence: targetCadence ?? this.targetCadence,
      message: message ?? this.message,
      requestedPower: requestedPower ?? this.requestedPower,
      sustainablePower: sustainablePower ?? this.sustainablePower,
      physicsGapPercent: physicsGapPercent ?? this.physicsGapPercent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rideStartedAt.present) {
      map['ride_started_at'] = Variable<DateTime>(rideStartedAt.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<int>(segmentId.value);
    }
    if (second.present) {
      map['second'] = Variable<int>(second.value);
    }
    if (alongMeters.present) {
      map['along_meters'] = Variable<double>(alongMeters.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (register.present) {
      map['register'] = Variable<String>(register.value);
    }
    if (situation.present) {
      map['situation'] = Variable<String>(situation.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (adjustmentLo.present) {
      map['adjustment_lo'] = Variable<double>(adjustmentLo.value);
    }
    if (adjustmentHi.present) {
      map['adjustment_hi'] = Variable<double>(adjustmentHi.value);
    }
    if (urgencyLo.present) {
      map['urgency_lo'] = Variable<double>(urgencyLo.value);
    }
    if (urgencyHi.present) {
      map['urgency_hi'] = Variable<double>(urgencyHi.value);
    }
    if (targetPower.present) {
      map['target_power'] = Variable<double>(targetPower.value);
    }
    if (targetCadence.present) {
      map['target_cadence'] = Variable<double>(targetCadence.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (requestedPower.present) {
      map['requested_power'] = Variable<double>(requestedPower.value);
    }
    if (sustainablePower.present) {
      map['sustainable_power'] = Variable<double>(sustainablePower.value);
    }
    if (physicsGapPercent.present) {
      map['physics_gap_percent'] = Variable<double>(physicsGapPercent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachingAdvicesCompanion(')
          ..write('id: $id, ')
          ..write('rideStartedAt: $rideStartedAt, ')
          ..write('segmentId: $segmentId, ')
          ..write('second: $second, ')
          ..write('alongMeters: $alongMeters, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('mode: $mode, ')
          ..write('register: $register, ')
          ..write('situation: $situation, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('adjustmentLo: $adjustmentLo, ')
          ..write('adjustmentHi: $adjustmentHi, ')
          ..write('urgencyLo: $urgencyLo, ')
          ..write('urgencyHi: $urgencyHi, ')
          ..write('targetPower: $targetPower, ')
          ..write('targetCadence: $targetCadence, ')
          ..write('message: $message, ')
          ..write('requestedPower: $requestedPower, ')
          ..write('sustainablePower: $sustainablePower, ')
          ..write('physicsGapPercent: $physicsGapPercent')
          ..write(')'))
        .toString();
  }
}

class $BikesTable extends Bikes with TableInfo<$BikesTable, BikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ruta'),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _lowestChainringMeta = const VerificationMeta(
    'lowestChainring',
  );
  @override
  late final GeneratedColumn<int> lowestChainring = GeneratedColumn<int>(
    'lowest_chainring',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _largestCogMeta = const VerificationMeta(
    'largestCog',
  );
  @override
  late final GeneratedColumn<int> largestCog = GeneratedColumn<int>(
    'largest_cog',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _largestChainringMeta = const VerificationMeta(
    'largestChainring',
  );
  @override
  late final GeneratedColumn<int> largestChainring = GeneratedColumn<int>(
    'largest_chainring',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _smallestCogMeta = const VerificationMeta(
    'smallestCog',
  );
  @override
  late final GeneratedColumn<int> smallestCog = GeneratedColumn<int>(
    'smallest_cog',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wheelCircumferenceMmMeta =
      const VerificationMeta('wheelCircumferenceMm');
  @override
  late final GeneratedColumn<int> wheelCircumferenceMm = GeneratedColumn<int>(
    'wheel_circumference_mm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    brand,
    kind,
    weightKg,
    color,
    photoPath,
    notes,
    lowestChainring,
    largestCog,
    largestChainring,
    smallestCog,
    wheelCircumferenceMm,
    isDefault,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bikes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikeRow> instance, {
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
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('lowest_chainring')) {
      context.handle(
        _lowestChainringMeta,
        lowestChainring.isAcceptableOrUnknown(
          data['lowest_chainring']!,
          _lowestChainringMeta,
        ),
      );
    }
    if (data.containsKey('largest_cog')) {
      context.handle(
        _largestCogMeta,
        largestCog.isAcceptableOrUnknown(data['largest_cog']!, _largestCogMeta),
      );
    }
    if (data.containsKey('largest_chainring')) {
      context.handle(
        _largestChainringMeta,
        largestChainring.isAcceptableOrUnknown(
          data['largest_chainring']!,
          _largestChainringMeta,
        ),
      );
    }
    if (data.containsKey('smallest_cog')) {
      context.handle(
        _smallestCogMeta,
        smallestCog.isAcceptableOrUnknown(
          data['smallest_cog']!,
          _smallestCogMeta,
        ),
      );
    }
    if (data.containsKey('wheel_circumference_mm')) {
      context.handle(
        _wheelCircumferenceMmMeta,
        wheelCircumferenceMm.isAcceptableOrUnknown(
          data['wheel_circumference_mm']!,
          _wheelCircumferenceMmMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
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
  BikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      lowestChainring: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lowest_chainring'],
      ),
      largestCog: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}largest_cog'],
      ),
      largestChainring: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}largest_chainring'],
      ),
      smallestCog: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}smallest_cog'],
      ),
      wheelCircumferenceMm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wheel_circumference_mm'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BikesTable createAlias(String alias) {
    return $BikesTable(attachedDatabase, alias);
  }
}

class BikeRow extends DataClass implements Insertable<BikeRow> {
  final int id;
  final String name;
  final String? brand;

  /// 'ruta' | 'montana'. Cambia la resistencia a la rodadura y el área
  /// frontal que se suponen.
  final String kind;

  /// Peso de la bicicleta lista para rodar, en kilos.
  final double? weightKg;

  /// Color como entero ARGB, para pintar su ficha.
  final int? color;

  /// Ruta local de la foto. Null = sin foto.
  final String? photoPath;
  final String? notes;

  /// El desarrollo más suave que tiene: dientes del plato pequeño y del
  /// piñón grande. Con eso se sabe a qué cadencia se puede pedalear a
  /// una velocidad dada, y por tanto si al ciclista le queda piñón o ya
  /// está en el último. Null = se supone el típico de su tipo.
  final int? lowestChainring;
  final int? largestCog;
  final int? largestChainring;
  final int? smallestCog;

  /// Desarrollo de la rueda en milímetros (perímetro).
  final int? wheelCircumferenceMm;

  /// La que se usa por defecto al guardar una salida y la que mira el
  /// coach. Solo una queda en true.
  final bool isDefault;
  final DateTime createdAt;
  const BikeRow({
    required this.id,
    required this.name,
    this.brand,
    required this.kind,
    this.weightKg,
    this.color,
    this.photoPath,
    this.notes,
    this.lowestChainring,
    this.largestCog,
    this.largestChainring,
    this.smallestCog,
    this.wheelCircumferenceMm,
    required this.isDefault,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || lowestChainring != null) {
      map['lowest_chainring'] = Variable<int>(lowestChainring);
    }
    if (!nullToAbsent || largestCog != null) {
      map['largest_cog'] = Variable<int>(largestCog);
    }
    if (!nullToAbsent || largestChainring != null) {
      map['largest_chainring'] = Variable<int>(largestChainring);
    }
    if (!nullToAbsent || smallestCog != null) {
      map['smallest_cog'] = Variable<int>(smallestCog);
    }
    if (!nullToAbsent || wheelCircumferenceMm != null) {
      map['wheel_circumference_mm'] = Variable<int>(wheelCircumferenceMm);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BikesCompanion toCompanion(bool nullToAbsent) {
    return BikesCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      kind: Value(kind),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      lowestChainring: lowestChainring == null && nullToAbsent
          ? const Value.absent()
          : Value(lowestChainring),
      largestCog: largestCog == null && nullToAbsent
          ? const Value.absent()
          : Value(largestCog),
      largestChainring: largestChainring == null && nullToAbsent
          ? const Value.absent()
          : Value(largestChainring),
      smallestCog: smallestCog == null && nullToAbsent
          ? const Value.absent()
          : Value(smallestCog),
      wheelCircumferenceMm: wheelCircumferenceMm == null && nullToAbsent
          ? const Value.absent()
          : Value(wheelCircumferenceMm),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }

  factory BikeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      kind: serializer.fromJson<String>(json['kind']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      color: serializer.fromJson<int?>(json['color']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      lowestChainring: serializer.fromJson<int?>(json['lowestChainring']),
      largestCog: serializer.fromJson<int?>(json['largestCog']),
      largestChainring: serializer.fromJson<int?>(json['largestChainring']),
      smallestCog: serializer.fromJson<int?>(json['smallestCog']),
      wheelCircumferenceMm: serializer.fromJson<int?>(
        json['wheelCircumferenceMm'],
      ),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'kind': serializer.toJson<String>(kind),
      'weightKg': serializer.toJson<double?>(weightKg),
      'color': serializer.toJson<int?>(color),
      'photoPath': serializer.toJson<String?>(photoPath),
      'notes': serializer.toJson<String?>(notes),
      'lowestChainring': serializer.toJson<int?>(lowestChainring),
      'largestCog': serializer.toJson<int?>(largestCog),
      'largestChainring': serializer.toJson<int?>(largestChainring),
      'smallestCog': serializer.toJson<int?>(smallestCog),
      'wheelCircumferenceMm': serializer.toJson<int?>(wheelCircumferenceMm),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BikeRow copyWith({
    int? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    String? kind,
    Value<double?> weightKg = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> lowestChainring = const Value.absent(),
    Value<int?> largestCog = const Value.absent(),
    Value<int?> largestChainring = const Value.absent(),
    Value<int?> smallestCog = const Value.absent(),
    Value<int?> wheelCircumferenceMm = const Value.absent(),
    bool? isDefault,
    DateTime? createdAt,
  }) => BikeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    kind: kind ?? this.kind,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    color: color.present ? color.value : this.color,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    notes: notes.present ? notes.value : this.notes,
    lowestChainring: lowestChainring.present
        ? lowestChainring.value
        : this.lowestChainring,
    largestCog: largestCog.present ? largestCog.value : this.largestCog,
    largestChainring: largestChainring.present
        ? largestChainring.value
        : this.largestChainring,
    smallestCog: smallestCog.present ? smallestCog.value : this.smallestCog,
    wheelCircumferenceMm: wheelCircumferenceMm.present
        ? wheelCircumferenceMm.value
        : this.wheelCircumferenceMm,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
  BikeRow copyWithCompanion(BikesCompanion data) {
    return BikeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      kind: data.kind.present ? data.kind.value : this.kind,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      color: data.color.present ? data.color.value : this.color,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      lowestChainring: data.lowestChainring.present
          ? data.lowestChainring.value
          : this.lowestChainring,
      largestCog: data.largestCog.present
          ? data.largestCog.value
          : this.largestCog,
      largestChainring: data.largestChainring.present
          ? data.largestChainring.value
          : this.largestChainring,
      smallestCog: data.smallestCog.present
          ? data.smallestCog.value
          : this.smallestCog,
      wheelCircumferenceMm: data.wheelCircumferenceMm.present
          ? data.wheelCircumferenceMm.value
          : this.wheelCircumferenceMm,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('kind: $kind, ')
          ..write('weightKg: $weightKg, ')
          ..write('color: $color, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('lowestChainring: $lowestChainring, ')
          ..write('largestCog: $largestCog, ')
          ..write('largestChainring: $largestChainring, ')
          ..write('smallestCog: $smallestCog, ')
          ..write('wheelCircumferenceMm: $wheelCircumferenceMm, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    kind,
    weightKg,
    color,
    photoPath,
    notes,
    lowestChainring,
    largestCog,
    largestChainring,
    smallestCog,
    wheelCircumferenceMm,
    isDefault,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.kind == this.kind &&
          other.weightKg == this.weightKg &&
          other.color == this.color &&
          other.photoPath == this.photoPath &&
          other.notes == this.notes &&
          other.lowestChainring == this.lowestChainring &&
          other.largestCog == this.largestCog &&
          other.largestChainring == this.largestChainring &&
          other.smallestCog == this.smallestCog &&
          other.wheelCircumferenceMm == this.wheelCircumferenceMm &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt);
}

class BikesCompanion extends UpdateCompanion<BikeRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String> kind;
  final Value<double?> weightKg;
  final Value<int?> color;
  final Value<String?> photoPath;
  final Value<String?> notes;
  final Value<int?> lowestChainring;
  final Value<int?> largestCog;
  final Value<int?> largestChainring;
  final Value<int?> smallestCog;
  final Value<int?> wheelCircumferenceMm;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  const BikesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.kind = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.color = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.lowestChainring = const Value.absent(),
    this.largestCog = const Value.absent(),
    this.largestChainring = const Value.absent(),
    this.smallestCog = const Value.absent(),
    this.wheelCircumferenceMm = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BikesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.kind = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.color = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.lowestChainring = const Value.absent(),
    this.largestCog = const Value.absent(),
    this.largestChainring = const Value.absent(),
    this.smallestCog = const Value.absent(),
    this.wheelCircumferenceMm = const Value.absent(),
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<BikeRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? kind,
    Expression<double>? weightKg,
    Expression<int>? color,
    Expression<String>? photoPath,
    Expression<String>? notes,
    Expression<int>? lowestChainring,
    Expression<int>? largestCog,
    Expression<int>? largestChainring,
    Expression<int>? smallestCog,
    Expression<int>? wheelCircumferenceMm,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (kind != null) 'kind': kind,
      if (weightKg != null) 'weight_kg': weightKg,
      if (color != null) 'color': color,
      if (photoPath != null) 'photo_path': photoPath,
      if (notes != null) 'notes': notes,
      if (lowestChainring != null) 'lowest_chainring': lowestChainring,
      if (largestCog != null) 'largest_cog': largestCog,
      if (largestChainring != null) 'largest_chainring': largestChainring,
      if (smallestCog != null) 'smallest_cog': smallestCog,
      if (wheelCircumferenceMm != null)
        'wheel_circumference_mm': wheelCircumferenceMm,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BikesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String>? kind,
    Value<double?>? weightKg,
    Value<int?>? color,
    Value<String?>? photoPath,
    Value<String?>? notes,
    Value<int?>? lowestChainring,
    Value<int?>? largestCog,
    Value<int?>? largestChainring,
    Value<int?>? smallestCog,
    Value<int?>? wheelCircumferenceMm,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
  }) {
    return BikesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      kind: kind ?? this.kind,
      weightKg: weightKg ?? this.weightKg,
      color: color ?? this.color,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      lowestChainring: lowestChainring ?? this.lowestChainring,
      largestCog: largestCog ?? this.largestCog,
      largestChainring: largestChainring ?? this.largestChainring,
      smallestCog: smallestCog ?? this.smallestCog,
      wheelCircumferenceMm: wheelCircumferenceMm ?? this.wheelCircumferenceMm,
      isDefault: isDefault ?? this.isDefault,
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
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (lowestChainring.present) {
      map['lowest_chainring'] = Variable<int>(lowestChainring.value);
    }
    if (largestCog.present) {
      map['largest_cog'] = Variable<int>(largestCog.value);
    }
    if (largestChainring.present) {
      map['largest_chainring'] = Variable<int>(largestChainring.value);
    }
    if (smallestCog.present) {
      map['smallest_cog'] = Variable<int>(smallestCog.value);
    }
    if (wheelCircumferenceMm.present) {
      map['wheel_circumference_mm'] = Variable<int>(wheelCircumferenceMm.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('kind: $kind, ')
          ..write('weightKg: $weightKg, ')
          ..write('color: $color, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('lowestChainring: $lowestChainring, ')
          ..write('largestCog: $largestCog, ')
          ..write('largestChainring: $largestChainring, ')
          ..write('smallestCog: $smallestCog, ')
          ..write('wheelCircumferenceMm: $wheelCircumferenceMm, ')
          ..write('isDefault: $isDefault, ')
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
  late final $RecordingSessionsTable recordingSessions =
      $RecordingSessionsTable(this);
  late final $RecordingPointsTable recordingPoints = $RecordingPointsTable(
    this,
  );
  late final $RecordingSensorSamplesTable recordingSensorSamples =
      $RecordingSensorSamplesTable(this);
  late final $ActivityCurvesTable activityCurves = $ActivityCurvesTable(this);
  late final $ActivityCurvePointsTable activityCurvePoints =
      $ActivityCurvePointsTable(this);
  late final $CoachingAdvicesTable coachingAdvices = $CoachingAdvicesTable(
    this,
  );
  late final $BikesTable bikes = $BikesTable(this);
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
    recordingSessions,
    recordingPoints,
    recordingSensorSamples,
    activityCurves,
    activityCurvePoints,
    coachingAdvices,
    bikes,
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
      Value<int?> bikeId,
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
      Value<int?> bikeId,
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

  ColumnFilters<int> get bikeId => $composableBuilder(
    column: $table.bikeId,
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

  ColumnOrderings<int> get bikeId => $composableBuilder(
    column: $table.bikeId,
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

  GeneratedColumn<int> get bikeId =>
      $composableBuilder(column: $table.bikeId, builder: (column) => column);

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
                Value<int?> bikeId = const Value.absent(),
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
                bikeId: bikeId,
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
                Value<int?> bikeId = const Value.absent(),
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
                bikeId: bikeId,
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
typedef $$RecordingSessionsTableCreateCompanionBuilder =
    RecordingSessionsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<int> movingMillis,
      Value<bool> isPaused,
      Value<DateTime?> endedAt,
      required DateTime updatedAt,
    });
typedef $$RecordingSessionsTableUpdateCompanionBuilder =
    RecordingSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<int> movingMillis,
      Value<bool> isPaused,
      Value<DateTime?> endedAt,
      Value<DateTime> updatedAt,
    });

class $$RecordingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingSessionsTable> {
  $$RecordingSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingMillis => $composableBuilder(
    column: $table.movingMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingSessionsTable> {
  $$RecordingSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingMillis => $composableBuilder(
    column: $table.movingMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingSessionsTable> {
  $$RecordingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get movingMillis => $composableBuilder(
    column: $table.movingMillis,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecordingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingSessionsTable,
          RecordingSession,
          $$RecordingSessionsTableFilterComposer,
          $$RecordingSessionsTableOrderingComposer,
          $$RecordingSessionsTableAnnotationComposer,
          $$RecordingSessionsTableCreateCompanionBuilder,
          $$RecordingSessionsTableUpdateCompanionBuilder,
          (
            RecordingSession,
            BaseReferences<
              _$AppDatabase,
              $RecordingSessionsTable,
              RecordingSession
            >,
          ),
          RecordingSession,
          PrefetchHooks Function()
        > {
  $$RecordingSessionsTableTableManager(
    _$AppDatabase db,
    $RecordingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> movingMillis = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecordingSessionsCompanion(
                id: id,
                startedAt: startedAt,
                movingMillis: movingMillis,
                isPaused: isPaused,
                endedAt: endedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<int> movingMillis = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime updatedAt,
              }) => RecordingSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                movingMillis: movingMillis,
                isPaused: isPaused,
                endedAt: endedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingSessionsTable,
      RecordingSession,
      $$RecordingSessionsTableFilterComposer,
      $$RecordingSessionsTableOrderingComposer,
      $$RecordingSessionsTableAnnotationComposer,
      $$RecordingSessionsTableCreateCompanionBuilder,
      $$RecordingSessionsTableUpdateCompanionBuilder,
      (
        RecordingSession,
        BaseReferences<
          _$AppDatabase,
          $RecordingSessionsTable,
          RecordingSession
        >,
      ),
      RecordingSession,
      PrefetchHooks Function()
    >;
typedef $$RecordingPointsTableCreateCompanionBuilder =
    RecordingPointsCompanion Function({
      Value<int> id,
      required int sessionId,
      required double latitude,
      required double longitude,
      required double altitude,
      required double speedMetersPerSecond,
      required double bearingDegrees,
      required double accuracyMeters,
      required int timestampMillis,
      required double distanceMeters,
      required double speedKmh,
    });
typedef $$RecordingPointsTableUpdateCompanionBuilder =
    RecordingPointsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> altitude,
      Value<double> speedMetersPerSecond,
      Value<double> bearingDegrees,
      Value<double> accuracyMeters,
      Value<int> timestampMillis,
      Value<double> distanceMeters,
      Value<double> speedKmh,
    });

class $$RecordingPointsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingPointsTable> {
  $$RecordingPointsTableFilterComposer({
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

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
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

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordingPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingPointsTable> {
  $$RecordingPointsTableOrderingComposer({
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

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
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

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedKmh => $composableBuilder(
    column: $table.speedKmh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingPointsTable> {
  $$RecordingPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get speedMetersPerSecond => $composableBuilder(
    column: $table.speedMetersPerSecond,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speedKmh =>
      $composableBuilder(column: $table.speedKmh, builder: (column) => column);
}

class $$RecordingPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingPointsTable,
          RecordingPoint,
          $$RecordingPointsTableFilterComposer,
          $$RecordingPointsTableOrderingComposer,
          $$RecordingPointsTableAnnotationComposer,
          $$RecordingPointsTableCreateCompanionBuilder,
          $$RecordingPointsTableUpdateCompanionBuilder,
          (
            RecordingPoint,
            BaseReferences<
              _$AppDatabase,
              $RecordingPointsTable,
              RecordingPoint
            >,
          ),
          RecordingPoint,
          PrefetchHooks Function()
        > {
  $$RecordingPointsTableTableManager(
    _$AppDatabase db,
    $RecordingPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> altitude = const Value.absent(),
                Value<double> speedMetersPerSecond = const Value.absent(),
                Value<double> bearingDegrees = const Value.absent(),
                Value<double> accuracyMeters = const Value.absent(),
                Value<int> timestampMillis = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double> speedKmh = const Value.absent(),
              }) => RecordingPointsCompanion(
                id: id,
                sessionId: sessionId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                speedMetersPerSecond: speedMetersPerSecond,
                bearingDegrees: bearingDegrees,
                accuracyMeters: accuracyMeters,
                timestampMillis: timestampMillis,
                distanceMeters: distanceMeters,
                speedKmh: speedKmh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required double latitude,
                required double longitude,
                required double altitude,
                required double speedMetersPerSecond,
                required double bearingDegrees,
                required double accuracyMeters,
                required int timestampMillis,
                required double distanceMeters,
                required double speedKmh,
              }) => RecordingPointsCompanion.insert(
                id: id,
                sessionId: sessionId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                speedMetersPerSecond: speedMetersPerSecond,
                bearingDegrees: bearingDegrees,
                accuracyMeters: accuracyMeters,
                timestampMillis: timestampMillis,
                distanceMeters: distanceMeters,
                speedKmh: speedKmh,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingPointsTable,
      RecordingPoint,
      $$RecordingPointsTableFilterComposer,
      $$RecordingPointsTableOrderingComposer,
      $$RecordingPointsTableAnnotationComposer,
      $$RecordingPointsTableCreateCompanionBuilder,
      $$RecordingPointsTableUpdateCompanionBuilder,
      (
        RecordingPoint,
        BaseReferences<_$AppDatabase, $RecordingPointsTable, RecordingPoint>,
      ),
      RecordingPoint,
      PrefetchHooks Function()
    >;
typedef $$RecordingSensorSamplesTableCreateCompanionBuilder =
    RecordingSensorSamplesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String kind,
      required int timestampMillis,
      required double value,
    });
typedef $$RecordingSensorSamplesTableUpdateCompanionBuilder =
    RecordingSensorSamplesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> kind,
      Value<int> timestampMillis,
      Value<double> value,
    });

class $$RecordingSensorSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingSensorSamplesTable> {
  $$RecordingSensorSamplesTableFilterComposer({
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

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordingSensorSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingSensorSamplesTable> {
  $$RecordingSensorSamplesTableOrderingComposer({
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

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingSensorSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingSensorSamplesTable> {
  $$RecordingSensorSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get timestampMillis => $composableBuilder(
    column: $table.timestampMillis,
    builder: (column) => column,
  );

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$RecordingSensorSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingSensorSamplesTable,
          RecordingSensorSample,
          $$RecordingSensorSamplesTableFilterComposer,
          $$RecordingSensorSamplesTableOrderingComposer,
          $$RecordingSensorSamplesTableAnnotationComposer,
          $$RecordingSensorSamplesTableCreateCompanionBuilder,
          $$RecordingSensorSamplesTableUpdateCompanionBuilder,
          (
            RecordingSensorSample,
            BaseReferences<
              _$AppDatabase,
              $RecordingSensorSamplesTable,
              RecordingSensorSample
            >,
          ),
          RecordingSensorSample,
          PrefetchHooks Function()
        > {
  $$RecordingSensorSamplesTableTableManager(
    _$AppDatabase db,
    $RecordingSensorSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingSensorSamplesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecordingSensorSamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecordingSensorSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> timestampMillis = const Value.absent(),
                Value<double> value = const Value.absent(),
              }) => RecordingSensorSamplesCompanion(
                id: id,
                sessionId: sessionId,
                kind: kind,
                timestampMillis: timestampMillis,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String kind,
                required int timestampMillis,
                required double value,
              }) => RecordingSensorSamplesCompanion.insert(
                id: id,
                sessionId: sessionId,
                kind: kind,
                timestampMillis: timestampMillis,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordingSensorSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingSensorSamplesTable,
      RecordingSensorSample,
      $$RecordingSensorSamplesTableFilterComposer,
      $$RecordingSensorSamplesTableOrderingComposer,
      $$RecordingSensorSamplesTableAnnotationComposer,
      $$RecordingSensorSamplesTableCreateCompanionBuilder,
      $$RecordingSensorSamplesTableUpdateCompanionBuilder,
      (
        RecordingSensorSample,
        BaseReferences<
          _$AppDatabase,
          $RecordingSensorSamplesTable,
          RecordingSensorSample
        >,
      ),
      RecordingSensorSample,
      PrefetchHooks Function()
    >;
typedef $$ActivityCurvesTableCreateCompanionBuilder =
    ActivityCurvesCompanion Function({
      Value<int> activityId,
      required int version,
      required int movingSeconds,
      required int powerSeconds,
      required int heartRateSeconds,
      Value<double?> climbingCadence,
      required DateTime computedAt,
    });
typedef $$ActivityCurvesTableUpdateCompanionBuilder =
    ActivityCurvesCompanion Function({
      Value<int> activityId,
      Value<int> version,
      Value<int> movingSeconds,
      Value<int> powerSeconds,
      Value<int> heartRateSeconds,
      Value<double?> climbingCadence,
      Value<DateTime> computedAt,
    });

class $$ActivityCurvesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityCurvesTable> {
  $$ActivityCurvesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingSeconds => $composableBuilder(
    column: $table.movingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get powerSeconds => $composableBuilder(
    column: $table.powerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRateSeconds => $composableBuilder(
    column: $table.heartRateSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get climbingCadence => $composableBuilder(
    column: $table.climbingCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityCurvesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityCurvesTable> {
  $$ActivityCurvesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingSeconds => $composableBuilder(
    column: $table.movingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get powerSeconds => $composableBuilder(
    column: $table.powerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRateSeconds => $composableBuilder(
    column: $table.heartRateSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get climbingCadence => $composableBuilder(
    column: $table.climbingCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityCurvesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityCurvesTable> {
  $$ActivityCurvesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get movingSeconds => $composableBuilder(
    column: $table.movingSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get powerSeconds => $composableBuilder(
    column: $table.powerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heartRateSeconds => $composableBuilder(
    column: $table.heartRateSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get climbingCadence => $composableBuilder(
    column: $table.climbingCadence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$ActivityCurvesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityCurvesTable,
          ActivityCurve,
          $$ActivityCurvesTableFilterComposer,
          $$ActivityCurvesTableOrderingComposer,
          $$ActivityCurvesTableAnnotationComposer,
          $$ActivityCurvesTableCreateCompanionBuilder,
          $$ActivityCurvesTableUpdateCompanionBuilder,
          (
            ActivityCurve,
            BaseReferences<_$AppDatabase, $ActivityCurvesTable, ActivityCurve>,
          ),
          ActivityCurve,
          PrefetchHooks Function()
        > {
  $$ActivityCurvesTableTableManager(
    _$AppDatabase db,
    $ActivityCurvesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityCurvesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityCurvesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityCurvesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> activityId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> movingSeconds = const Value.absent(),
                Value<int> powerSeconds = const Value.absent(),
                Value<int> heartRateSeconds = const Value.absent(),
                Value<double?> climbingCadence = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
              }) => ActivityCurvesCompanion(
                activityId: activityId,
                version: version,
                movingSeconds: movingSeconds,
                powerSeconds: powerSeconds,
                heartRateSeconds: heartRateSeconds,
                climbingCadence: climbingCadence,
                computedAt: computedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> activityId = const Value.absent(),
                required int version,
                required int movingSeconds,
                required int powerSeconds,
                required int heartRateSeconds,
                Value<double?> climbingCadence = const Value.absent(),
                required DateTime computedAt,
              }) => ActivityCurvesCompanion.insert(
                activityId: activityId,
                version: version,
                movingSeconds: movingSeconds,
                powerSeconds: powerSeconds,
                heartRateSeconds: heartRateSeconds,
                climbingCadence: climbingCadence,
                computedAt: computedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityCurvesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityCurvesTable,
      ActivityCurve,
      $$ActivityCurvesTableFilterComposer,
      $$ActivityCurvesTableOrderingComposer,
      $$ActivityCurvesTableAnnotationComposer,
      $$ActivityCurvesTableCreateCompanionBuilder,
      $$ActivityCurvesTableUpdateCompanionBuilder,
      (
        ActivityCurve,
        BaseReferences<_$AppDatabase, $ActivityCurvesTable, ActivityCurve>,
      ),
      ActivityCurve,
      PrefetchHooks Function()
    >;
typedef $$ActivityCurvePointsTableCreateCompanionBuilder =
    ActivityCurvePointsCompanion Function({
      required int activityId,
      required String kind,
      required int durationSeconds,
      required double value,
      required int startSecond,
      Value<int> rowid,
    });
typedef $$ActivityCurvePointsTableUpdateCompanionBuilder =
    ActivityCurvePointsCompanion Function({
      Value<int> activityId,
      Value<String> kind,
      Value<int> durationSeconds,
      Value<double> value,
      Value<int> startSecond,
      Value<int> rowid,
    });

class $$ActivityCurvePointsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityCurvePointsTable> {
  $$ActivityCurvePointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startSecond => $composableBuilder(
    column: $table.startSecond,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityCurvePointsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityCurvePointsTable> {
  $$ActivityCurvePointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startSecond => $composableBuilder(
    column: $table.startSecond,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityCurvePointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityCurvePointsTable> {
  $$ActivityCurvePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get startSecond => $composableBuilder(
    column: $table.startSecond,
    builder: (column) => column,
  );
}

class $$ActivityCurvePointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityCurvePointsTable,
          ActivityCurvePoint,
          $$ActivityCurvePointsTableFilterComposer,
          $$ActivityCurvePointsTableOrderingComposer,
          $$ActivityCurvePointsTableAnnotationComposer,
          $$ActivityCurvePointsTableCreateCompanionBuilder,
          $$ActivityCurvePointsTableUpdateCompanionBuilder,
          (
            ActivityCurvePoint,
            BaseReferences<
              _$AppDatabase,
              $ActivityCurvePointsTable,
              ActivityCurvePoint
            >,
          ),
          ActivityCurvePoint,
          PrefetchHooks Function()
        > {
  $$ActivityCurvePointsTableTableManager(
    _$AppDatabase db,
    $ActivityCurvePointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityCurvePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityCurvePointsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ActivityCurvePointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> activityId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<int> startSecond = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityCurvePointsCompanion(
                activityId: activityId,
                kind: kind,
                durationSeconds: durationSeconds,
                value: value,
                startSecond: startSecond,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int activityId,
                required String kind,
                required int durationSeconds,
                required double value,
                required int startSecond,
                Value<int> rowid = const Value.absent(),
              }) => ActivityCurvePointsCompanion.insert(
                activityId: activityId,
                kind: kind,
                durationSeconds: durationSeconds,
                value: value,
                startSecond: startSecond,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityCurvePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityCurvePointsTable,
      ActivityCurvePoint,
      $$ActivityCurvePointsTableFilterComposer,
      $$ActivityCurvePointsTableOrderingComposer,
      $$ActivityCurvePointsTableAnnotationComposer,
      $$ActivityCurvePointsTableCreateCompanionBuilder,
      $$ActivityCurvePointsTableUpdateCompanionBuilder,
      (
        ActivityCurvePoint,
        BaseReferences<
          _$AppDatabase,
          $ActivityCurvePointsTable,
          ActivityCurvePoint
        >,
      ),
      ActivityCurvePoint,
      PrefetchHooks Function()
    >;
typedef $$CoachingAdvicesTableCreateCompanionBuilder =
    CoachingAdvicesCompanion Function({
      Value<int> id,
      required DateTime rideStartedAt,
      required int segmentId,
      required int second,
      required double alongMeters,
      required DateTime recordedAt,
      required String mode,
      required String register,
      Value<String?> situation,
      Value<String?> diagnosis,
      Value<double?> adjustmentLo,
      Value<double?> adjustmentHi,
      Value<double?> urgencyLo,
      Value<double?> urgencyHi,
      Value<double?> targetPower,
      Value<double?> targetCadence,
      Value<String?> message,
      Value<double?> requestedPower,
      Value<double?> sustainablePower,
      Value<double?> physicsGapPercent,
    });
typedef $$CoachingAdvicesTableUpdateCompanionBuilder =
    CoachingAdvicesCompanion Function({
      Value<int> id,
      Value<DateTime> rideStartedAt,
      Value<int> segmentId,
      Value<int> second,
      Value<double> alongMeters,
      Value<DateTime> recordedAt,
      Value<String> mode,
      Value<String> register,
      Value<String?> situation,
      Value<String?> diagnosis,
      Value<double?> adjustmentLo,
      Value<double?> adjustmentHi,
      Value<double?> urgencyLo,
      Value<double?> urgencyHi,
      Value<double?> targetPower,
      Value<double?> targetCadence,
      Value<String?> message,
      Value<double?> requestedPower,
      Value<double?> sustainablePower,
      Value<double?> physicsGapPercent,
    });

class $$CoachingAdvicesTableFilterComposer
    extends Composer<_$AppDatabase, $CoachingAdvicesTable> {
  $$CoachingAdvicesTableFilterComposer({
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

  ColumnFilters<DateTime> get rideStartedAt => $composableBuilder(
    column: $table.rideStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get second => $composableBuilder(
    column: $table.second,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alongMeters => $composableBuilder(
    column: $table.alongMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get register => $composableBuilder(
    column: $table.register,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adjustmentLo => $composableBuilder(
    column: $table.adjustmentLo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adjustmentHi => $composableBuilder(
    column: $table.adjustmentHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get urgencyLo => $composableBuilder(
    column: $table.urgencyLo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get urgencyHi => $composableBuilder(
    column: $table.urgencyHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPower => $composableBuilder(
    column: $table.targetPower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetCadence => $composableBuilder(
    column: $table.targetCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get requestedPower => $composableBuilder(
    column: $table.requestedPower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sustainablePower => $composableBuilder(
    column: $table.sustainablePower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get physicsGapPercent => $composableBuilder(
    column: $table.physicsGapPercent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoachingAdvicesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachingAdvicesTable> {
  $$CoachingAdvicesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get rideStartedAt => $composableBuilder(
    column: $table.rideStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get second => $composableBuilder(
    column: $table.second,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alongMeters => $composableBuilder(
    column: $table.alongMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get register => $composableBuilder(
    column: $table.register,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adjustmentLo => $composableBuilder(
    column: $table.adjustmentLo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adjustmentHi => $composableBuilder(
    column: $table.adjustmentHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get urgencyLo => $composableBuilder(
    column: $table.urgencyLo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get urgencyHi => $composableBuilder(
    column: $table.urgencyHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPower => $composableBuilder(
    column: $table.targetPower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetCadence => $composableBuilder(
    column: $table.targetCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get requestedPower => $composableBuilder(
    column: $table.requestedPower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sustainablePower => $composableBuilder(
    column: $table.sustainablePower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get physicsGapPercent => $composableBuilder(
    column: $table.physicsGapPercent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoachingAdvicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachingAdvicesTable> {
  $$CoachingAdvicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get rideStartedAt => $composableBuilder(
    column: $table.rideStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<int> get second =>
      $composableBuilder(column: $table.second, builder: (column) => column);

  GeneratedColumn<double> get alongMeters => $composableBuilder(
    column: $table.alongMeters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get register =>
      $composableBuilder(column: $table.register, builder: (column) => column);

  GeneratedColumn<String> get situation =>
      $composableBuilder(column: $table.situation, builder: (column) => column);

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<double> get adjustmentLo => $composableBuilder(
    column: $table.adjustmentLo,
    builder: (column) => column,
  );

  GeneratedColumn<double> get adjustmentHi => $composableBuilder(
    column: $table.adjustmentHi,
    builder: (column) => column,
  );

  GeneratedColumn<double> get urgencyLo =>
      $composableBuilder(column: $table.urgencyLo, builder: (column) => column);

  GeneratedColumn<double> get urgencyHi =>
      $composableBuilder(column: $table.urgencyHi, builder: (column) => column);

  GeneratedColumn<double> get targetPower => $composableBuilder(
    column: $table.targetPower,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetCadence => $composableBuilder(
    column: $table.targetCadence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<double> get requestedPower => $composableBuilder(
    column: $table.requestedPower,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sustainablePower => $composableBuilder(
    column: $table.sustainablePower,
    builder: (column) => column,
  );

  GeneratedColumn<double> get physicsGapPercent => $composableBuilder(
    column: $table.physicsGapPercent,
    builder: (column) => column,
  );
}

class $$CoachingAdvicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachingAdvicesTable,
          CoachingAdvice,
          $$CoachingAdvicesTableFilterComposer,
          $$CoachingAdvicesTableOrderingComposer,
          $$CoachingAdvicesTableAnnotationComposer,
          $$CoachingAdvicesTableCreateCompanionBuilder,
          $$CoachingAdvicesTableUpdateCompanionBuilder,
          (
            CoachingAdvice,
            BaseReferences<
              _$AppDatabase,
              $CoachingAdvicesTable,
              CoachingAdvice
            >,
          ),
          CoachingAdvice,
          PrefetchHooks Function()
        > {
  $$CoachingAdvicesTableTableManager(
    _$AppDatabase db,
    $CoachingAdvicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachingAdvicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachingAdvicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachingAdvicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> rideStartedAt = const Value.absent(),
                Value<int> segmentId = const Value.absent(),
                Value<int> second = const Value.absent(),
                Value<double> alongMeters = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> register = const Value.absent(),
                Value<String?> situation = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<double?> adjustmentLo = const Value.absent(),
                Value<double?> adjustmentHi = const Value.absent(),
                Value<double?> urgencyLo = const Value.absent(),
                Value<double?> urgencyHi = const Value.absent(),
                Value<double?> targetPower = const Value.absent(),
                Value<double?> targetCadence = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<double?> requestedPower = const Value.absent(),
                Value<double?> sustainablePower = const Value.absent(),
                Value<double?> physicsGapPercent = const Value.absent(),
              }) => CoachingAdvicesCompanion(
                id: id,
                rideStartedAt: rideStartedAt,
                segmentId: segmentId,
                second: second,
                alongMeters: alongMeters,
                recordedAt: recordedAt,
                mode: mode,
                register: register,
                situation: situation,
                diagnosis: diagnosis,
                adjustmentLo: adjustmentLo,
                adjustmentHi: adjustmentHi,
                urgencyLo: urgencyLo,
                urgencyHi: urgencyHi,
                targetPower: targetPower,
                targetCadence: targetCadence,
                message: message,
                requestedPower: requestedPower,
                sustainablePower: sustainablePower,
                physicsGapPercent: physicsGapPercent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime rideStartedAt,
                required int segmentId,
                required int second,
                required double alongMeters,
                required DateTime recordedAt,
                required String mode,
                required String register,
                Value<String?> situation = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<double?> adjustmentLo = const Value.absent(),
                Value<double?> adjustmentHi = const Value.absent(),
                Value<double?> urgencyLo = const Value.absent(),
                Value<double?> urgencyHi = const Value.absent(),
                Value<double?> targetPower = const Value.absent(),
                Value<double?> targetCadence = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<double?> requestedPower = const Value.absent(),
                Value<double?> sustainablePower = const Value.absent(),
                Value<double?> physicsGapPercent = const Value.absent(),
              }) => CoachingAdvicesCompanion.insert(
                id: id,
                rideStartedAt: rideStartedAt,
                segmentId: segmentId,
                second: second,
                alongMeters: alongMeters,
                recordedAt: recordedAt,
                mode: mode,
                register: register,
                situation: situation,
                diagnosis: diagnosis,
                adjustmentLo: adjustmentLo,
                adjustmentHi: adjustmentHi,
                urgencyLo: urgencyLo,
                urgencyHi: urgencyHi,
                targetPower: targetPower,
                targetCadence: targetCadence,
                message: message,
                requestedPower: requestedPower,
                sustainablePower: sustainablePower,
                physicsGapPercent: physicsGapPercent,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoachingAdvicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachingAdvicesTable,
      CoachingAdvice,
      $$CoachingAdvicesTableFilterComposer,
      $$CoachingAdvicesTableOrderingComposer,
      $$CoachingAdvicesTableAnnotationComposer,
      $$CoachingAdvicesTableCreateCompanionBuilder,
      $$CoachingAdvicesTableUpdateCompanionBuilder,
      (
        CoachingAdvice,
        BaseReferences<_$AppDatabase, $CoachingAdvicesTable, CoachingAdvice>,
      ),
      CoachingAdvice,
      PrefetchHooks Function()
    >;
typedef $$BikesTableCreateCompanionBuilder =
    BikesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> brand,
      Value<String> kind,
      Value<double?> weightKg,
      Value<int?> color,
      Value<String?> photoPath,
      Value<String?> notes,
      Value<int?> lowestChainring,
      Value<int?> largestCog,
      Value<int?> largestChainring,
      Value<int?> smallestCog,
      Value<int?> wheelCircumferenceMm,
      Value<bool> isDefault,
      required DateTime createdAt,
    });
typedef $$BikesTableUpdateCompanionBuilder =
    BikesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> brand,
      Value<String> kind,
      Value<double?> weightKg,
      Value<int?> color,
      Value<String?> photoPath,
      Value<String?> notes,
      Value<int?> lowestChainring,
      Value<int?> largestCog,
      Value<int?> largestChainring,
      Value<int?> smallestCog,
      Value<int?> wheelCircumferenceMm,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
    });

class $$BikesTableFilterComposer extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableFilterComposer({
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

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowestChainring => $composableBuilder(
    column: $table.lowestChainring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get largestCog => $composableBuilder(
    column: $table.largestCog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get largestChainring => $composableBuilder(
    column: $table.largestChainring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get smallestCog => $composableBuilder(
    column: $table.smallestCog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wheelCircumferenceMm => $composableBuilder(
    column: $table.wheelCircumferenceMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BikesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableOrderingComposer({
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

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowestChainring => $composableBuilder(
    column: $table.lowestChainring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get largestCog => $composableBuilder(
    column: $table.largestCog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get largestChainring => $composableBuilder(
    column: $table.largestChainring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get smallestCog => $composableBuilder(
    column: $table.smallestCog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wheelCircumferenceMm => $composableBuilder(
    column: $table.wheelCircumferenceMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikesTable> {
  $$BikesTableAnnotationComposer({
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

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get lowestChainring => $composableBuilder(
    column: $table.lowestChainring,
    builder: (column) => column,
  );

  GeneratedColumn<int> get largestCog => $composableBuilder(
    column: $table.largestCog,
    builder: (column) => column,
  );

  GeneratedColumn<int> get largestChainring => $composableBuilder(
    column: $table.largestChainring,
    builder: (column) => column,
  );

  GeneratedColumn<int> get smallestCog => $composableBuilder(
    column: $table.smallestCog,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wheelCircumferenceMm => $composableBuilder(
    column: $table.wheelCircumferenceMm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BikesTable,
          BikeRow,
          $$BikesTableFilterComposer,
          $$BikesTableOrderingComposer,
          $$BikesTableAnnotationComposer,
          $$BikesTableCreateCompanionBuilder,
          $$BikesTableUpdateCompanionBuilder,
          (BikeRow, BaseReferences<_$AppDatabase, $BikesTable, BikeRow>),
          BikeRow,
          PrefetchHooks Function()
        > {
  $$BikesTableTableManager(_$AppDatabase db, $BikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> lowestChainring = const Value.absent(),
                Value<int?> largestCog = const Value.absent(),
                Value<int?> largestChainring = const Value.absent(),
                Value<int?> smallestCog = const Value.absent(),
                Value<int?> wheelCircumferenceMm = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BikesCompanion(
                id: id,
                name: name,
                brand: brand,
                kind: kind,
                weightKg: weightKg,
                color: color,
                photoPath: photoPath,
                notes: notes,
                lowestChainring: lowestChainring,
                largestCog: largestCog,
                largestChainring: largestChainring,
                smallestCog: smallestCog,
                wheelCircumferenceMm: wheelCircumferenceMm,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> lowestChainring = const Value.absent(),
                Value<int?> largestCog = const Value.absent(),
                Value<int?> largestChainring = const Value.absent(),
                Value<int?> smallestCog = const Value.absent(),
                Value<int?> wheelCircumferenceMm = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
              }) => BikesCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                kind: kind,
                weightKg: weightKg,
                color: color,
                photoPath: photoPath,
                notes: notes,
                lowestChainring: lowestChainring,
                largestCog: largestCog,
                largestChainring: largestChainring,
                smallestCog: smallestCog,
                wheelCircumferenceMm: wheelCircumferenceMm,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BikesTable,
      BikeRow,
      $$BikesTableFilterComposer,
      $$BikesTableOrderingComposer,
      $$BikesTableAnnotationComposer,
      $$BikesTableCreateCompanionBuilder,
      $$BikesTableUpdateCompanionBuilder,
      (BikeRow, BaseReferences<_$AppDatabase, $BikesTable, BikeRow>),
      BikeRow,
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
  $$RecordingSessionsTableTableManager get recordingSessions =>
      $$RecordingSessionsTableTableManager(_db, _db.recordingSessions);
  $$RecordingPointsTableTableManager get recordingPoints =>
      $$RecordingPointsTableTableManager(_db, _db.recordingPoints);
  $$RecordingSensorSamplesTableTableManager get recordingSensorSamples =>
      $$RecordingSensorSamplesTableTableManager(
        _db,
        _db.recordingSensorSamples,
      );
  $$ActivityCurvesTableTableManager get activityCurves =>
      $$ActivityCurvesTableTableManager(_db, _db.activityCurves);
  $$ActivityCurvePointsTableTableManager get activityCurvePoints =>
      $$ActivityCurvePointsTableTableManager(_db, _db.activityCurvePoints);
  $$CoachingAdvicesTableTableManager get coachingAdvices =>
      $$CoachingAdvicesTableTableManager(_db, _db.coachingAdvices);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db, _db.bikes);
}
