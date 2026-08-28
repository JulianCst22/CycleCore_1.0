import 'dart:collection';

/// Calcula la pendiente actual con una regresión lineal sobre una
/// ventana de TIEMPO (no de distancia) de los últimos [windowSeconds]
/// segundos.
///
/// Reemplaza a `SlopeWindowCalculator` SOLO en el cockpit en vivo (ver
/// `RouteRecordingController._onNewPosition`). `SlopeWindowCalculator`
/// se deja intacto porque sigue siendo la elección correcta para el
/// aplanado post-actividad (`ActivityAltitudeFlattener`, Fase 1),
/// donde no hay ninguna urgencia de tiempo real y una ventana de
/// distancia fija da un resultado más consistente sobre toda la ruta.
///
/// --- Por qué la ventana de distancia se sentía lenta subiendo ---
///
/// Con los 40m fijos originales: a 8-10 km/h (subida), recorrerlos
/// toma 15-18 segundos; a 40 km/h (bajada), los mismos 40m toman ~3.5
/// segundos. La ventana era la misma en metros, pero el TIEMPO DE
/// RESPUESTA de la pendiente dependía completamente de la velocidad
/// -- lento subiendo, rápido bajando. Confirmado en campo el
/// 2026-08-22 (ruta "San Jorge"): la pendiente se demoraba
/// muchísimo en actualizar en el puerto.
///
/// Este es un problema documentado en toda la industria de
/// ciclocomputadores, no exclusivo de esta app. Garmin reconoció
/// públicamente (reseña del Edge 1050, DC Rainmaker, junio 2024) que
/// sus unidades anteriores podían tardar "10-15 segundos" en mostrar
/// la pendiente correcta en cambios abruptos de grado, y lo
/// resolvieron con "un algoritmo enteramente nuevo" enfocado en
/// velocidad de respuesta (después llevado también a los Edge
/// 540/840/1040 vía actualización de firmware). Un desarrollador de
/// la comunidad Garmin Connect IQ, intentando replicar el
/// comportamiento, describe el mismo dilema: los datos barométricos
/// no se actualizan rápido y cuando cambian lo hacen en escalón, así
/// que hay que balancear entre pendiente ruidosa (por esos saltos) o
/// lenta (por el suavizado necesario para evitarlos) -- y resolvió
/// hacer ese balance "adaptativo" para detectar más rápido una
/// inversión de pendiente o una transición a terreno plano.
///
/// Una ventana por TIEMPO logra ese mismo efecto de forma directa:
/// responde en el mismo número de segundos sin importar la
/// velocidad. Subiendo lento, la ventana cubre menos distancia física
/// (más sensible al cambio real, que es justo lo que se necesitaba).
/// Bajando rápido, cubre más distancia (sigue suavizando bien el
/// ruido del GPS, sin volverse nerviosa).
class LiveSlopeCalculator {
  final double windowSeconds;

  /// Piso de distancia mínima dentro de la ventana para confiar en la
  /// regresión -- evita divisiones por un denominador casi cero
  /// cuando el ciclista está prácticamente detenido (semáforo, jitter
  /// de GPS sin movimiento real). Sin esto, una ventana de tiempo con
  /// el ciclista parado podría "inventar" una pendiente a partir de
  /// puro ruido de posición.
  final double minDistanceMeters;

  final Queue<_TimedSample> _samples = Queue();

  LiveSlopeCalculator({
    this.windowSeconds = 6,
    this.minDistanceMeters = 3,
  });

  /// Agrega una nueva muestra y devuelve la pendiente actual en
  /// porcentaje. [timestamp] es el momento real de la muestra -- se
  /// usa SOLO para decidir qué tan vieja es una muestra respecto a la
  /// más reciente (nunca contra `DateTime.now()`), así que el cálculo
  /// es determinístico y fácil de probar con timestamps fabricados.
  double addSample({
    required double cumulativeDistanceMeters,
    required double altitude,
    required DateTime timestamp,
  }) {
    _samples.addLast(
      _TimedSample(timestamp, cumulativeDistanceMeters, altitude),
    );

    final cutoff = timestamp.subtract(
      Duration(milliseconds: (windowSeconds * 1000).round()),
    );
    while (_samples.isNotEmpty && _samples.first.timestamp.isBefore(cutoff)) {
      _samples.removeFirst();
    }

    if (_samples.length < 3) return 0;

    final span =
        _samples.last.distanceMeters - _samples.first.distanceMeters;
    if (span < minDistanceMeters) return 0;

    final n = _samples.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (final s in _samples) {
      sumX += s.distanceMeters;
      sumY += s.altitude;
      sumXY += s.distanceMeters * s.altitude;
      sumXX += s.distanceMeters * s.distanceMeters;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) return 0;

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    return slope * 100;
  }

  void reset() => _samples.clear();
}

class _TimedSample {
  final DateTime timestamp;
  final double distanceMeters;
  final double altitude;
  const _TimedSample(this.timestamp, this.distanceMeters, this.altitude);
}
