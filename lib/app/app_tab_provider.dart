import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestaña activa del `AppShell` (0 Mapa, 1 Segmentos, 2 Actividad,
/// 3 Perfil).
///
/// Es estado de la capa `app`: solo `AppShell` lo lee y lo escribe. Si una
/// pantalla de una feature necesita llevar a otra pestaña, `AppShell` le
/// inyecta un callback (ver `SegmentsListScreen.onBrowseActivities`).
final appTabIndexProvider = StateProvider<int>((ref) => 0);
