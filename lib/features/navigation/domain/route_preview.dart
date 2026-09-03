import 'navigation_route.dart';
import 'navigation_target.dart';

/// Una ruta ya calculada pero **todavía no activa** -- lo que se
/// muestra en la tarjeta "Confirmar la ruta" antes de que el usuario
/// toque "Empezar". Lleva, además de la ruta y el destino, el perfil de
/// altimetría estimado del camino (muestreado contra las teselas HGT) y
/// si el destino parece un alto.
class RoutePreview {
  final NavigationTarget target;
  final NavigationRoute route;

  /// Altitud (msnm) muestreada a lo largo de la ruta. `null` en los
  /// tramos sin tesela de elevación descargada.
  final List<double?> elevationSamples;

  /// Desnivel positivo acumulado del muestreo. `null` si no hubo
  /// suficientes muestras válidas para estimarlo.
  final double? elevationGainMeters;

  /// Altitud del destino, si se pudo resolver.
  final double? destinationAltitudeMeters;

  final bool isClimb;

  const RoutePreview({
    required this.target,
    required this.route,
    required this.elevationSamples,
    required this.elevationGainMeters,
    required this.destinationAltitudeMeters,
    required this.isClimb,
  });

  double get distanceMeters => route.totalDistanceMeters;

  /// Estimación gruesa de duración en bici: ~18 km/h en llano más el
  /// tiempo de trepar el desnivel a una VAM de ~550 m/h. No pretende ser
  /// exacta -- es una referencia para decidir si vale la pena el plan.
  Duration get estimatedRideTime {
    final flatHours = (distanceMeters / 1000) / 18.0;
    final climbHours = (elevationGainMeters ?? 0) / 550.0;
    return Duration(seconds: ((flatHours + climbHours) * 3600).round());
  }
}
