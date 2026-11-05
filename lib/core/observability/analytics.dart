import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tande/core/constants.dart';

/// Product events, kept intentionally small and PII-free.
///
/// In production this fans out to two sinks:
/// - [SupabaseAnalytics] stores the event in `public.analytics_events`;
/// - [SentryAnalytics] adds a breadcrumb so a crash report shows what the
///   user was doing right before it.
///
/// Tests and mock builds get [NoopAnalytics], so nothing leaves the device.
/// Firebase Analytics can be added later as another sink without touching the
/// screens that call [track].
abstract class Analytics {
  /// A product event, e.g. `tournament_created`. [properties] must only carry
  /// non-sensitive values (ids, sport, kind, counts) — never names or phones.
  void track(String event, [Map<String, Object?> properties = const {}]);

  void identify(String userId);

  void reset();
}

class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {}

  @override
  void identify(String userId) {}

  @override
  void reset() {}
}

class CompositeAnalytics implements Analytics {
  CompositeAnalytics(Iterable<Analytics> sinks) : _sinks = List.of(sinks);

  final List<Analytics> _sinks;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    for (final sink in _sinks) {
      sink.track(event, properties);
    }
  }

  @override
  void identify(String userId) {
    for (final sink in _sinks) {
      sink.identify(userId);
    }
  }

  @override
  void reset() {
    for (final sink in _sinks) {
      sink.reset();
    }
  }
}

/// First-party product analytics: one row per event in Supabase.
///
/// The table is insert-only for clients (RLS: `user_id = auth.uid()`), so the
/// user id is attached here and cannot be spoofed. Anonymous visitors have no
/// user id and are not tracked.
class SupabaseAnalytics implements Analytics {
  SupabaseAnalytics(this._client);

  final SupabaseClient _client;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    final user = _client.auth.currentUser;
    if (user == null) return;
    // Fire and forget: a failed analytics write must never surface in the UI
    // or block the action that generated it.
    unawaited(
      _client
          .from('analytics_events')
          .insert({
            'user_id': user.id,
            'event': event,
            'properties': properties,
            'app_version': AppConstants.appRelease,
            'platform': defaultTargetPlatform.name,
          })
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
  }

  /// The server derives the user from the JWT; nothing to do client-side.
  @override
  void identify(String userId) {}

  @override
  void reset() {}
}

/// Crash breadcrumbs + the Sentry user id. Only installed when a DSN is
/// present, so tests and local builds never initialize the SDK.
class SentryAnalytics implements Analytics {
  const SentryAnalytics();

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: event,
          category: 'analytics',
          level: SentryLevel.info,
          data: properties.isEmpty ? null : properties,
          timestamp: DateTime.now().toUtc(),
        ),
      ),
    );
  }

  @override
  void identify(String userId) {
    unawaited(
      Future.sync(
        () => Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: userId)),
        ),
      ),
    );
  }

  @override
  void reset() {
    unawaited(
      Future.sync(() => Sentry.configureScope((scope) => scope.setUser(null))),
    );
  }
}

/// Chooses the sinks that are actually configured. With no Supabase and no
/// Sentry (tests, local mock builds) this is a no-op.
final analyticsProvider = Provider<Analytics>((ref) {
  final sinks = <Analytics>[
    if (AppConstants.hasSupabase) SupabaseAnalytics(Supabase.instance.client),
    if (AppConstants.hasSentry) const SentryAnalytics(),
  ];
  return switch (sinks.length) {
    0 => const NoopAnalytics(),
    1 => sinks.first,
    _ => CompositeAnalytics(sinks),
  };
});
