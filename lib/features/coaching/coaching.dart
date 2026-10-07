/// API pública de la feature coaching: el coach difuso tipo-2 que
/// recomienda potencia y cadencia dentro de un segmento.
///
/// Es deliberadamente corta. La app solo necesita cuatro cosas —tener
/// el coach vivo durante la salida, pintar su banner, abrir sus ajustes
/// y saber qué variable acaba de nombrar—; todo lo demás (los motores,
/// las reglas, la calibración, el banco de frases, la reproducción de
/// salidas) es detalle interno y se queda adentro. Las herramientas de
/// `tool/` sí entran al dominio directamente, porque generan los
/// resultados de la tesis y no son parte de la app.
library;

export 'application/coaching_controller.dart'
    show
        CoachingLiveState,
        coachMentionedValuesProvider,
        coachingControllerProvider;

/// El resumen de CP/W′ que el perfil muestra: lo calcula el coach, pero
/// lo pinta la gamificación a través de su punto de extensión.
export 'application/coaching_providers.dart'
    show criticalPowerSummaryOfAthleteProvider;

/// Las variables que el coach puede nombrar en voz alta. El cockpit
/// resalta el recuadro de la que sonó (ver `lib/app/coach_highlight.dart`).
export 'domain/message/message_values.dart' show MessageValue;

export 'presentation/coach_setup_sheet.dart' show confirmCoachSetup;
export 'presentation/coaching_settings_screen.dart' show CoachingSettingsScreen;
export 'presentation/widgets/coaching_banner.dart' show CoachingBanner;
export 'presentation/widgets/coaching_strip.dart' show CoachingStrip;
