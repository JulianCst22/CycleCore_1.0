/// Configuración de infraestructura que cambia según el entorno. Se
/// centraliza aquí para no tener URLs sueltas por el código.
class AppConfig {
  AppConfig._();

  /// Base donde viven las teselas de elevación (.hgt) que TÚ subiste a tu
  /// cloud (bucket S3, R2, Backblaze, etc.) -- el celular NUNCA llama a
  /// NASA directamente, ni conoce que NASA existe. Solo habla con esta URL.
  ///
  /// TODO: reemplazar por la URL real de tu bucket cuando subas las
  /// teselas manualmente. Ej: 'https://tu-bucket.s3.amazonaws.com/elevation-tiles'
  static const String elevationTilesBaseUrl = 'http://localhost:8000';
}
