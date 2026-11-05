import 'package:tande/core/constants.dart';
import 'package:tande/core/observability/analytics.dart';
import 'package:tande/core/router/app_router.dart';
import 'package:tande/core/theme/app_theme.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Spanish day/month names for `DateFormat(..., appLocale)` (English
  // names ship built into `intl`).
  await initializeDateFormatting(appLocale);

  // Runs only when SUPABASE_URL / SUPABASE_ANON_KEY are passed via
  // --dart-define; otherwise the app stays on repository mocks.
  if (AppConstants.hasSupabase) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  // Crash reporting is opt-in: without a DSN (tests, local mock builds) the
  // app starts exactly as before and the SDK is never initialized.
  if (!AppConstants.hasSentry) {
    _runApp();
    return;
  }

  try {
    await SentryFlutter.init(
      (options) => options
        ..dsn = AppConstants.sentryDsn
        ..environment = AppConstants.sentryEnvironment
        ..release = AppConstants.appRelease
        // Sample a tenth of the traces: enough to see slow screens without
        // burning the free quota on every navigation.
        ..tracesSampleRate = 0.1
        // No IP address, cookies or user content by default. The user id is
        // attached explicitly by `SentryAnalytics.identify`.
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..maxBreadcrumbs = 50,
      appRunner: _runApp,
    );
  } catch (_) {
    // A bad DSN or a native init failure must not keep the app from opening.
    _runApp();
  }
}

void _runApp() {
  runApp(const ProviderScope(child: TandeApp()));
}

/// Keeps the crash-report identity in sync with the session. A provider (not
/// a build side effect) so the initial restored session is covered too.
final _analyticsIdentityProvider = Provider<void>((ref) {
  final analytics = ref.read(analyticsProvider);
  final session = ref.read(authStateProvider);
  if (session == null) {
    analytics.reset();
  } else {
    analytics.identify(session.userId);
  }
  ref.listen(authStateProvider, (previous, next) {
    if (next == null) {
      analytics.reset();
    } else {
      analytics.identify(next.userId);
    }
  });
});

class TandeApp extends ConsumerWidget {
  const TandeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(_analyticsIdentityProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Follows the phone: any Spanish locale gets the app's Uruguayan
      // copy (es_UY), English gets English, any other language falls back
      // to the app's source (Uruguayan Spanish). Also picks the date
      // locale: money always stays peso-styled regardless.
      localeResolutionCallback: (device, supported) {
        final hasEsUy = supported.contains(const Locale('es', 'UY'));
        Locale resolved;
        switch (device?.languageCode) {
          case 'es':
            resolved = hasEsUy
                ? const Locale('es', 'UY')
                : supported.firstWhere((l) => l.languageCode == 'es');
          case 'en':
            resolved = supported.firstWhere((l) => l.languageCode == 'en');
          default:
            resolved = hasEsUy ? const Locale('es', 'UY') : supported.first;
        }
        activeLocale = resolved.languageCode == 'es' ? appLocale : 'en_US';
        return resolved;
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Cupertino widgets (iOS alerts, wheels, switches) tint with the
      // app's primary instead of the system blue.
      builder: (context, child) => CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: Theme.of(context).colorScheme.primary,
          brightness: Theme.of(context).brightness,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }
}
