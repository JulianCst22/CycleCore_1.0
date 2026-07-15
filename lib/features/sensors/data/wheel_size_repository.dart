import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la circunferencia de rueda que el usuario configuró al
/// conectar su sensor de velocidad. Vive separada del perfil del
/// ciclista a propósito: es un dato del EQUIPO (puede cambiar si cambia
/// de llantas), no del ciclista.
class WheelSizeRepository {
  static const _key = 'wheel_circumference_mm';

  Future<double?> loadCircumferenceMm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key);
  }

  Future<void> saveCircumferenceMm(double mm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, mm);
  }
}
