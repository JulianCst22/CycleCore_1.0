import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frecuencia cardíaca en tiempo real, en latidos por minuto.
///
/// Vive en `core/` (no dentro de un feature específico) porque tanto el
/// feature `sensors` (quien la escribe, al recibir datos BLE reales) como
/// el feature `geospatial` (quien la muestra en el panel del mapa) la
/// necesitan. Ponerla en cualquiera de los dos features generaría un
/// acoplamiento innecesario entre módulos que deberían ser independientes.
///
/// `null` significa "sin sensor conectado" -- la UI ya sabe mostrar `--`
/// en ese caso.
final heartRateBpmProvider = StateProvider<int?>((ref) => null);
