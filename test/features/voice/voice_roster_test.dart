import 'package:cyclecore_app/features/profile/domain/kit_unlocks.dart';
import 'package:cyclecore_core/gamification/level_info.dart';
import 'package:cyclecore_app/features/profile/presentation/cyclist_kit_providers.dart';
import 'package:cyclecore_app/features/voice/data/voice_engine.dart';
import 'package:cyclecore_app/features/voice/domain/voice_event.dart';
import 'package:cyclecore_app/features/voice/domain/voice_persona.dart';
import 'package:cyclecore_app/features/voice/presentation/voice_providers.dart';
import 'package:cyclecore_app/features/voice/presentation/widgets/voice_roster_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Motor de voz mudo para los tests: evita tocar flutter_tts / audioplayers
/// (que dejan timers pendientes en el entorno de test).
class _SilentEngine implements VoiceEngine {
  @override
  Future<void> init() async {}
  @override
  VoicePersona get currentPersona => kVoicePersonas.first;
  @override
  Future<void> setPersona(VoicePersona persona) async {}
  @override
  Future<void> speakEvent(VoiceEventType event) async {}
  @override
  Future<void> speakSample(VoicePersona persona, VoiceEventType event) async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

KitUnlockContext _ctx({
  int level = 3,
  CyclistRank rank = CyclistRank.rodador,
  double totalKm = 200,
  double totalElevationM = 500,
  int postalesCount = 0,
  double bestRideSpeedKmh = 20,
  double longestRideKm = 20,
}) {
  return KitUnlockContext(
    level: level,
    rank: rank,
    totalKm: totalKm,
    totalElevationM: totalElevationM,
    postalesCount: postalesCount,
    bestRideSpeedKmh: bestRideSpeedKmh,
    longestRideKm: longestRideKm,
  );
}

VoicePersona _byId(String id) => kVoicePersonas.firstWhere((p) => p.id == id);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el roster tiene 5 voces: 2 gratis y 3 por desbloquear', () {
    expect(kVoicePersonas, hasLength(5));
    expect(
      kVoicePersonas.where((p) => p.tier == VoiceTier.gratis).map((p) => p.id),
      containsAll(['pro', 'chill']),
    );
    expect(
      kVoicePersonas
          .where((p) => p.tier == VoiceTier.desbloqueable)
          .map((p) => p.id),
      containsAll(['coach', 'hype', 'zen']),
    );
    // Retiradas.
    expect(kVoicePersonas.map((p) => p.id), isNot(contains('sergeant')));
    expect(kVoicePersonas.map((p) => p.id), isNot(contains('sarcastic')));
    expect(kVoicePersonas.map((p) => p.id), isNot(contains('grandma')));
  });

  test('las voces gratis están siempre disponibles', () {
    expect(isVoicePersonaUnlocked(_byId('pro'), null), isTrue);
    expect(isVoicePersonaUnlocked(_byId('chill'), null), isTrue);
  });

  test(
    'festejo de voz: la primera vez inicializa; luego devuelve las nuevas',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final seen = container.read(voiceUnlocksSeenProvider.notifier);
      await Future<void>.delayed(Duration.zero); // deja correr la carga inicial

      // Primera reconciliación: sólo inicializa, no festeja el backlog.
      expect(await seen.reconcile({'pro', 'chill'}), isEmpty);
      // Ahora se desbloquea una voz nueva -> se devuelve para festejarla.
      expect(await seen.reconcile({'pro', 'chill', 'coach'}), {'coach'});
      // Ya vista: no se repite.
      expect(await seen.reconcile({'pro', 'chill', 'coach'}), isEmpty);
    },
  );

  test('las voces de logro dependen del contexto', () {
    final entrenador = _byId('coach'); // corona el rango Rodador
    expect(isVoicePersonaUnlocked(entrenador, null), isFalse);
    expect(
      isVoicePersonaUnlocked(entrenador, _ctx(rank: CyclistRank.novato)),
      isFalse,
    );
    expect(
      isVoicePersonaUnlocked(entrenador, _ctx(rank: CyclistRank.escalador)),
      isTrue,
    );

    final director = _byId('hype'); // 30 km/h de media
    expect(
      isVoicePersonaUnlocked(director, _ctx(bestRideSpeedKmh: 25)),
      isFalse,
    );
    expect(
      isVoicePersonaUnlocked(director, _ctx(bestRideSpeedKmh: 32)),
      isTrue,
    );

    final ritmo = _byId('zen'); // 3.000 m de desnivel
    expect(isVoicePersonaUnlocked(ritmo, _ctx(totalElevationM: 1000)), isFalse);
    expect(isVoicePersonaUnlocked(ritmo, _ctx(totalElevationM: 4000)), isTrue);
  });

  testWidgets('VoiceRosterView pinta los tres estantes y el estado bloqueado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceEngineProvider.overrideWithValue(_SilentEngine()),
          kitUnlockContextProvider.overrideWithValue(
            _ctx(
              rank: CyclistRank.novato,
              totalElevationM: 100,
              bestRideSpeedKmh: 18,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: VoiceRosterView())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('GRATIS'), findsOneWidget);
    expect(find.text('POR DESBLOQUEAR'), findsOneWidget);
    expect(find.text('Estándar'), findsOneWidget);
    expect(find.text('Entrenador'), findsOneWidget);
    expect(find.text('Corona el rango Rodador'), findsOneWidget);
    expect(find.text('En uso'), findsOneWidget);
    expect(find.text('Probar'), findsWidgets);

    // El estante premium está más abajo en la lista.
    await tester.scrollUntilVisible(find.text('Voces de artista'), 300);
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.text('Voces de artista'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
