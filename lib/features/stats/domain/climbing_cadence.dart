import 'dart:math' as math;

import '../../../core/database/database.dart';
import '../../../core/geo/geo.dart';

/// Cadencia habitual del ciclista **subiendo**, en rpm.
///
/// Es la referencia contra la que el coach mide el torque: si se compara
/// contra 85 rpm para todo el mundo, a quien sube natural a 70 le va a
/// leer «pesado» toda la vida y a quien pedalea a 95, «ligero». Y de esa
/// lectura salen el estado del Motor A y el consejo de subir o bajar un
/// piñón.
///
/// Se mide solo en subida y solo pedaleando: en llano y en bajada la
/// cadencia dice otra cosa (o no dice nada, porque se va en punto
/// muerto), y promediar toda la salida la infla.
///
/// Se usa la **mediana** y no el promedio: un par de arranques a 110 rpm
/// o un semáforo a 40 no tienen por qué mover la referencia.

/// Con la que se arranca mientras no haya salidas de las que aprender.
///
/// Ochenta y cinco es la referencia de la literatura para subir sin
/// ir atascado; los profesionales bajan a ~70 en pendientes largas
/// (Lucía, Hoyos y Chicharro, 2001). Es un punto de partida, no un
/// objetivo: apenas hay salidas, manda lo que el ciclista de verdad
/// hace.
const recommendedCadenceRpm = 85;

/// Pendiente desde la que se considera que va subiendo.
const climbingCadenceMinSlope = 3.0;

/// Cadencia por debajo de la cual se entiende que no está pedaleando.
const climbingCadenceMinRpm = 30.0;

/// Segundos mínimos de subida pedaleando para que la medida signifique
/// algo. Menos de tres minutos es una anécdota, no una costumbre.
const climbingCadenceMinSeconds = 180;

/// Mediana de la cadencia en los tramos de subida de un trazado, o
/// `null` si la salida no trae suficiente subida con cadencia.
double? climbingCadenceOf(List<RoutePointSnapshot> points) {
  if (points.length < 2) return null;
  final samples = <double>[];

  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1], current = points[i];
    final cadence = current.cadenceRpm;
    if (cadence == null || cadence < climbingCadenceMinRpm) continue;

    final seconds = current.secondsFromStart - previous.secondsFromStart;
    // Un salto largo entre puntos es una pausa: lo que pasó en medio no
    // se sabe, así que no se cuenta.
    if (seconds <= 0 || seconds > 10) continue;

    final meters = haversineMeters(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    if (meters < 1) continue;
    final slope = 100 * (current.altitude - previous.altitude) / meters;
    if (slope < climbingCadenceMinSlope) continue;

    // Cada muestra vale lo que duró, para que un punto cada cinco
    // segundos no pese lo mismo que uno cada segundo.
    for (var s = 0; s < seconds; s++) {
      samples.add(cadence);
    }
  }

  if (samples.length < climbingCadenceMinSeconds) return null;
  samples.sort();
  final middle = samples.length ~/ 2;
  return samples.length.isOdd
      ? samples[middle]
      : (samples[middle - 1] + samples[middle]) / 2;
}

/// Referencia que se le pasa al coach a partir de lo medido en varias
/// salidas: la mediana de las medianas, que aguanta que una salida haya
/// sido rara.
///
/// `null` si todavía no hay suficientes salidas con subida: hacen falta
/// al menos [minRides] para no cambiarle la referencia a alguien por una
/// sola mañana.
double? learnedClimbingCadence(Iterable<double> perRide, {int minRides = 3}) {
  final values = perRide.toList()..sort();
  if (values.length < minRides) return null;
  final middle = values.length ~/ 2;
  final median = values.length.isOdd
      ? values[middle]
      : (values[middle - 1] + values[middle]) / 2;
  // Fuera de lo humano no se acepta: antes de creerle a un dato raro,
  // mejor quedarse con la recomendada.
  return median.clamp(50.0, 110.0).toDouble();
}

/// Redondeo a rpm enteros para mostrarla y guardarla.
int roundCadence(double rpm) => math.max(1, rpm.round());
