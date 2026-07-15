/// Talla de llanta común, con su circunferencia estándar en milímetros
/// (valores ETRTO, los mismos que usan Garmin/Wahoo en sus apps).
///
/// El usuario elige de esta lista (o ingresa un valor manual) en el
/// popup que aparece la primera vez que conecta un sensor de velocidad
/// -- el protocolo BLE nunca manda la velocidad ya calculada, solo
/// revoluciones de rueda, así que sin esto no hay forma de sacar km/h.
class WheelSize {
  final String label;
  final double circumferenceMm;

  const WheelSize({required this.label, required this.circumferenceMm});

  static const List<WheelSize> commonSizes = [
    WheelSize(label: '700x18C (ruta, tubular delgado)', circumferenceMm: 2070),
    WheelSize(label: '700x20C', circumferenceMm: 2086),
    WheelSize(label: '700x23C (ruta estándar)', circumferenceMm: 2096),
    WheelSize(label: '700x25C (ruta, la más común hoy)', circumferenceMm: 2105),
    WheelSize(label: '700x28C', circumferenceMm: 2136),
    WheelSize(label: '700x30C', circumferenceMm: 2146),
    WheelSize(label: '700x32C (gravel)', circumferenceMm: 2155),
    WheelSize(label: '700x35C (gravel/ciclocross)', circumferenceMm: 2168),
    WheelSize(label: '700x38C (gravel ancho)', circumferenceMm: 2180),
    WheelSize(label: '650x23C', circumferenceMm: 1907),
    WheelSize(label: '26" x 1.75 (MTB rueda pequeña)', circumferenceMm: 2023),
    WheelSize(label: '26" x 2.10 (MTB)', circumferenceMm: 2068),
    WheelSize(label: '27.5" / 650B (MTB)', circumferenceMm: 2170),
    WheelSize(label: '29" (MTB rueda grande)', circumferenceMm: 2326),
  ];
}
