import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../elevation/elevation.dart';
import 'activities_providers.dart';

/// Versión de la forma de medir la altimetría de una actividad. Subirla
/// hace que el historial entero se vuelva a medir.
///
/// 2: desnivel sobre la distancia (remuestreo, promedio de 200 m,
///    umbral de 10 m), GPX anclado al modelo y barómetro (nov. 2026).
/// 3: solo Copernicus y capa 3 difusa (barómetro, Copernicus, GPX y
///    altitud en vivo pesados tramo por tramo) (nov. 2026).
/// 4: umbral del desnivel por tramo según el terreno (5 m en llano, 10 m
///    en quebrado) y el último tramo de la salida cuenta aunque sea
///    menor que el umbral (nov. 2026).
const int altitudeAlgorithmVersion = 4;

const _fingerprintKey = 'altitude_history_fingerprint_v2';

/// Vuelve a medir la altimetría de todas las actividades guardadas cuando
/// cambia la forma de medir ([altitudeAlgorithmVersion]) o las teselas de
/// Copernicus descargadas: una salida medida sin teselas de su zona se
/// corrige sola en cuanto se bajan. Con lo mismo no se repite: se guarda
/// una huella. Sin ninguna tesela no hace nada, para no medir el
/// historial sin modelo justo antes de que se descarguen.
///
/// Espera unos segundos antes de empezar, para no competir con el
/// arranque de la app y para que una descarga de varias teselas cuente
/// como un solo cambio; si en ese rato algo cambia de nuevo, esta pasada
/// se cancela y la siguiente la reemplaza.
final altitudeHistorySyncProvider = FutureProvider<int>((ref) async {
  final tiles = ref.watch(downloadedElevationTilesProvider).valueOrNull;
  if (tiles == null || tiles.isEmpty) return 0;
  final names = [for (final t in tiles) t.tileName]..sort();
  final fingerprint = ['v$altitudeAlgorithmVersion', ...names].join('|');

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_fingerprintKey) == fingerprint) return 0;

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
  if (!cancelled) await prefs.setString(_fingerprintKey, fingerprint);
  return count;
});
