/// De dónde puede salir la cadencia: tres aparatos distintos la miden.
///
/// El orden de la enumeración es la prioridad cuando el ciclista no
/// eligió: el medidor de potencia primero (la mide en la biela, junto
/// con los vatios), después el sensor de cadencia dedicado y por último
/// el sensor de velocidad marcado como combo.
enum CadenceSource { power, dedicated, speedCombo }

extension CadenceSourceInfo on CadenceSource {
  String get label => switch (this) {
    CadenceSource.power => 'Medidor de potencia',
    CadenceSource.dedicated => 'Sensor de cadencia',
    CadenceSource.speedCombo => 'Sensor de velocidad (combo)',
  };

  static CadenceSource? byName(String? name) {
    for (final source in CadenceSource.values) {
      if (source.name == name) return source;
    }
    return null;
  }
}

/// La fuente que manda ahora: la elegida si está dando datos; si no, la
/// primera que los dé en orden de prioridad. Así, si el sensor elegido
/// se cae a mitad de la subida, la cadencia sigue llegando del otro.
CadenceSource? resolveCadenceSource({
  required CadenceSource? preferred,
  required Map<CadenceSource, double?> values,
}) {
  if (preferred != null && values[preferred] != null) return preferred;
  for (final source in CadenceSource.values) {
    if (values[source] != null) return source;
  }
  return null;
}
