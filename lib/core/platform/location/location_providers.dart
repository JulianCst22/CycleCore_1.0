import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// Instancia única del servicio de ubicación, compartida por toda la app.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Posición actual del dispositivo, obtenida una sola vez.
/// Se usa para centrar el mapa la primera vez que se abre la pantalla y
/// por cualquier pantalla que necesite "dónde estoy ahora" sin
/// suscribirse al stream de posición en vivo de la grabación.
final currentPositionProvider = FutureProvider<Position>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getCurrentPosition();
});

/// Última ubicación conocida, al instante: con ella se abre el mapa sin
/// esperar al GPS (en modo avión el primer fix puede tardar mucho, o no
/// llegar bajo techo). `null` si el teléfono nunca se ha ubicado.
final lastKnownPositionProvider = FutureProvider<Position?>((ref) {
  return ref.read(locationServiceProvider).lastKnownPosition();
});
