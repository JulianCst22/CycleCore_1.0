import 'dart:convert';

/// Un pedazo de una región con su límite real: un departamento, o
/// Bogotá dentro de "Bogotá y Cundinamarca". Sirve para decir "Estás en
/// Bogotá".
class RegionPart {
  final String code;
  final String name;

  /// Anillos del límite como pares (lat, lng). Con la regla par-impar,
  /// un anillo dentro de otro es un hueco.
  final List<List<(double, double)>> rings;

  const RegionPart({
    required this.code,
    required this.name,
    required this.rings,
  });

  bool contains(double lat, double lng) {
    var crossings = 0;
    for (final ring in rings) {
      for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        final (yi, xi) = ring[i];
        final (yj, xj) = ring[j];
        if ((yi > lat) != (yj > lat) &&
            lng < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
          crossings++;
        }
      }
    }
    return crossings.isOdd;
  }

  static RegionPart fromJson(Map<String, dynamic> json) => RegionPart(
    code: json['codigo'] as String,
    name: json['nombre'] as String,
    rings: [
      for (final ring in json['anillos'] as List)
        [
          for (final p in ring as List)
            (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
        ],
    ],
  );
}

/// Una región descargable del mapa vial: un departamento o varios
/// unidos. Viene del catálogo `regiones.json` que publica el servidor
/// (ver la carpeta "Servidor CycleCore" del escritorio), no está
/// escrita en el código: agregar o actualizar regiones no requiere
/// sacar otra versión de la app.
class RoadRegion {
  final String id;
  final String name;
  final String fileName;

  /// Versión del mapa (fecha del OSM + versión del proceso). Si cambia,
  /// la app ofrece "Actualizar".
  final String version;

  /// Lo que ocupa en el teléfono y lo que se baja (va comprimido).
  final int sizeBytes;
  final int downloadBytes;

  /// Caja que cubren las vías del mapa: el límite más el margen que se
  /// le deja sobre los vecinos. (minLat, minLng, maxLat, maxLng)
  final (double, double, double, double) box;

  final List<RegionPart> parts;

  const RoadRegion({
    required this.id,
    required this.name,
    required this.fileName,
    required this.version,
    required this.sizeBytes,
    required this.downloadBytes,
    required this.box,
    required this.parts,
  });

  /// El mapa tiene vías en ese punto (dentro del límite o del margen).
  bool covers(double lat, double lng) {
    final (minLat, minLng, maxLat, maxLng) = box;
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  /// La parte (departamento) donde cae el punto, si cae en alguna.
  RegionPart? partAt(double lat, double lng) {
    for (final part in parts) {
      if (part.contains(lat, lng)) return part;
    }
    return null;
  }

  static RoadRegion fromJson(Map<String, dynamic> json) {
    final box = (json['caja'] as List).map((v) => (v as num).toDouble());
    final [minLat, minLng, maxLat, maxLng] = box.toList();
    return RoadRegion(
      id: json['id'] as String,
      name: json['nombre'] as String,
      fileName: json['archivo'] as String,
      version: json['version'] as String,
      sizeBytes: json['bytes'] as int,
      downloadBytes: json['bytes_descarga'] as int,
      box: (minLat, minLng, maxLat, maxLng),
      parts: [
        for (final p in json['partes'] as List)
          RegionPart.fromJson((p as Map).cast<String, dynamic>()),
      ],
    );
  }
}

/// El catálogo de regiones que publica el servidor.
class RegionCatalog {
  final String version;
  final DateTime? generatedAt;
  final List<RoadRegion> regions;

  const RegionCatalog({
    required this.version,
    required this.generatedAt,
    required this.regions,
  });

  static const empty = RegionCatalog(
    version: '',
    generatedAt: null,
    regions: [],
  );

  static RegionCatalog parse(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    return RegionCatalog(
      version: json['version'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generado'] as String? ?? ''),
      regions: [
        for (final r in json['regiones'] as List)
          RoadRegion.fromJson((r as Map).cast<String, dynamic>()),
      ],
    );
  }

  RoadRegion? byId(String id) {
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// La región descargada con la que se rutea desde un punto (y hacia
  /// otro, si se da): la que lo cubre, mejor si cubre también el
  /// destino y si el origen cae dentro de su límite real. `null` si
  /// ninguna de las descargadas lo cubre.
  ///
  /// Sin catálogo (nunca se pudo leer del servidor) se usa la primera
  /// descargada: el isolate de ruteo avisa si el punto queda por fuera.
  String? regionForRoute({
    required Iterable<String> downloaded,
    required double fromLat,
    required double fromLng,
    double? toLat,
    double? toLng,
  }) {
    final ids = downloaded.toSet();
    if (regions.isEmpty) return ids.isEmpty ? null : ids.first;
    final candidates = [
      for (final r in regions)
        if (ids.contains(r.id) && r.covers(fromLat, fromLng)) r,
    ];
    if (candidates.isEmpty) return null;
    int score(RoadRegion r) =>
        (toLat != null && toLng != null && r.covers(toLat, toLng) ? 2 : 0) +
        (r.partAt(fromLat, fromLng) != null ? 1 : 0);
    candidates.sort((a, b) => score(b).compareTo(score(a)));
    return candidates.first.id;
  }

  /// Dónde estás: la región cuyo límite real contiene el punto, y la
  /// parte (departamento) exacta. Si el punto no cae dentro de ningún
  /// límite (en una frontera, por la simplificación), la primera región
  /// cuyo mapa lo cubre.
  ({RoadRegion region, RegionPart? part})? locate(double lat, double lng) {
    for (final region in regions) {
      final part = region.partAt(lat, lng);
      if (part != null) return (region: region, part: part);
    }
    for (final region in regions) {
      if (region.covers(lat, lng)) return (region: region, part: null);
    }
    return null;
  }
}
