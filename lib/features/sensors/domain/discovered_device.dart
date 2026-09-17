/// Un dispositivo BLE encontrado durante el escaneo, ya filtrado para
/// que sea (probablemente) un sensor del tipo buscado -- el filtrado
/// real ocurre en el `Ble*Service`; este modelo sólo transporta el
/// resultado a la UI.
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
