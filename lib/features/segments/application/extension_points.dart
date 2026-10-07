import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Punto de extensión de `segments` para features ajenas (hoy,
/// `coaching`): vacío por defecto, se completa una sola vez desde la
/// raíz de composición de la app (ver `main.dart`), que sí conoce todas
/// las features. `segments` nunca importa esas features directamente
/// —y no podría: el coach sí importa segmentos, así que el camino de
/// vuelta sería un ciclo.

/// Aviso que `SegmentLiveScreen` muestra encima de su cuadrícula.
///
/// Es el banner del coach. Mientras el ciclista sube, el panel de
/// segmento está expandido y tapa el banner del mapa: sin esto, la voz
/// habla pero en pantalla no queda nada que leer, que es justo cuando
/// más falta hace.
final segmentLiveNoticeProvider = Provider<Widget?>((ref) => null);
