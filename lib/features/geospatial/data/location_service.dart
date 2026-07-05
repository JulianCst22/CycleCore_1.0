import 'package:geolocator/geolocator.dart';

/// Única puerta de entrada a la ubicación del dispositivo.
///
/// Ningún otro archivo de la app debería importar `geolocator` directamente.
/// Si mañana cambiamos de paquete de geolocalización, solo se toca este
/// archivo.
class LocationService {
  /// Verifica que el servicio de ubicación esté encendido y que la app
  /// tenga permiso concedido. Lanza una excepción con un mensaje claro
  /// si algo falta, para que la UI pueda mostrarlo al usuario.
  Future<void> ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }
  }

  /// Obtiene la posición actual una sola vez (útil para centrar el mapa
  /// al abrir la pantalla, antes de empezar a grabar).
  Future<Position> getCurrentPosition() async {
    await ensureLocationReady();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Stream continuo de posiciones, usado mientras se está grabando
  /// una ruta o durante una sesión de entrenamiento en vivo.
  ///
  /// `distanceFilter: 5` significa que solo se emite un nuevo punto si
  /// el usuario se movió al menos 5 metros desde el último punto reportado
  /// -- esto evita saturar el flujo con ruido del GPS cuando el ciclista
  /// está momentáneamente detenido (ej. en un semáforo).
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
  @override
  String toString() =>
      'El GPS del dispositivo está desactivado. Actívalo para continuar.';
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
  @override
  String toString() =>
      'Se necesita permiso de ubicación para grabar rutas y segmentos.';
}

class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();
  @override
  String toString() =>
      'El permiso de ubicación fue denegado permanentemente. '
      'Actívalo manualmente desde Ajustes > Apps > CycleCore > Permisos.';
}
