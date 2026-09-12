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
