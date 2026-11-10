import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../elevation/elevation.dart';
import 'activities_providers.dart';

/// Versión de la forma de medir la altimetría de una actividad. Subirla
/// hace que el historial entero se vuelva a medir (con el modelo elegido
/// en Ajustes) la próxima vez que se abra la app.
///
/// 2: desnivel sobre la distancia (remuestreo, promedio de 200 m,
///    umbral de 10 m), GPX anclado al modelo, tramos sin modelo
///    enganchados y barómetro (noviembre de 2026).
const int altitudeAlgorithmVersion = 2;

const _versionKey = 'altitude_history_version_v1';

/// De antes: una huella que también incluía las teselas descargadas.
/// Solo se lee para no repetir la pasada de la versión 2.
const _legacyFingerprintKey = 'altitude_history_fingerprint_v1';

/// Vuelve a medir la altimetría de todas las actividades guardadas cuando
/// cambia la forma de medir ([altitudeAlgorithmVersion]). Cambiar de
/// modelo o bajar teselas NO la dispara: eso solo afecta a las salidas
/// nuevas, y una guardada se cambia a mano en "Ajustar altimetría".
///
/// Espera unos segundos antes de empezar, para no competir con el
/// arranque de la app; si en ese rato se descarta, la pasada se cancela.
final altitudeHistorySyncProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  var done = prefs.getInt(_versionKey);
  final legacy = prefs.getString(_legacyFingerprintKey);
  if (done == null &&
      legacy != null &&
      legacy.startsWith('v$altitudeAlgorithmVersion')) {
    done = altitudeAlgorithmVersion;
    await prefs.setInt(_versionKey, done);
  }
  if (done != null && done >= altitudeAlgorithmVersion) return 0;

  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(seconds: 10));
  if (cancelled) return 0;

  final count = await ref
      .read(activitiesRepositoryProvider)
      .readjustAllAltitudes(
        resolver: ref.read(elevationResolverProvider),
        cancelled: () => cancelled,
      );
  if (!cancelled) await prefs.setInt(_versionKey, altitudeAlgorithmVersion);
  return count;
});
