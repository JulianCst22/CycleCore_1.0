import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../data/activities_repository.dart';

export '../../../core/database/database_providers.dart' show appDatabaseProvider;

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(appDatabaseProvider));
});

/// Lista reactiva de actividades guardadas — esto es lo que consumirá
/// tu futura pantalla Home para mostrar el historial.
final activitiesListProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).watchActivities();
});
