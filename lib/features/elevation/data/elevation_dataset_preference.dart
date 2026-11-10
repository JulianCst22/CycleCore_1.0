import 'package:shared_preferences/shared_preferences.dart';

import '../domain/elevation_dataset.dart';

/// El modelo de elevación que eligió el ciclista. Se lee siempre de las
/// preferencias (y no de un estado en memoria) porque se consulta justo
/// al empezar a grabar: si la app acaba de abrir, un estado que todavía
/// no terminó de cargar daría el modelo estándar en vez del elegido.
class ElevationDatasetPreference {
  static const _key = 'elevation_dataset_v1';

  const ElevationDatasetPreference._();

  static Future<ElevationDataset> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ElevationDataset.byId(prefs.getString(_key)) ??
        ElevationDataset.standard;
  }

  static Future<void> save(ElevationDataset dataset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dataset.id);
  }
}
