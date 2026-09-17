/// Sensores BLE: frecuencia cardíaca, potencia, velocidad y cadencia.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/cadence_providers.dart';
export 'application/heart_rate_provider.dart';
export 'application/power_providers.dart';
export 'application/speed_providers.dart';
export 'presentation/sensors_screen.dart';
