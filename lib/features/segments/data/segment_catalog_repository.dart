import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cyclecore_core/config/app_config.dart';
import '../domain/segment_catalog_entry.dart';
import '../domain/segment_source.dart';
import 'gpx_segment_importer.dart';
import 'segments_repository.dart';

/// Catálogo remoto de segmentos "nativos" de la app. Mismo patrón que
/// `RoadRegionRepository` / la descarga de teselas de elevación: el
/// celular solo habla con TU bucket (`AppConfig.segmentCatalogBaseUrl`),
/// baja un `catalog.json` con la lista y un `.gpx` por segmento.
///
/// A diferencia de las teselas/grafos, acá NO hay una tabla de
/// "descargados" aparte: al descargar, el GPX se parsea y el segmento
/// se inserta como una fila más en `Segments` (con `source =
/// nativeCatalog` y `remoteId` puesto). Eso alcanza para no
/// re-importarlo dos veces y para que aparezca en la lista junto a los
/// demás.
class SegmentCatalogRepository {
  final SegmentsRepository segmentsRepository;
  final GpxSegmentImporter importer;

  SegmentCatalogRepository(
    this.segmentsRepository, {
    this.importer = const GpxSegmentImporter(),
  });

  Future<List<SegmentCatalogEntry>> fetchCatalog() async {
    final uri = Uri.parse('${AppConfig.segmentCatalogBaseUrl}/catalog.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el catálogo de segmentos '
        '(HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    final list = decoded is Map<String, dynamic>
        ? decoded['segments'] as List<dynamic>
        : decoded as List<dynamic>;

    return list
        .map((e) => SegmentCatalogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// true si este segmento del catálogo ya fue descargado (existe una
  /// fila en `Segments` con este `remoteId`).
  Future<bool> isDownloaded(String remoteId) async {
    return await segmentsRepository.database.getSegmentByRemoteId(remoteId) !=
        null;
  }

  /// Descarga el GPX del segmento, lo parsea y lo guarda. Si ya estaba
  /// descargado, no hace nada y devuelve el id existente.
  Future<int> downloadAndImport(SegmentCatalogEntry entry) async {
    final existing = await segmentsRepository.database.getSegmentByRemoteId(
      entry.id,
    );
    if (existing != null) return existing.id;

    final uri = Uri.parse(
      '${AppConfig.segmentCatalogBaseUrl}/${entry.gpxFileName}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo descargar "${entry.name}" (HTTP ${response.statusCode}).',
      );
    }

    final result = importer.parse(utf8.decode(response.bodyBytes));

    return segmentsRepository.createSegmentFromGpx(
      name: entry.name,
      profilePoints: result.profilePoints,
      stats: result.stats,
      startBearingDegrees: result.startBearingDegrees,
      source: SegmentSource.nativeCatalog,
      remoteId: entry.id,
    );
  }
}
