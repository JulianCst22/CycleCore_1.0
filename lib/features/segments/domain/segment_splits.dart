import 'dart:convert';

import 'segment_detector.dart';

/// Serializa la curva tiempo-vs-distancia de un esfuerzo a lo que se
/// guarda en `SegmentEfforts.splitsJson`.
String encodeSplits(List<SplitPoint> splits) =>
    jsonEncode(splits.map((s) => s.toJson()).toList());

/// Reconstruye la curva desde `SegmentEfforts.splitsJson`. Devuelve
/// lista vacía si el JSON está vacío o corrupto (esfuerzos grabados
/// antes de la Fase C).
List<SplitPoint> decodeSplits(String json) {
  if (json.isEmpty || json == '[]') return const [];
  try {
    final decoded = jsonDecode(json) as List<dynamic>;
    return decoded
        .map((e) => SplitPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Tiempo (segundos desde el inicio del segmento) que la mejor marca
/// tardó en llegar a [distanceMeters] -- el "fantasma". Interpola
/// linealmente entre los dos splits que envuelven esa distancia.
/// `null` si no hay curva de splits (mejor marca vieja o inexistente).
double? ghostSecondsAtDistance(List<SplitPoint> splits, double distanceMeters) {
  if (splits.length < 2) return null;
  if (distanceMeters <= splits.first.distanceMeters) {
    return splits.first.secondsFromStart.toDouble();
  }
  if (distanceMeters >= splits.last.distanceMeters) {
    return splits.last.secondsFromStart.toDouble();
  }
  for (int i = 0; i < splits.length - 1; i++) {
    final a = splits[i];
    final b = splits[i + 1];
    if (distanceMeters >= a.distanceMeters &&
        distanceMeters <= b.distanceMeters) {
      final span = b.distanceMeters - a.distanceMeters;
      final t = span <= 0
          ? 0.0
          : (distanceMeters - a.distanceMeters) / span;
      return a.secondsFromStart +
          (b.secondsFromStart - a.secondsFromStart) * t;
    }
  }
  return splits.last.secondsFromStart.toDouble();
}
