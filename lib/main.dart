import 'package:bracket/core/constants.dart';
import 'package:bracket/core/router/app_router.dart';
import 'package:bracket/core/theme/app_theme.dart';
import 'package:bracket/core/utils/format.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  runApp(const ProviderScope(child: BracketApp()));
}

class BracketApp extends ConsumerWidget {
  const BracketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
