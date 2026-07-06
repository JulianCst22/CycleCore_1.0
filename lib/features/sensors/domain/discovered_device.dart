/// Representa un dispositivo BLE encontrado durante el escaneo, ya
/// filtrado para que sea (probablemente) un sensor de frecuencia
/// cardíaca -- el filtrado real ocurre en BleHeartRateService, este
/// modelo solo transporta el resultado.
class DiscoveredDevice {
  final String id;
  final String name;

  /// Fuerza de la señal en dBm. Más cercano a 0 = más cerca/mejor señal.
  /// Se muestra en la UI para ayudar al usuario a distinguir "su" banda
  /// de otra banda cercana con nombre genérico similar.
  final int rssi;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
}
