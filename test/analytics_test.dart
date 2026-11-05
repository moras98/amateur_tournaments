import 'package:tande/core/observability/analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalytics implements Analytics {
  final events = <String>[];
  final identified = <String>[];
  var resets = 0;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    events.add(event);
  }

  @override
  void identify(String userId) => identified.add(userId);

  @override
  void reset() => resets++;
}

void main() {
  test('composite forwards every call to all sinks', () {
    final first = _FakeAnalytics();
    final second = _FakeAnalytics();
    final analytics = CompositeAnalytics([first, second]);

    analytics
      ..track('tournament_created', {'sport': 'padel'})
      ..identify('u-1')
      ..reset();

    for (final sink in [first, second]) {
      expect(sink.events, ['tournament_created']);
      expect(sink.identified, ['u-1']);
      expect(sink.resets, 1);
    }
  });

  test('without Supabase or Sentry the provider is a no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(analyticsProvider), isA<NoopAnalytics>());
  });
}
