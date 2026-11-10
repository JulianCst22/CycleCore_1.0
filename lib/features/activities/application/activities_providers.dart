import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../elevation/elevation.dart' show ElevationDataset;
import '../data/activities_repository.dart';
import '../domain/weekly_summary.dart';


final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(appDatabaseProvider));
});

/// Lista reactiva de actividades guardadas — esto es lo que consumirá
/// tu futura pantalla Home para mostrar el historial.
final activitiesListProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).watchActivities();
});

/// Una actividad, al día: el detalle la escucha para que "Ajustar
/// altimetría" o "Editar" se vean apenas se guardan (mapa coloreado por
/// pendiente, perfil, altitud, desnivel, calorías). `null` si se borró.
final activityByIdProvider = StreamProvider.autoDispose
    .family<Activity?, int>((ref, id) {
      return ref.watch(activitiesRepositoryProvider).watchActivity(id);
    });

/// Resumen de la semana en curso (distancia, desnivel, salidas, tiempo
/// y las 6 semanas de barras) para el banner de la pantalla de
/// actividades. Se recalcula solo cuando cambian las actividades.
final weeklySummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  return ref.watch(activitiesListProvider).whenData(computeWeeklySummary);
});

/// Con qué modelo de elevación se midió una actividad (para la insignia
/// Premium). `null` si es de antes de poder elegirlo. "Ajustar
/// altimetría" la invalida al cambiar de modelo.
final activityElevationDatasetProvider = FutureProvider.autoDispose
    .family<ElevationDataset?, int>((ref, id) {
      return ref.read(activitiesRepositoryProvider).elevationDatasetOf(id);
    });
