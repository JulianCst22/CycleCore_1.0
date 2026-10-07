import 'dart:convert';

import 'app_database.dart';
import 'activity_summary.dart';

/// `routePointsJson` y `photoPathsJson` se guardan como texto plano en la
/// base de datos (Drift no tiene un tipo de columna "lista" nativo para
/// SQLite), así que centralizamos aquí la decodificación para no
/// repetirla en cada pantalla.
extension ActivityJsonFields on Activity {
  List<RoutePointSnapshot> get routePoints {
    final decoded = jsonDecode(routePointsJson) as List;
    return decoded
        .map((e) => RoutePointSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<String> get photoPaths {
    final decoded = jsonDecode(photoPathsJson) as List;
    return decoded.cast<String>();
  }
}
