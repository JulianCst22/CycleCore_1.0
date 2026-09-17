/// Fuentes de altitud: teselas SRTM (HGT) descargadas, perfiles GPX y la cadena
/// de prioridades.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/elevation_providers.dart';
export 'data/elevation_resolver.dart';
export 'domain/elevation_lookup.dart';
export 'presentation/elevation_download_dialog.dart';
export 'presentation/elevation_settings_screen.dart';
