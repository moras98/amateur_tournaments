import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/auth/forgot_password_screen.dart';
import 'package:tande/features/auth/login_screen.dart';
import 'package:tande/features/auth/profile_form_screen.dart';
import 'package:tande/features/auth/reset_password_screen.dart';
import 'package:tande/features/auth/signup_screen.dart';
import 'package:tande/features/explore/explore_screen.dart';
import 'package:tande/features/inscriptions/my_inscriptions_screen.dart';
import 'package:tande/features/organizer/event_form_screen.dart';
import 'package:tande/features/organizer/event_requests_screen.dart';
import 'package:tande/features/organizer/organizer_screen.dart';
import 'package:tande/features/profile/profile_screen.dart';
import 'package:tande/features/pro/paywall_screen.dart';
import 'package:tande/features/tournament/tournament_detail_screen.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root destinations, in bottom-nav order.
final _rootDestinations = [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/inscriptions',
        builder: (context, state) => const MyInscriptionsScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/organize',
        builder: (context, state) => const OrganizerScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  ),
];

/// Routes anyone can open without signing in.
bool _isPublic(String location) =>
    location == '/explore' ||
    location == '/login' ||
    location == '/signup' ||
    location == '/forgot-password' ||
    location.startsWith('/tournament/');

/// Auth gate. Keeps the router instance stable across auth changes by
/// pairing it with [refreshListenable].
///
/// Note: go_router re-evaluates this against the *base* location (pushed
/// pages are not re-matched), so the auth screens navigate with `go`.
String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  final session = ref.read(authStateProvider);
  final signedIn = session != null;

  // Password-recovery session (the reset email's link landed): the whole
  // point of that session is setting a new password, so hold the user on
  // /reset-password until [AuthController.updatePassword] releases the
  // flag — wherever they try to go, including back to /login.
  if (session != null && session.recovery && location != '/reset-password') {
    return '/reset-password';
  }

  if (!signedIn) {
    if (_isPublic(location)) return null;
    // Remember where the user was headed, including /complete-profile.
    return Uri(path: '/login', queryParameters: {'from': location}).toString();
  }

  if (location == '/login') {
    return state.uri.queryParameters['from'] ?? '/explore';
  }
  // No redirect for /signup: the sign-up form collects the profile itself
  // and navigates (from ?? /explore) once the account row is topped up.
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluates the redirect whenever the auth state changes, without
  // recreating the router (which would reset navigation).
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/explore',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    // Unknown locations (broken deep links, bad `from` values) would
    // otherwise render a blank screen.
    errorBuilder: (context, state) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.errorScreenTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.errorScreenBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/explore'),
                  child: Text(l10n.errorScreenBack),
                ),
              ],
            ),
          ),
        ),
      );
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: _rootDestinations,
      ),
      GoRoute(
        path: '/tournament/:id',
        pageBuilder: (context, state) => _pushPage(
          state,
          TournamentDetailScreen(tournamentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/organize/create',
        pageBuilder: (context, state) =>
            _pushPage(state, const EventFormScreen()),
      ),
      GoRoute(
        path: '/organize/event/:id',
        pageBuilder: (context, state) => _pushPage(
          state,
          EventRequestsScreen(tournamentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/organize/event/:id/edit',
        pageBuilder: (context, state) => _pushPage(
          state,
          EventFormScreen(tournamentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _pushPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _pushPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) =>
            _pushPage(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _pushPage(state, const SignUpScreen()),
      ),
      GoRoute(
        path: '/complete-profile',
        pageBuilder: (context, state) =>
            _pushPage(state, const ProfileFormScreen()),
      ),
      GoRoute(
        path: '/pro',
        pageBuilder: (context, state) =>
            _pushPage(state, const PaywallScreen()),
      ),
    ],
  );
});

/// Pushed screens: quick fade + slide-up (240 ms) instead of the platform
/// default, so navigation feels app-like and consistent on both platforms.
CustomTransitionPage<void> _pushPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Bottom-navigation shell around the root destinations.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Floating capsule (design.md §7): bordered surface pill floating on the
    // page tint — the cards' tonal recipe, no shadow. SafeArea runs outside
    // the pill so the gesture inset stays out of it: NavigationBar pads
    // itself from MediaQuery internally.
    // Geometry comes from core/utils/nav_geometry.dart (bar height 64 → the
    // radius is exactly half, i.e. a stadium).
    const radius = BorderRadius.all(Radius.circular(kNavCapsuleBarHeight / 2));
    final navBar = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(kNavCapsuleMargin),
        child: DecoratedBox(
          // Hairline painted after the child: NavigationBar's own opaque
          // Material background would cover it otherwise.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: radius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  // Returning to an already-selected tab pops to its root.
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: l10n.navExplore,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.confirmation_num_outlined),
                    selectedIcon: Icon(Icons.confirmation_num),
                    // Short enough for one line in a quarter of the capsule:
                    // the SDK's label Text has no maxLines/ellipsis hook.
                    label: l10n.navInscriptions,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    selectedIcon: Icon(Icons.emoji_events),
                    label: l10n.navOrganize,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: l10n.navProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      // The Explore map runs full-bleed behind the floating capsule (its
      // tab only); every other tab keeps the reserved area so content ends
      // above the bar. Explore elements that must not sit under the pill
      // clear it with navBarClearanceOf (core/utils/nav_geometry.dart).
      extendBody: navigationShell.currentIndex == 0,
      body: navigationShell,
      bottomNavigationBar: navBar,
    );
  }
}
