/// Los cuatro tipos de sensor BLE que la app sabe conectar. Cada uno
/// tiene su propia conexión física independiente (puedes llevar los
/// cuatro a la vez), pero el flujo escanear -> conectar -> desconectar y
/// la lógica de reconexión son idénticos: viven una sola vez en
/// `BleSensorController`.
enum SensorKind { heartRate, power, speed, cadence }

extension SensorKindInfo on SensorKind {
  /// Nombre para mostrar en la UI.
  String get label => switch (this) {
    SensorKind.heartRate => 'Frecuencia cardíaca',
    SensorKind.power => 'Potencia',
    SensorKind.speed => 'Velocidad',
    SensorKind.cadence => 'Cadencia',
  };

  /// Unidad del valor en vivo ('ppm', 'W', 'km/h', 'rpm').
  String get unit => switch (this) {
    SensorKind.heartRate => 'ppm',
    SensorKind.power => 'W',
    SensorKind.speed => 'km/h',
    SensorKind.cadence => 'rpm',
  };

  /// Clave de `SharedPreferences` donde se recuerda el último
  /// dispositivo conectado de este tipo.
  String get lastDeviceIdPrefsKey => switch (this) {
    SensorKind.heartRate => 'last_heart_rate_device_id',
    SensorKind.power => 'last_power_device_id',
    SensorKind.speed => 'last_speed_device_id',
    SensorKind.cadence => 'last_cadence_device_id',
  };
}
