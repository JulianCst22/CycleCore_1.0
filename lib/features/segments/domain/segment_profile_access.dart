import 'package:core_database/core_database.dart';

import 'package:core_geo/core_geo.dart';

/// Acceso perezoso al perfil parseado de un segmento persistido --
/// mismo patrón que ya usa el proyecto en `activity_json_helpers.dart`
/// para `Activity.routePoints`. Evita decodificar el JSON a mano en
/// cada pantalla que necesite el perfil.
extension SegmentProfileAccess on Segment {
  SegmentProfile get profile => SegmentProfile.decode(profileJson);
}
