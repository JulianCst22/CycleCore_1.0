/// Navegación: grafo vial offline, ruteo (Contraction Hierarchies y A*),
/// búsqueda, lugares guardados e instrucciones de giro.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/navigation_providers.dart';
export 'domain/climb_detection.dart';
export 'domain/navigation_target.dart';
export 'presentation/end_navigation_confirm.dart';
export 'presentation/navigation_polyline_layer.dart';
export 'presentation/navigation_search_sheet.dart';
export 'presentation/navigation_settings_screen.dart';
export 'presentation/navigation_voice_bridge.dart';
export 'presentation/route_confirm_card.dart';
export 'presentation/saved_places_screen.dart';
export 'presentation/turn_instruction_banner.dart';
