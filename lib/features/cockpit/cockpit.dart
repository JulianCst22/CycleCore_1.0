/// Cockpit de datos en vivo: campos configurables, grilla, barra lateral y
/// panel deslizable.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/cockpit_layout_providers.dart';
export 'data/cockpit_layout_repository.dart';
export 'domain/cockpit_field.dart';
export 'domain/cockpit_tile_config.dart';
export 'domain/cockpit_tile_packing.dart';
export 'presentation/cockpit_field_ui.dart';
export 'presentation/cockpit_fullscreen_view.dart';
export 'presentation/cockpit_sliding_panel.dart';
export 'presentation/gps_status_widgets.dart';
export 'presentation/lateral_data_bar.dart';
