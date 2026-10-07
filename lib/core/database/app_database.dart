import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Tabla de actividades grabadas (carreras/entrenamientos).
///
/// `routePointsJson` guarda el trazado completo (lat/lng/altitud/
/// pendiente/velocidad/FC/potencia/cadencia por punto) serializado.
/// `photoPathsJson` guarda rutas absolutas a los archivos ya copiados al
/// almacenamiento permanente de la app (ver ActivitiesRepository).

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// 'race' o 'training'.
  TextColumn get activityType => text()();

  TextColumn get bikeName => text()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();

  RealColumn get distanceMeters => real()();
  RealColumn get avgSpeedKmh => real()();
  RealColumn get maxSpeedKmh => real()();
  RealColumn get elevationGainMeters => real()();

  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();

  /// Null si no hubo medidor de potencia conectado durante la grabación.
  IntColumn get avgPower => integer().nullable()();
  IntColumn get maxPower => integer().nullable()();

  /// Cadencia redondeada a RPM entero para el resumen -- el detalle por
  /// punto (RoutePointSnapshot) sí guarda el valor sin redondear.
  IntColumn get avgCadence => integer().nullable()();
  IntColumn get maxCadence => integer().nullable()();

  TextColumn get notes => text().nullable()();

  /// Bicicleta con la que se hizo, si el ciclista la tenía registrada.
  /// El nombre se sigue guardando en [bikeName] para que una actividad
  /// vieja (o una bici borrada) siga diciendo con qué se hizo.
  IntColumn get bikeId => integer().nullable()();
  TextColumn get routePointsJson => text().withDefault(const Constant('[]'))();
  TextColumn get photoPathsJson => text().withDefault(const Constant('[]'))();
}

/// Catálogo liviano de qué teselas de elevación (`.hgt`) ya se
/// descargaron a este dispositivo. El contenido binario de la tesela
/// vive en el sistema de archivos (`elevation_tiles/`), NO aquí -- esta
/// tabla solo guarda los metadatos, igual que decidimos para las fotos
/// de actividades.
class DownloadedElevationTiles extends Table {
  /// Nombre estándar de la tesela, ej. "N04W075.hgt".
  TextColumn get tileName => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tileName};
}

/// Catálogo liviano de qué regiones del grafo vial (`.roadgraph`) ya
/// se descargaron a este dispositivo -- mismo espíritu que
/// `DownloadedElevationTiles`: el contenido binario vive en el
/// sistema de archivos (`road_regions/`), esta tabla solo guarda los
/// metadatos. Ver `RoadRegionRepository` y `RoadRegion`.
class DownloadedRoadRegions extends Table {
  /// Id de la región en el catálogo `regiones.json`, ej.
  /// "norte-de-santander".
  TextColumn get regionId => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {regionId};
}

/// Segmentos creados por el usuario arrastrando dos puntos sobre la
/// polilínea de una de sus propias actividades YA APLANADA contra HGT
/// (ver `ActivityAltitudeFlattener`). Nacen con la mayor confiabilidad
/// geográfica posible porque parten de datos ya limpios, no de un GPX
/// externo.
///
/// `profileJson` congela el perfil completo del tramo (distancia
/// acumulada, lat/lng, altitud y pendiente por punto). Es el que se
/// consulta por "lookup" mientras el segmento está activo en vivo, en
/// vez de recalcular pendiente con sensores -- ver
/// `SegmentDetectionService` (Fase 5).
class Segments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// De dónde nació el segmento:
  ///  - `activity`      : recortado de una actividad propia ya aplanada
  ///                      contra HGT (`SegmentCreationScreen`).
  ///  - `gpxImport`     : importado de un archivo GPX que subió el
  ///                      usuario (altitud barométrica de un
  ///                      ciclocomputador -- prioridad 1 sobre HGT).
  ///  - `nativeCatalog` : descargado del catálogo remoto de segmentos
  ///                      "nativos" de la app (mismo patrón que las
  ///                      teselas de elevación y el grafo vial).
  TextColumn get source => text().withDefault(const Constant('activity'))();

  /// Id del segmento en el catálogo remoto -- solo para `nativeCatalog`.
  /// Sirve para no volver a importar el mismo segmento oficial si el
  /// usuario toca "descargar" dos veces. `null` para segmentos locales.
  TextColumn get remoteId => text().nullable()();

  /// Reservado para cuando exista backend real (ver notas del
  /// proyecto: por ahora todo es local, así que esto siempre queda en
  /// `false`). El campo ya existe para no requerir otra migración
  /// cuando llegue la sincronización en la nube.
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();

  /// Si `SegmentDetectionService` debe vigilar este segmento mientras
  /// se pedalea. El usuario lo prende/apaga desde el menú de
  /// segmentos (Fase 4) -- si está activo, arranca solo al pasar por
  /// su inicio con el rumbo correcto; si no, se ignora por completo.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  RealColumn get startLat => real()();
  RealColumn get startLng => real()();
  RealColumn get endLat => real()();
  RealColumn get endLng => real()();

  /// Rumbo de referencia (grados, 0-360) en el arranque del segmento,
  /// calculado sobre los primeros metros del tramo al crearlo. Se usa
  /// para exigir que el ciclista vaya en el sentido correcto y no
  /// disparar el segmento si pasa en contravía o por una calle
  /// paralela.
  RealColumn get startBearingDegrees => real()();

  RealColumn get distanceMeters => real()();
  RealColumn get elevationGainMeters => real()();
  RealColumn get avgSlopePercent => real()();
  RealColumn get maxSlopePercent => real()();

  /// Perfil congelado del tramo, serializado en JSON: lista de
  /// `{dist, lat, lng, alt, slope}` en orden desde el inicio hasta el
  /// fin del segmento.
  TextColumn get profileJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// De qué actividad salió este segmento -- trazabilidad, y permite
  /// regenerar el perfil más adelante si cambia el método de
  /// aplanado sin perder el segmento.
  IntColumn get sourceActivityId => integer().nullable()();
}

/// Un "esfuerzo": cada vez que el usuario completa un segmento activo
/// dentro de una actividad. Permite comparar contra la mejor marca
/// propia (equivalente a los "segment efforts" de Strava) y alimentar
/// después el motor difuso de frases de voz ("vas mejor que tu mejor
/// marca", etc.).
class SegmentEfforts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get segmentId => integer()();
  IntColumn get activityId => integer()();
  IntColumn get durationSeconds => integer()();
  RealColumn get avgSpeedKmh => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get avgPower => integer().nullable()();
  DateTimeColumn get completedAt => dateTime()();

  /// Curva tiempo-vs-distancia REAL de este esfuerzo, serializada como
  /// JSON: `[{d: <metros desde el inicio>, t: <segundos>}]`. Es lo que
  /// alimenta el "fantasma" de la mejor marca en la pantalla de
  /// segmento en vivo (Fase D) -- el fantasma se mueve a la velocidad
  /// real que llevaba el ciclista en cada punto, no a un ritmo
  /// promedio constante. `'[]'` para esfuerzos grabados antes de la
  /// Fase C.
  TextColumn get splitsJson => text().withDefault(const Constant('[]'))();
}

/// Lugares que el usuario guardó para navegar rápido (Casa, un alto que
/// hace seguido, un punto de encuentro). Aparecen primero en el buscador
/// de "Navegar" y con estrella sobre el mapa. Ver `SavedPlacesRepository`.
class SavedPlaces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// 'home' | 'peak' | 'generic' -- decide el ícono. 'peak' se sugiere
  /// solo cuando el nombre parece un alto (ver `climb_detection.dart`).
  TextColumn get kind => text().withDefault(const Constant('generic'))();

  DateTimeColumn get createdAt => dateTime()();
}

/// Diario de la grabación EN CURSO -- la "caja negra" que evita perder
/// el recorrido si la app se cierra a mitad de la salida (Android la
/// mata por batería, se desliza de recientes, un crash). Mientras se
/// graba, `RecordingJournal` va escribiendo acá por lotes; al guardar
/// la actividad en el historial (o descartarla) las tres tablas del
/// diario se vacían. Si al abrir la app todavía tienen datos, la
/// grabación no terminó bien y se ofrece recuperarla.
///
/// Hay a lo sumo UNA sesión a la vez: empezar a grabar borra cualquier
/// resto anterior.
class RecordingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();

  /// Tiempo en movimiento (sin pausas) acumulado hasta la última
  /// escritura, en milisegundos. Lo que pase entre esa escritura y la
  /// reapertura de la app se trata como pausa.
  IntColumn get movingMillis => integer().withDefault(const Constant(0))();

  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();

  /// Cuándo se tocó "Terminar". `null` mientras se sigue grabando; con
  /// valor, la app se cerró ya en la pantalla de guardar.
  DateTimeColumn get endedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
}

/// Cada punto GPS de la sesión del diario, en orden de `id`. Guarda el
/// `RoutePoint` tal cual más la distancia/velocidad ya priorizadas
/// (sensor BLE o GPS) de ese instante -- lo que `finishRecording`
/// necesita para armar el resumen sin recalcular nada.
///
/// Los instantes van en milisegundos (`IntColumn`) y no como
/// `DateTimeColumn`: Drift guarda las fechas con precisión de segundos,
/// y dos puntos GPS pueden caer en el mismo segundo.
class RecordingPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real()();
  RealColumn get speedMetersPerSecond => real()();
  RealColumn get bearingDegrees => real()();
  RealColumn get accuracyMeters => real()();
  IntColumn get timestampMillis => integer()();
  RealColumn get distanceMeters => real()();
  RealColumn get speedKmh => real()();
}

/// Muestras de FC / potencia / cadencia de la sesión del diario -- lo
/// mismo que acumula `RideSensorLog` en memoria.
class RecordingSensorSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();

  /// 'hr' | 'power' | 'cadence' -- ver `RecordingSampleKind`.
  TextColumn get kind => text()();

  IntColumn get timestampMillis => integer()();
  RealColumn get value => real()();
}

/// Marca de que las curvas de una actividad ya se calcularon (feature
/// stats), aunque no haya salido ningún punto (una salida sin
/// potenciómetro ni pulsómetro). [version] es la del algoritmo: si cambia,
/// las curvas se vuelven a calcular.
class ActivityCurves extends Table {
  IntColumn get activityId => integer()();
  IntColumn get version => integer()();

  /// Largo de la serie de 1 Hz (tiempo en movimiento) y cuántos de esos
  /// segundos tuvieron lectura de cada sensor.
  IntColumn get movingSeconds => integer()();
  IntColumn get powerSeconds => integer()();
  IntColumn get heartRateSeconds => integer()();

  /// Mediana de la cadencia subiendo (rpm). De acá sale la referencia
  /// con la que el coach mide el torque. `null` si la salida no trajo
  /// subida con cadencia.
  RealColumn get climbingCadence => real().nullable()();

  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {activityId};
}

/// Mejor media de cada duración (5 s a 60 min) dentro de una actividad:
/// la curva de potencia y la de FC. El histórico de un periodo es el
/// máximo por duración entre sus actividades.
class ActivityCurvePoints extends Table {
  IntColumn get activityId => integer()();

  /// 'power' | 'heartRate' -- ver `CurveKind` en stats.
  TextColumn get kind => text()();

  IntColumn get durationSeconds => integer()();
  RealColumn get value => real()();

  /// Segundo (en movimiento) donde empieza ese mejor esfuerzo.
  IntColumn get startSecond => integer()();

  @override
  Set<Column> get primaryKey => {activityId, kind, durationSeconds};
}

/// Registro de los avisos que dio el coach (feature coaching): qué dijo,
/// dónde, con qué tono y con qué números. Se enlaza con la actividad por
/// su hora de inicio, que ya existe mientras se graba (la actividad no
/// tiene id hasta que se guarda).
class CoachingAdvices extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get rideStartedAt => dateTime()();
  IntColumn get segmentId => integer()();

  /// Segundos en movimiento desde que empezó el segmento, y metros
  /// recorridos dentro de él.
  IntColumn get second => integer()();
  RealColumn get alongMeters => real()();
  DateTimeColumn get recordedAt => dateTime()();

  /// 'type1' | 'type2'.
  TextColumn get mode => text()();

  /// Tono del mensaje (`Register`) y celda del tensor de situaciones
  /// ('estado/demanda/fase').
  TextColumn get register => text()();
  TextColumn get situation => text().nullable()();

  /// Regla que explica el aviso (id de la base de reglas).
  TextColumn get diagnosis => text().nullable()();

  /// Centroides de intervalo del ajuste y de la urgencia.
  RealColumn get adjustmentLo => real().nullable()();
  RealColumn get adjustmentHi => real().nullable()();
  RealColumn get urgencyLo => real().nullable()();
  RealColumn get urgencyHi => real().nullable()();

  /// Números dichos en voz alta.
  RealColumn get targetPower => real().nullable()();
  RealColumn get targetCadence => real().nullable()();

  /// Frase que se dijo (la arma el compositor de mensajes).
  TextColumn get message => text().nullable()();

  /// Verificación física independiente (F12): los vatios que pidieron
  /// las reglas sin recortar, los que dice la ecuación de la reserva, y
  /// cuánto se separaron en puntos porcentuales. Se guarda para poder
  /// revisar después si la base de reglas se está yendo de la física.
  RealColumn get requestedPower => real().nullable()();
  RealColumn get sustainablePower => real().nullable()();
  RealColumn get physicsGapPercent => real().nullable()();
}

/// Una fila de la curva de una actividad junto con los datos de la
/// actividad que hacen falta para mostrar su origen.
typedef CurvePointWithActivity = ({
  ActivityCurvePoint point,
  DateTime startedAt,
  String title,
});

/// Las bicicletas del ciclista (feature bikes).
///
/// El peso y el tipo no son adorno: con ellos el motor estima la
/// potencia a partir de la velocidad y la pendiente cuando no hay
/// potenciómetro, y ahí la masa total entra multiplicando. El resto
/// (marca, color, foto) es para reconocerla de un vistazo.
///
/// La fila se llama `BikeRow` para dejarle el nombre `Bike` al modelo
/// del dominio, que es el que sabe de rodadura y de arrastre.
@DataClassName('BikeRow')
class Bikes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();

  /// 'ruta' | 'montana'. Cambia la resistencia a la rodadura y el área
  /// frontal que se suponen.
  TextColumn get kind => text().withDefault(const Constant('ruta'))();

  /// Peso de la bicicleta lista para rodar, en kilos.
  RealColumn get weightKg => real().nullable()();

  /// Color como entero ARGB, para pintar su ficha.
  IntColumn get color => integer().nullable()();

  /// Ruta local de la foto. Null = sin foto.
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// El desarrollo más suave que tiene: dientes del plato pequeño y del
  /// piñón grande. Con eso se sabe a qué cadencia se puede pedalear a
  /// una velocidad dada, y por tanto si al ciclista le queda piñón o ya
  /// está en el último. Null = se supone el típico de su tipo.
  IntColumn get lowestChainring => integer().nullable()();
  IntColumn get largestCog => integer().nullable()();
  IntColumn get largestChainring => integer().nullable()();
  IntColumn get smallestCog => integer().nullable()();

  /// Desarrollo de la rueda en milímetros (perímetro).
  IntColumn get wheelCircumferenceMm => integer().nullable()();

  /// La que se usa por defecto al guardar una salida y la que mira el
  /// coach. Solo una queda en true.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Activities,
    DownloadedElevationTiles,
    Segments,
    SegmentEfforts,
    DownloadedRoadRegions,
    SavedPlaces,
    RecordingSessions,
    RecordingPoints,
    RecordingSensorSamples,
    ActivityCurves,
    ActivityCurvePoints,
    CoachingAdvices,
    Bikes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Base sobre un ejecutor arbitrario -- en los tests, una SQLite en
  /// memoria (`NativeDatabase.memory()`).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Quien venía de la versión 1 (antes de las teselas de
      // elevación) solo necesita la tabla nueva; Activities no cambió.
      if (from < 2) {
        await m.createTable(downloadedElevationTiles);
      }
      // Quien venía de antes del módulo de potencia/cadencia (v3)
      // necesita estas 4 columnas nuevas, todas nullable -- las
      // actividades ya guardadas simplemente quedan con estos campos
      // en null (equivalente a "sin sensor conectado ese día").
      if (from < 3) {
        await m.addColumn(activities, activities.avgPower);
        await m.addColumn(activities, activities.maxPower);
        await m.addColumn(activities, activities.avgCadence);
        await m.addColumn(activities, activities.maxCadence);
      }
      // Módulo de segmentos (Fase 1): quien venía de antes de v4
      // simplemente no tenía estas dos tablas -- se crean vacías,
      // no hay datos previos que migrar.
      if (from < 4) {
        await m.createTable(segments);
        await m.createTable(segmentEfforts);
      }
      // Módulo de navegación (Fase 1): igual que segmentos, tabla
      // nueva vacía -- nadie tenía regiones descargadas antes de
      // que existiera el concepto.
      if (from < 5) {
        await m.createTable(downloadedRoadRegions);
      }
      // Segmentos en vivo (Fases B/C): origen del segmento
      // (actividad / GPX importado / catálogo remoto), id remoto
      // para dedup del catálogo, y la curva tiempo-distancia del
      // esfuerzo para el fantasma. Todas con default, así las filas
      // ya existentes quedan como `source='activity'`,
      // `remoteId=null`, `splitsJson='[]'`.
      if (from < 6) {
        await m.addColumn(segments, segments.source);
        await m.addColumn(segments, segments.remoteId);
        await m.addColumn(segmentEfforts, segmentEfforts.splitsJson);
      }
      // Ubicaciones guardadas para navegar (Casa, altos frecuentes...).
      // Tabla nueva vacía -- nadie tenía lugares guardados antes.
      if (from < 7) {
        await m.createTable(savedPlaces);
      }
      // Diario de la grabación en curso (recuperación tras un cierre
      // inesperado). Tablas nuevas vacías -- no hay nada que migrar.
      if (from < 8) {
        await m.createTable(recordingSessions);
        await m.createTable(recordingPoints);
        await m.createTable(recordingSensorSamples);
      }
      // Curvas de potencia/FC y registro del coach. Las tablas nacen
      // vacías: las curvas de las actividades ya guardadas las calcula
      // stats al abrir la app (este módulo no conoce el cálculo), igual
      // que las de cualquier actividad que todavía no las tenga.
      if (from < 9) {
        await m.createTable(activityCurves);
        await m.createTable(activityCurvePoints);
        await m.createTable(coachingAdvices);
      }
      // La bicicleta pasa de ser un texto suelto en cada actividad a ser
      // una ficha con peso y tipo. Las actividades viejas conservan su
      // nombre y se quedan sin enlace, que es lo correcto: nadie sabe
      // con cuál de las bicis nuevas se hicieron.
      if (from < 10) {
        await m.createTable(bikes);
        await m.addColumn(activities, activities.bikeId);
      }
      // El registro del coach empieza a guardar el contraste con la
      // física. Los avisos viejos se quedan sin él: no se puede
      // reconstruir sin la reserva que había en ese instante.
      //
      // Solo para quien ya tenía la tabla: al que viene de antes de la
      // v9 se la acabamos de crear, y `createTable` la crea con el
      // esquema de hoy, columnas nuevas incluidas.
      if (from >= 9 && from < 11) {
        await m.addColumn(coachingAdvices, coachingAdvices.requestedPower);
        await m.addColumn(coachingAdvices, coachingAdvices.sustainablePower);
        await m.addColumn(coachingAdvices, coachingAdvices.physicsGapPercent);
      }
      // El otro extremo de la transmisión: con él, el coach sabe si
      // queda piñón para bajar cuando la cadencia se dispara. Igual que
      // arriba, solo para quien ya tenía la tabla.
      if (from >= 10 && from < 12) {
        await m.addColumn(bikes, bikes.largestChainring);
        await m.addColumn(bikes, bikes.smallestCog);
      }
      // La cadencia de subida de cada salida. Nace vacía y se llena
      // sola: subir la versión del cálculo hace que stats recalcule las
      // curvas de todas las actividades, y de paso la mide.
      if (from >= 9 && from < 13) {
        await m.addColumn(activityCurves, activityCurves.climbingCadence);
      }
    },
  );

  // ---------------------------------------------------------------
  // Diario de la grabación en curso
  // ---------------------------------------------------------------
  //
  // Lo consulta `RecordingJournal` (feature recording). Las escrituras
  // van siempre en lote/transacción: si la app muere a mitad de una, no
  // queda un punto sin su progreso ni una sesión a medio borrar.

  /// Abre una sesión nueva, borrando antes cualquier resto de una
  /// anterior. Devuelve el id de la sesión.
  Future<int> startRecordingSession(DateTime startedAt) {
    return transaction(() async {
      await clearRecordingJournal();
      return into(recordingSessions).insert(
        RecordingSessionsCompanion.insert(
          startedAt: startedAt,
          updatedAt: startedAt,
        ),
      );
    });
  }

  /// La sesión del diario, si la hay.
  Future<RecordingSession?> getRecordingSession() {
    return (select(recordingSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Agrega puntos y muestras y actualiza el progreso de la sesión, todo
  /// en un único lote atómico.
  Future<void> appendToRecordingJournal({
    required int sessionId,
    required RecordingSessionsCompanion progress,
    required List<RecordingPointsCompanion> points,
    required List<RecordingSensorSamplesCompanion> samples,
  }) {
    return batch((b) {
      b.insertAll(recordingPoints, points);
      b.insertAll(recordingSensorSamples, samples);
      b.update(
        recordingSessions,
        progress,
        where: (s) => s.id.equals(sessionId),
      );
    });
  }

  Future<List<RecordingPoint>> getRecordingPoints(int sessionId) {
    return (select(recordingPoints)
          ..where((p) => p.sessionId.equals(sessionId))
          ..orderBy([(p) => OrderingTerm.asc(p.id)]))
        .get();
  }

  Future<List<RecordingSensorSample>> getRecordingSensorSamples(int sessionId) {
    return (select(recordingSensorSamples)
          ..where((s) => s.sessionId.equals(sessionId))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();
  }

  /// Vacía las tres tablas del diario.
  Future<void> clearRecordingJournal() {
    return batch((b) {
      b.deleteAll(recordingPoints);
      b.deleteAll(recordingSensorSamples);
      b.deleteAll(recordingSessions);
    });
  }

  // ---------------------------------------------------------------
  // Ubicaciones guardadas
  // ---------------------------------------------------------------

  Stream<List<SavedPlace>> watchSavedPlaces() {
    return (select(
      savedPlaces,
    )..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();
  }

  Future<int> insertSavedPlace(SavedPlacesCompanion entry) {
    return into(savedPlaces).insert(entry);
  }

  Future<void> updateSavedPlace(SavedPlacesCompanion entry) {
    return update(savedPlaces).replace(entry);
  }

  Future<void> deleteSavedPlace(int id) {
    return (delete(savedPlaces)..where((p) => p.id.equals(id))).go();
  }

  // ---------------------------------------------------------------
  // Actividades
  // ---------------------------------------------------------------

  /// Stream reactivo: cualquier pantalla que lo escuche (ej. el futuro
  /// Home con el historial) se actualiza sola cuando se guarda o borra
  /// una actividad, sin necesidad de refrescar manualmente.
  Stream<List<Activity>> watchAllActivities() {
    return (select(
      activities,
    )..orderBy([(a) => OrderingTerm.desc(a.startedAt)])).watch();
  }

  Future<Activity?> getActivityById(int id) {
    return (select(
      activities,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertActivity(ActivitiesCompanion entry) {
    return into(activities).insert(entry);
  }

  /// Si ya hay una actividad que empezó en [startedAt] -- lo usa el
  /// diario de grabación para reconocer una sesión que alcanzó a
  /// guardarse en el historial justo antes de que la app se cerrara.
  Future<bool> hasActivityStartedAt(DateTime startedAt) async {
    final match =
        await (select(activities)
              ..where((a) => a.startedAt.equals(startedAt))
              ..limit(1))
            .getSingleOrNull();
    return match != null;
  }

  /// Borra la actividad junto con sus curvas y los avisos del coach que
  /// se dieron en ella.
  Future<void> deleteActivity(int id) {
    return transaction(() async {
      final startedAt =
          await (selectOnly(activities)
                ..addColumns([activities.startedAt])
                ..where(activities.id.equals(id)))
              .map((row) => row.read(activities.startedAt))
              .getSingleOrNull();
      await (delete(
        activityCurvePoints,
      )..where((p) => p.activityId.equals(id))).go();
      await (delete(
        activityCurves,
      )..where((c) => c.activityId.equals(id))).go();
      if (startedAt != null) {
        await (delete(
          coachingAdvices,
        )..where((a) => a.rideStartedAt.equals(startedAt))).go();
      }
      await (delete(activities)..where((a) => a.id.equals(id))).go();
    });
  }

  // ---------------------------------------------------------------
  // Curvas de medias máximas
  // ---------------------------------------------------------------
  //
  // Las calcula y las consulta la feature stats; acá solo se guardan.

  /// Actividades sin curvas, o con curvas de un algoritmo anterior a
  /// [version], de la más reciente a la más antigua.
  Future<List<int>> getActivityIdsNeedingCurves(int version) {
    final query =
        selectOnly(activities).join([
            leftOuterJoin(
              activityCurves,
              activityCurves.activityId.equalsExp(activities.id),
              useColumns: false,
            ),
          ])
          ..addColumns([activities.id])
          ..where(
            activityCurves.activityId.isNull() |
                activityCurves.version.isSmallerThanValue(version),
          )
          ..orderBy([OrderingTerm.desc(activities.startedAt)]);
    return query.map((row) => row.read(activities.id)!).get();
  }

  /// Reemplaza las curvas de una actividad (cabecera y puntos) de una sola
  /// vez. Si la actividad se borró mientras se calculaban, no guarda
  /// nada. Devuelve si guardó.
  Future<bool> replaceActivityCurves(
    ActivityCurvesCompanion header,
    List<ActivityCurvePointsCompanion> points,
  ) {
    final id = header.activityId.value;
    return transaction(() async {
      final exists =
          await (selectOnly(activities)
                ..addColumns([activities.id])
                ..where(activities.id.equals(id)))
              .getSingleOrNull() !=
          null;
      if (!exists) return false;
      await (delete(
        activityCurvePoints,
      )..where((p) => p.activityId.equals(id))).go();
      await into(activityCurves).insertOnConflictUpdate(header);
      await batch((b) => b.insertAll(activityCurvePoints, points));
      return true;
    });
  }

  Future<ActivityCurve?> getActivityCurve(int activityId) {
    return (select(
      activityCurves,
    )..where((c) => c.activityId.equals(activityId))).getSingleOrNull();
  }

  Stream<ActivityCurve?> watchActivityCurve(int activityId) {
    return (select(
      activityCurves,
    )..where((c) => c.activityId.equals(activityId))).watchSingleOrNull();
  }

  Stream<List<ActivityCurvePoint>> watchCurvePointsForActivity(int activityId) {
    return (select(activityCurvePoints)
          ..where((p) => p.activityId.equals(activityId))
          ..orderBy([(p) => OrderingTerm.asc(p.durationSeconds)]))
        .watch();
  }

  /// Cadencias de subida medidas, de las actividades que empezaron
  /// desde [since] (todas si es `null`).
  Stream<List<double>> watchClimbingCadences({DateTime? since}) {
    var filter = activityCurves.climbingCadence.isNotNull();
    if (since != null) {
      filter = filter & activities.startedAt.isBiggerOrEqualValue(since);
    }
    final query =
        select(activityCurves).join([
            innerJoin(
              activities,
              activities.id.equalsExp(activityCurves.activityId),
              useColumns: false,
            ),
          ])
          ..where(filter);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          ?row.readTable(activityCurves).climbingCadence,
      ],
    );
  }

  /// Puntos de curva de tipo [kind] de las actividades que empezaron
  /// dentro de `[since, until)` (sin límite si van en `null`), con la
  /// fecha y el título de su actividad.
  Stream<List<CurvePointWithActivity>> watchCurvePoints({
    required String kind,
    DateTime? since,
    DateTime? until,
  }) {
    var filter = activityCurvePoints.kind.equals(kind);
    if (since != null) {
      filter = filter & activities.startedAt.isBiggerOrEqualValue(since);
    }
    if (until != null) {
      filter = filter & activities.startedAt.isSmallerThanValue(until);
    }
    final query =
        select(activityCurvePoints).join([
            innerJoin(
              activities,
              activities.id.equalsExp(activityCurvePoints.activityId),
              useColumns: false,
            ),
          ])
          ..addColumns([activities.startedAt, activities.title])
          ..where(filter);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            point: row.readTable(activityCurvePoints),
            startedAt: row.read(activities.startedAt)!,
            title: row.read(activities.title)!,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Registro de avisos del coach
  // ---------------------------------------------------------------

  Future<int> insertCoachingAdvice(CoachingAdvicesCompanion entry) {
    return into(coachingAdvices).insert(entry);
  }

  /// Avisos de la salida que empezó en [rideStartedAt], en el orden en
  /// que se dieron.
  Future<List<CoachingAdvice>> getCoachingAdvicesForRide(
    DateTime rideStartedAt,
  ) {
    return (select(coachingAdvices)
          ..where((a) => a.rideStartedAt.equals(rideStartedAt))
          ..orderBy([(a) => OrderingTerm.asc(a.id)]))
        .get();
  }

  // ---------------------------------------------------------------
  // Catálogo de teselas de elevación
  // ---------------------------------------------------------------

  Stream<List<DownloadedElevationTile>> watchDownloadedTiles() {
    return select(downloadedElevationTiles).watch();
  }

  Future<List<DownloadedElevationTile>> getAllDownloadedTiles() {
    return select(downloadedElevationTiles).get();
  }

  Future<DownloadedElevationTile?> getTile(String tileName) {
    return (select(
      downloadedElevationTiles,
    )..where((t) => t.tileName.equals(tileName))).getSingleOrNull();
  }

  Future<void> upsertTile(DownloadedElevationTilesCompanion entry) {
    return into(downloadedElevationTiles).insertOnConflictUpdate(entry);
  }

  Future<void> deleteTile(String tileName) {
    return (delete(
      downloadedElevationTiles,
    )..where((t) => t.tileName.equals(tileName))).go();
  }

  // ---------------------------------------------------------------
  // Catálogo de regiones del grafo vial (Navegación)
  // ---------------------------------------------------------------
  //
  // Mismo patrón que el catálogo de teselas de elevación de arriba --
  // esto es lo que consulta `RoadRegionRepository`.

  Stream<List<DownloadedRoadRegion>> watchDownloadedRoadRegions() {
    return select(downloadedRoadRegions).watch();
  }

  Future<List<DownloadedRoadRegion>> getAllDownloadedRoadRegions() {
    return select(downloadedRoadRegions).get();
  }

  Future<DownloadedRoadRegion?> getRoadRegion(String regionId) {
    return (select(
      downloadedRoadRegions,
    )..where((r) => r.regionId.equals(regionId))).getSingleOrNull();
  }

  Future<void> upsertRoadRegion(DownloadedRoadRegionsCompanion entry) {
    return into(downloadedRoadRegions).insertOnConflictUpdate(entry);
  }

  Future<void> deleteRoadRegion(String regionId) {
    return (delete(
      downloadedRoadRegions,
    )..where((r) => r.regionId.equals(regionId))).go();
  }

  // ---------------------------------------------------------------
  // Segmentos
  // ---------------------------------------------------------------
  //
  // CRUD mínimo necesario para que la Fase 1 quede completa y
  // probable por sí sola (se puede insertar/leer un segmento antes de
  // que exista cualquier pantalla). La Fase 2 construye el
  // `SegmentsRepository` de dominio sobre estos métodos.

  /// Stream reactivo de todos los segmentos del usuario -- lo usará el
  /// menú de segmentos (Fase 4) para la lista con el toggle de
  /// activo/inactivo.
  Stream<List<Segment>> watchAllSegments() {
    return (select(
      segments,
    )..orderBy([(s) => OrderingTerm.asc(s.name)])).watch();
  }

  /// Solo los segmentos activos -- es la lista que consulta
  /// `SegmentDetectionService` en cada punto GPS nuevo mientras NO se
  /// está dentro de un segmento, así que conviene tenerla ya filtrada
  /// en la base de datos y no traer todos para filtrar en Dart.
  Future<List<Segment>> getActiveSegments() {
    return (select(segments)..where((s) => s.isActive.equals(true))).get();
  }

  /// Segmentos que nacieron de un GPX (importado o del catálogo) --
  /// sus perfiles son la fuente de elevación de PRIORIDAD 1 para el
  /// aplanado de actividades (ver `GpxTrackRepository` /
  /// `ElevationResolver`). Un segmento recortado de una actividad
  /// (`source = 'activity'`) NO cuenta: su altitud ya salió de HGT, no
  /// aportaría nada nuevo como fuente.
  Future<List<Segment>> getGpxOriginSegments() {
    return (select(
      segments,
    )..where((s) => s.source.equals('activity').not())).get();
  }

  Future<Segment?> getSegmentById(int id) {
    return (select(segments)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Segmento descargado del catálogo remoto por su id remoto -- para
  /// que `SegmentCatalogRepository` no re-importe el mismo segmento
  /// oficial si el usuario toca "descargar" dos veces.
  Future<Segment?> getSegmentByRemoteId(String remoteId) {
    return (select(
      segments,
    )..where((s) => s.remoteId.equals(remoteId))).getSingleOrNull();
  }

  Future<int> insertSegment(SegmentsCompanion entry) {
    return into(segments).insert(entry);
  }

  /// Prende/apaga la vigilancia de un segmento -- lo que dispara el
  /// toggle del menú de segmentos.
  Future<void> setSegmentActive(int id, bool isActive) {
    return (update(segments)..where((s) => s.id.equals(id))).write(
      SegmentsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> renameSegment(int id, String name) {
    return (update(segments)..where((s) => s.id.equals(id))).write(
      SegmentsCompanion(name: Value(name)),
    );
  }

  Future<void> deleteSegment(int id) {
    return (delete(segments)..where((s) => s.id.equals(id))).go();
  }

  // ---------------------------------------------------------------
  // Esfuerzos sobre segmentos
  // ---------------------------------------------------------------

  Future<int> insertSegmentEffort(SegmentEffortsCompanion entry) {
    return into(segmentEfforts).insert(entry);
  }

  /// Borra un esfuerzo puntual -- para poder limpiar tiempos sueltos
  /// desde el detalle del segmento (útil sobre todo con tiempos de
  /// prueba incoherentes).
  Future<void> deleteSegmentEffort(int id) {
    return (delete(segmentEfforts)..where((e) => e.id.equals(id))).go();
  }

  /// Borra TODOS los esfuerzos de un segmento -- "empezar de cero" el
  /// historial de ese segmento.
  Future<void> deleteAllEffortsForSegment(int segmentId) {
    return (delete(
      segmentEfforts,
    )..where((e) => e.segmentId.equals(segmentId))).go();
  }

  /// Todos los esfuerzos de un segmento, del más rápido al más lento --
  /// pensado para poder sacar la mejor marca directamente con
  /// `.first` sin ordenar de nuevo en Dart.
  Future<List<SegmentEffort>> getEffortsForSegment(int segmentId) {
    return (select(segmentEfforts)
          ..where((e) => e.segmentId.equals(segmentId))
          ..orderBy([(e) => OrderingTerm.asc(e.durationSeconds)]))
        .get();
  }

  Stream<List<SegmentEffort>> watchEffortsForSegment(int segmentId) {
    return (select(segmentEfforts)
          ..where((e) => e.segmentId.equals(segmentId))
          ..orderBy([(e) => OrderingTerm.asc(e.durationSeconds)]))
        .watch();
  }

  /// Todos los esfuerzos de todos los segmentos, del más reciente al
  /// más antiguo -- alimenta el resumen y el feed de "esfuerzos
  /// recientes" del menú de segmentos.
  Stream<List<SegmentEffort>> watchAllEfforts() {
    return (select(
      segmentEfforts,
    )..orderBy([(e) => OrderingTerm.desc(e.completedAt)])).watch();
  }

  /// Todos los esfuerzos registrados dentro de UNA actividad puntual --
  /// a diferencia de `getEffortsForSegment`/`watchEffortsForSegment`
  /// (que miran "todos los intentos de este segmento, sin importar en
  /// qué actividad"), esto es "qué segmentos se completaron DURANTE
  /// esta actividad". Lo usa `ActivityDetailScreen` para la sección
  /// "Segmentos en esta ruta".
  Future<List<SegmentEffort>> getEffortsForActivity(int activityId) {
    return (select(
      segmentEfforts,
    )..where((e) => e.activityId.equals(activityId))).get();
  }

  // ---------------------------------------------------------------
  // Bicicletas
  // ---------------------------------------------------------------

  /// Las bicicletas, la predeterminada primero y después por nombre.
  Stream<List<BikeRow>> watchBikes() {
    return (select(bikes)..orderBy([
          (b) => OrderingTerm.desc(b.isDefault),
          (b) => OrderingTerm.asc(b.name),
        ]))
        .watch();
  }

  Future<List<BikeRow>> allBikes() {
    return (select(bikes)..orderBy([
          (b) => OrderingTerm.desc(b.isDefault),
          (b) => OrderingTerm.asc(b.name),
        ]))
        .get();
  }

  Future<BikeRow?> getBikeById(int id) {
    return (select(bikes)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  /// La bicicleta con la que trabaja el coach: la predeterminada, o la
  /// primera que haya si ninguna lo es.
  Future<BikeRow?> getDefaultBike() async {
    final rows = await allBikes();
    return rows.isEmpty ? null : rows.first;
  }

  /// Guarda una bicicleta nueva. La primera queda predeterminada sola:
  /// quien solo tiene una no debería tener que elegirla.
  Future<int> insertBike(BikesCompanion entry) async {
    return transaction(() async {
      final first = (await select(bikes).get()).isEmpty;
      final id = await into(
        bikes,
      ).insert(first ? entry.copyWith(isDefault: const Value(true)) : entry);
      if (entry.isDefault.present && entry.isDefault.value) {
        await _clearDefaultExcept(id);
      }
      return id;
    });
  }

  Future<bool> updateBike(BikeRow bike) async {
    return transaction(() async {
      final saved = await update(bikes).replace(bike);
      if (bike.isDefault) await _clearDefaultExcept(bike.id);
      return saved;
    });
  }

  /// Borra la bicicleta y desenlaza sus actividades, que conservan el
  /// nombre con el que se guardaron.
  Future<void> deleteBike(int id) {
    return transaction(() async {
      await (update(activities)..where((a) => a.bikeId.equals(id))).write(
        const ActivitiesCompanion(bikeId: Value(null)),
      );
      await (delete(bikes)..where((b) => b.id.equals(id))).go();
      final rest = await select(bikes).get();
      if (rest.isNotEmpty && !rest.any((b) => b.isDefault)) {
        await (update(bikes)..where((b) => b.id.equals(rest.first.id))).write(
          const BikesCompanion(isDefault: Value(true)),
        );
      }
    });
  }

  Future<void> setDefaultBike(int id) {
    return transaction(() async {
      await (update(bikes)..where((b) => b.id.equals(id))).write(
        const BikesCompanion(isDefault: Value(true)),
      );
      await _clearDefaultExcept(id);
    });
  }

  Future<void> _clearDefaultExcept(int id) {
    return (update(bikes)..where((b) => b.id.isNotValue(id))).write(
      const BikesCompanion(isDefault: Value(false)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecore.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
