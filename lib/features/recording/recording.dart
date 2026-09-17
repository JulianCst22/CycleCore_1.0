/// Grabación de salidas: motor en vivo (GPS + barómetro + lógica difusa),
/// diario de recuperación y pausa automática.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/auto_pause_providers.dart';
export 'application/ride_sensor_log.dart';
export 'application/route_recording_providers.dart';
export 'domain/activity_altitude_flattener.dart';
export 'domain/recording_snapshot.dart';
export 'domain/route_point.dart';
export 'presentation/recording_recovery_dialog.dart';
