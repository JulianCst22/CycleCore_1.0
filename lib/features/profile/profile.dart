/// Perfil del ciclista: identidad, datos deportivos, zonas de entrenamiento,
/// onboarding y la pestaña Perfil.
///
/// API pública de la feature: lo único que otros módulos pueden
/// importar. Todo lo que no se exporta acá es detalle interno.
library;

export 'application/extension_points.dart';
export 'application/profile_providers.dart';
export 'application/zones_providers.dart';
export 'domain/cyclist_profile.dart';
export 'domain/training_zones.dart';
export 'presentation/onboarding_screen.dart';
export 'presentation/profile_edit_screen.dart';
export 'presentation/profile_screen.dart';
export 'presentation/training_zones_screen.dart';
export 'presentation/widgets/birth_date_field.dart';
export 'presentation/widgets/zones_editor.dart';
