import 'package:flutter/material.dart';

/// Paleta de colores centralizada de CycleCore.
///
/// Para cambiar la identidad visual de toda la app, modifica los valores
/// aquí -- no hay colores hardcodeados sueltos en otros archivos de UI.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------
  // Color de marca principal. Se usa como semilla del ColorScheme de
  // Material 3 (botones, acentos por defecto, AppBar si se usa, etc).
  // ---------------------------------------------------------------
  static const Color primary = Color(0xFFFF6B35); // Naranja energía

  // ---------------------------------------------------------------
  // Panel de datos tipo "cockpit" que se superpone al mapa.
  // Oscuro a propósito: mejor legibilidad bajo sol directo, que es
  // la condición real de uso (ciclismo de ruta al aire libre).
  // ---------------------------------------------------------------
  static const Color panelBackground = Color(0xFF1A1D29);

  // ---------------------------------------------------------------
  // Un color de acento distinto por tipo de métrica, para que el
  // ciclista identifique cada dato de un vistazo, sin leer la etiqueta.
  // ---------------------------------------------------------------
  static const Color accentTime = Color(0xFF64B5F6); // Azul
  static const Color accentDistance = Color(0xFFFFB74D); // Ámbar
  static const Color accentSpeed = Color(0xFF4FC3F7); // Celeste
  static const Color accentHeartRate = Color(0xFFEF5350); // Rojo
  static const Color accentElevation = Color(0xFF81C784); // Verde
  static const Color accentSlope = Color(0xFFFFA726); // Naranja
  static const Color accentPower = Color(0xFFAB47BC); // Violeta
  static const Color accentCadence = Color(0xFF26A69A); // Verde azulado

  static const Color textPrimaryOnPanel = Color(0xFFFFFFFF);
  static const Color textSecondaryOnPanel = Color(0xFF9CA3AF);

  static const Color recordButtonActive = Color(0xFFE53935); // Grabando
  static const Color recordButtonInactive = Color(0xFF43A047); // Detenido

// Training
  static const Color accentTraining = Color(0xFF00BFFF);

  // ---------------------------------------------------------------
  // Segmentos. Antes el verde de "A" estaba hardcodeado como
  // Color(0xFF2ECC71) en segment_creation_screen.dart y
  // segment_detail_screen.dart -- ahora vive acá.
  // ---------------------------------------------------------------

  /// Marcador/hito de INICIO de un segmento (punto A).
  static const Color segmentStart = Color(0xFF2ECC71); // Verde

  /// Marcador/hito de FIN de un segmento (punto B) -- reusa el rojo de
  /// "grabando", con nombre propio para que quede claro en el sitio de
  /// uso que representa "meta del segmento", no "grabación activa".
  static const Color segmentEnd = recordButtonActive;

  /// Polilínea del segmento que se está recorriendo AHORA, dibujada
  /// sobre el mapa ("vas aquí").
  static const Color segmentActiveTrack = Color(0xFF00E0C6); // Turquesa

  /// Polilínea de los demás segmentos cercanos (vigilados pero no
  /// activos) -- atenuada para no competir con el trazado grabado.
  static const Color segmentIdleTrack = Color(0xFF5C6B7A);

  /// Vas MÁS RÁPIDO que tu mejor marca / el fantasma.
  static const Color ghostAhead = Color(0xFF2ECC71);

  /// Vas MÁS LENTO que tu mejor marca / el fantasma.
  static const Color ghostBehind = Color(0xFFE0663D);
}
