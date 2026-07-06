import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Única puerta de entrada a la ubicación del dispositivo.
///
/// Ningún otro archivo de la app debería importar `geolocator` directamente.
/// Si mañana cambiamos de paquete de geolocalización, solo se toca este
/// archivo.
class LocationService {
  /// Verifica que el servicio de ubicación esté encendido y que la app
  /// tenga permiso de primer plano concedido. Lanza una excepción con
  /// un mensaje claro si algo falta, para que la UI pueda mostrarlo.
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

  /// Solicita el permiso de ubicación EN SEGUNDO PLANO y el de
  /// notificaciones, necesarios para que la grabación siga funcionando
  /// con la pantalla bloqueada.
  ///
  /// Debe llamarse DESPUÉS de [ensureLocationReady] -- Android exige
  /// que el permiso de primer plano ya esté concedido antes de poder
  /// pedir el de segundo plano; pedirlos juntos falla silenciosamente
  /// desde Android 11.
  ///
  /// No lanza excepción si el usuario lo niega: la grabación puede
  /// seguir funcionando en primer plano solamente, solo que se
  /// detendrá si se bloquea la pantalla. Se devuelve `true`/`false`
  /// para que la UI decida si advertir al usuario.
  Future<bool> ensureBackgroundLocationReady() async {
    final backgroundStatus = await ph.Permission.locationAlways.request();
    final notificationStatus = await ph.Permission.notification.request();

    return backgroundStatus.isGranted && notificationStatus.isGranted;
  }

  Future<Position> getCurrentPosition() async {
    await ensureLocationReady();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Stream continuo de posiciones, usado mientras se está grabando una
  /// ruta.
  ///
  /// Se configura como Foreground Service (con notificación persistente
  /// "CycleCore está grabando tu ruta") para que Android no suspenda las
  /// actualizaciones de ubicación cuando el usuario bloquea la pantalla
  /// o cambia de app -- esto es exactamente lo que resuelve el bug de
  /// "se detiene al bloquear el teléfono".
  ///
  /// `distanceFilter: 5` evita saturar el flujo con ruido del GPS
  /// cuando el ciclista está momentáneamente detenido.
  Stream<Position> watchPosition() {
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'CycleCore está grabando tu ruta',
        notificationText: 'Toca para volver a la app',
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: androidSettings);
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
