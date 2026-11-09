import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../elevation/elevation.dart';
import 'activities_providers.dart';

/// Versión de la forma de medir la altimetría de una actividad. Subirla
/// hace que el historial entero se vuelva a medir la próxima vez que se
/// abra la app.
///
/// 2: desnivel sobre la distancia (remuestreo, promedio de 200 m,
///    umbral de 10 m), GPX anclado al modelo, tramos sin modelo
///    enganchados y barómetro (noviembre de 2026).
const int altitudeAlgorithmVersion = 2;

const _fingerprintKey = 'altitude_history_fingerprint_v1';

/// Vuelve a medir la altimetría de todas las actividades guardadas
/// cuando cambia algo que la mide: la versión de arriba o las teselas
/// descargadas (una tesela nueva, o la misma de otro modelo). Lo que ya
/// se midió con lo mismo no se repite: se guarda una huella.
///
/// Espera unos segundos antes de empezar, para no competir con el
/// arranque de la app y para que una descarga de varias teselas cuente
/// como un solo cambio; si en ese rato algo cambia de nuevo, esta pasada
/// se cancela y la siguiente la reemplaza.
final altitudeHistorySyncProvider = FutureProvider<int>((ref) async {
  final tiles = ref.watch(downloadedElevationTilesProvider).valueOrNull;
  if (tiles == null) return 0;
  final sorted = [...tiles]..sort((a, b) => a.tileName.compareTo(b.tileName));
  final fingerprint = [
    'v$altitudeAlgorithmVersion',
    for (final t in sorted)
      '${t.tileName}:${t.sizeBytes}:${t.downloadedAt.millisecondsSinceEpoch}',
  ].join('|');

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_fingerprintKey) == fingerprint) return 0;

  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(seconds: 10));
  if (cancelled) return 0;

  final done = await ref
      .read(activitiesRepositoryProvider)
      .readjustAllAltitudes(
        resolver: ref.read(elevationResolverProvider),
        cancelled: () => cancelled,
      );
  if (!cancelled) await prefs.setString(_fingerprintKey, fingerprint);
  return done;
});
