import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Pide (una sola vez por instalación) que Android no aplique el
  /// ahorro de batería a la app.
  ///
  /// El servicio en primer plano no alcanza en muchos teléfonos: los
  /// fabricantes que "optimizan" la batería matan el proceso con la
  /// pantalla apagada y la grabación se corta a mitad de la salida. El
  /// sistema muestra su propio diálogo («¿Permitir que la app se
  /// ejecute siempre en segundo plano?»). Si el ciclista dice que no, no
  /// se le vuelve a preguntar: se puede activar en Ajustes del sistema.
  Future<bool> ensureUnrestrictedBattery() async {
    const askedKey = 'battery_exemption_asked_v1';
    try {
      if (await ph.Permission.ignoreBatteryOptimizations.isGranted) {
        return true;
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(askedKey) ?? false) return false;
      await prefs.setBool(askedKey, true);
      return (await ph.Permission.ignoreBatteryOptimizations.request())
          .isGranted;
    } catch (_) {
      // Plataforma sin este permiso (iOS, escritorio): nada que pedir.
      return true;
    }
  }

  /// Un fix de GPS ahora. Espera como mucho [timeout]: en modo avión y
  /// bajo techo el teléfono no se puede ubicar con wifi ni antenas, y sin
  /// tope la espera no terminaba nunca (la app se quedaba cargando). Si
  /// se vence, devuelve la última ubicación conocida; si no hay ninguna,
  /// lanza el `TimeoutException`.
  Future<Position> getCurrentPosition({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await ensureLocationReady();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      unawaited(_remember(position));
      return position;
    } on TimeoutException {
      final last = await lastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  static const _lastPositionKey = 'last_position_v1';

  /// Dónde estuvo el teléfono por última vez, al instante y sin esperar
  /// al GPS: la que recuerda el sistema y, si no tiene, la última que vio
  /// la app. `null` si nunca hubo ninguna. Sirve para abrir el mapa ya,
  /// aunque no haya señal.
  Future<Position?> lastKnownPosition() async {
    try {
      final system = await Geolocator.getLastKnownPosition();
      if (system != null) return system;
    } catch (_) {
      // Sin permiso todavía: se sigue con la guardada.
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_lastPositionKey)?.split(',');
      if (saved == null || saved.length < 4) return null;
      return Position(
        latitude: double.parse(saved[0]),
        longitude: double.parse(saved[1]),
        altitude: double.parse(saved[2]),
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(saved[3])),
        accuracy: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _remember(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastPositionKey,
        '${position.latitude},${position.longitude},${position.altitude},'
        '${position.timestamp.millisecondsSinceEpoch}',
      );
    } catch (_) {}
  }

  /// Espera hasta que llegue un fix con precisión razonable, o hasta que
  /// venza [timeout] -- lo que ocurra primero. Pensado para llamarse
  /// justo antes de arrancar una grabación.
  ///
  /// Complementa (no reemplaza) el buffer de calentamiento de
  /// SlopePlausibilityFilter: esto reduce la probabilidad de arrancar
  /// con un fix malo en el origen, pero no depende de conseguirlo
  /// siempre -- si el timeout vence con el GPS todavía inestable, la
  /// grabación arranca igual y el buffer de calentamiento actúa como
  /// red de seguridad.
  ///
  /// Agregado tras confirmar en campo (Alto del Águila, 2026-07-16) que
  /// el primer fix de un cold start puede llegar hasta ~19m desviado en
  /// altitud.
  Future<void> waitForStableFix({
    Duration timeout = const Duration(seconds: 8),
    double desiredAccuracyMeters = 20,
  }) async {
    final completer = Completer<void>();
    StreamSubscription<Position>? sub;

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
          ),
        ).listen(
          (position) {
            if (!completer.isCompleted &&
                position.accuracy <= desiredAccuracyMeters) {
              completer.complete();
            }
          },
          onError: (_) {
            // Si el stream falla acá, no bloqueamos el arranque de la
            // grabación por esto -- se deja que watchPosition() en
            // _subscribeToSensors() reporte el error real si persiste.
            if (!completer.isCompleted) completer.complete();
          },
        );

    await completer.future;
    timer.cancel();
    await sub.cancel();
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
