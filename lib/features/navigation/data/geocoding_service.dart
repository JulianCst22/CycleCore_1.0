import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double lat;
  final double lng;

  const GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

/// Búsqueda de lugares por nombre ("Los Patios", "Parque Nacional")
/// usando Nominatim, el geocodificador público de OpenStreetMap. Es
/// independiente de tu grafo de rutas -- solo convierte texto en
/// coordenadas, no necesita ninguna región descargada.
///
/// IMPORTANTE -- política de uso de Nominatim público:
/// - Máximo 1 solicitud por segundo.
/// - Exige un User-Agent que identifique tu app (cambiá el de abajo
///   por el nombre/contacto real antes de publicar).
/// - No pensado para uso masivo en producción -- si CycleCore crece,
///   lo normal es migrar a una instancia propia de Nominatim o a un
///   geocodificador de pago (Mapbox, Google Places, etc.).
/// https://operations.osmfoundation.org/policies/nominatim/
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<GeocodingResult>> search(
    String query, {
    double? nearLat,
    double? nearLng,
  }) async {
    final hasBias = nearLat != null && nearLng != null;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '5',
      if (hasBias)
        'viewbox':
            '${nearLng - 0.5},${nearLat + 0.5},${nearLng + 0.5},${nearLat - 0.5}',
      if (hasBias) 'bounded': '0',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'CycleCoreApp/1.0 (contacto@tudominio.com)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo buscar "$query" (HTTP ${response.statusCode}).',
      );
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return GeocodingResult(
        displayName: map['display_name'] as String,
        lat: double.parse(map['lat'] as String),
        lng: double.parse(map['lon'] as String),
      );
    }).toList();
  }
}
