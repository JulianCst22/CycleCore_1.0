# Módulo de Voz — CycleCore

## 1. Dónde va cada archivo

Copia la carpeta `lib/features/voice/` completa dentro de tu proyecto,
en `cyclecore_app/lib/features/voice/` (reemplaza la carpeta vacía que
ya tienes ahí). Estructura:

```
lib/features/voice/
  domain/
    voice_event.dart        -> los 4 eventos (start/pause/resume/finish)
    voice_persona.dart       -> las 8 personalidades + su configuración
    voice_line_bank.dart     -> las frases (varias por evento y persona)
  data/
    voice_settings_repository.dart  -> guarda la voz elegida (shared_preferences)
    voice_engine.dart        -> motor: habla por TTS o reproduce audio pre-grabado
  presentation/
    voice_providers.dart     -> providers de Riverpod (el `speak()` que vas a llamar)
    voice_selection_screen.dart  -> pantalla para elegir y probar voces
```

## 2. Dependencia nueva

Ya tienes `flutter_tts` y `shared_preferences`. Falta agregar
`audioplayers` (solo se usa si más adelante metes audios
pre-grabados; si nunca los usas, el motor simplemente no la necesita
pero el import ya está puesto, así que sí hay que agregarla).

En tu `pubspec.yaml`, dentro de `dependencies:`:

```yaml
  audioplayers: ^6.0.0
```

Luego corre `flutter pub get`.

Si en el futuro agregas audios pre-grabados, también necesitas
declarar la carpeta de assets en el mismo `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/voice_packs/
```

(Por ahora puedes omitir esto si no vas a usar audios pre-grabados
todavía — el motor funciona 100% con TTS sin esa carpeta.)

## 3. Conectar los 4 eventos a tu grabación de actividad

No tengo el contenido de tu pantalla de grabación (`map_screen.dart` /
lo que maneje iniciar-pausar-reanudar-detener en `geospatial/`), así
que te dejo exactamente qué agregar y tú lo pegas en los lugares
correctos de tu código:

**Import necesario** (arriba del archivo donde esté la lógica de
grabación):

```dart
import 'package:cyclecore_app/features/voice/domain/voice_event.dart';
import 'package:cyclecore_app/features/voice/presentation/voice_providers.dart';
```

**En el método/callback que inicia la grabación:**

```dart
ref.read(voiceSettingsProvider.notifier).speak(VoiceEventType.activityStarted);
```

**En el que pausa:**

```dart
ref.read(voiceSettingsProvider.notifier).speak(VoiceEventType.activityPaused);
```

**En el que reanuda:**

```dart
ref.read(voiceSettingsProvider.notifier).speak(VoiceEventType.activityResumed);
```

**En el que termina/detiene la actividad** (antes de navegar a
`SaveActivityScreen` probablemente):

```dart
ref.read(voiceSettingsProvider.notifier).speak(VoiceEventType.activityFinished);
```

Si esa lógica vive en un `ConsumerStatefulWidget` o `ConsumerWidget`,
ya tienes `ref` disponible. Si vive en un `StateNotifier`/repositorio
que no tiene `ref`, pásale el `voiceSettingsProvider.notifier` o
expón un callback — como no vi ese archivo, prefiero que tú decidas
la forma que mejor encaje en tu arquitectura actual en vez de que yo
adivine y rompa algo.

## 4. Agregar la entrada en el perfil

En tu pantalla de perfil (`profile_form_widgets.dart` /
`onboarding_screen.dart` o donde tengas la lista de opciones),
agrega algo así:

```dart
ListTile(
  leading: const Icon(Icons.record_voice_over),
  title: const Text('Voz de guía'),
  subtitle: const Text('Elige y prueba la voz que te acompaña al pedalear'),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VoiceSelectionScreen()),
    );
  },
),
```

Con el import:

```dart
import 'package:cyclecore_app/features/voice/presentation/voice_selection_screen.dart';
```

## 5. Cómo funciona por dentro (resumen rápido)

- `voiceSettingsProvider` guarda qué persona está activa y si la voz
  está encendida, y persiste eso en `shared_preferences`.
- Cuando llamas `.speak(VoiceEventType.algo)`, el motor busca una
  frase al azar entre las variantes de esa persona+evento en
  `voice_line_bank.dart` y la dice con `flutter_tts`, usando el tono
  y velocidad configurados para esa persona.
- Si en el futuro cambias el `source` de una persona a
  `VoiceSourceType.audioPack`, el motor primero intenta reproducir un
  archivo de audio real; si no lo encuentra, cae automáticamente a
  TTS sin errores — puedes migrar personas de a una.

## 6. De dónde sacar audios pre-grabados (para el modo `audioPack`)

Cuando quieras que una persona suene con una voz de verdad grabada
(no el TTS del sistema), tienes estas opciones, de más simple a más
elaborada:

1. **Grabarte tú mismo o pedirle a un amigo/a** que lea el guion (ya
   tienes todas las frases en `voice_line_bank.dart`, cópialas). Usa
   el micrófono del teléfono o una app como Audacity (gratis) para
   grabar, recortar silencios y normalizar el volumen. Exporta como
   `.mp3` a 44.1kHz.

2. **Herramientas de voz sintética de pago** (no son "TTS del
   sistema", generan audio de mejor calidad y con más personalidad,
   pensadas justo para este tipo de uso): ElevenLabs, Play.ht,
   Murf.ai, Google Cloud Text-to-Speech (voces WaveNet/Neural2),
   Amazon Polly Neural. Generas cada frase, descargas el mp3. Revisa
   los términos de licencia comercial de la herramienta que elijas
   antes de usarlas en la app.

3. **Actores de voz freelance** (Fiverr, Voices.com): les pasas el
   guion completo de una persona (por ejemplo las ~16 frases de
   "Entrenador Motivador") y te devuelven los clips grabados.

4. **Evita clonar voces de celebridades o personas reales sin
   permiso** — además de ser un problema legal (derechos de imagen,
   leyes sobre deepfakes), no es necesario: con las opciones de
   arriba puedes crear una voz distintiva y 100% tuya para cada
   persona.

Una vez tengas los archivos, ponlos en:

```
assets/voice_packs/<id_de_la_persona>/start/0.mp3
assets/voice_packs/<id_de_la_persona>/start/1.mp3
assets/voice_packs/<id_de_la_persona>/paused/0.mp3
assets/voice_packs/<id_de_la_persona>/resumed/0.mp3
assets/voice_packs/<id_de_la_persona>/finished/0.mp3
```

(usa los ids: `coach`, `chill`, `sergeant`, `pro`, `sarcastic`, `zen`,
`hype`, `grandma`) y cambia el `source` de esa persona en
`voice_persona.dart` de `VoiceSourceType.systemTts` a
`VoiceSourceType.audioPack`.

## 7. Siguiente paso

Cuando quieras, seguimos con los mensajes dinámicos basados en tu
motor de lógica difusa (`core/fuzzy_engine/`) — por ejemplo, avisos
de ritmo/pendiente que usen las reglas difusas para decidir qué tan
"urgente" o "relajado" debe sonar el aviso, reutilizando este mismo
banco de personas y el motor de voz.
