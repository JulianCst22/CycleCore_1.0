import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Instancia única de la base de datos, compartida por cualquier feature
/// que la necesite (actividades, catálogo de teselas de elevación, etc.).
/// Vive en `core` -- y no dentro de una feature específica -- justamente
/// para evitar que dos features terminen abriendo dos conexiones
/// distintas al mismo archivo `.sqlite`.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Todas las actividades guardadas -- lectura directa de la tabla, sin
/// pasar por `ActivitiesRepository` (que trae consigo lógica de fotos/
/// altimetría que la mayoría de consumidores no necesita). Lo usan
/// varias features (profile, segments) solo para derivar estadísticas o
/// resúmenes a partir de la lista completa.
final allActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllActivities();
});
