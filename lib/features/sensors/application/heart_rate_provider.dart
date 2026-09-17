import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frecuencia cardíaca en tiempo real, en latidos por minuto.
///
/// La escribe el sensor de frecuencia cardíaca BLE y la leen, a través
/// de la API pública de `sensors`, la grabación, el cockpit y los
/// segmentos -- igual que potencia, cadencia y velocidad.
///
/// `null` significa "sin sensor conectado" -- la UI ya sabe mostrar `--`
/// en ese caso.
final heartRateBpmProvider = StateProvider<int?>((ref) => null);
