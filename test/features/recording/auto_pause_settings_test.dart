import 'package:cyclecore_app/features/recording/application/auto_pause_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deja terminar la carga asíncrona inicial del notifier.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('viene encendida si nunca se tocó', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(autoPauseEnabledProvider);
    await _settle();

    expect(container.read(autoPauseEnabledProvider), isTrue);
  });

  test('apagarla se recuerda en la siguiente apertura', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    await first.read(autoPauseEnabledProvider.notifier).setEnabled(false);
    expect(first.read(autoPauseEnabledProvider), isFalse);
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    second.read(autoPauseEnabledProvider);
    await _settle();

    expect(second.read(autoPauseEnabledProvider), isFalse);
  });
}
