import 'package:tande/core/theme/app_gradients.dart';
import 'package:tande/core/constants.dart';
import 'package:tande/data/auth/auth_repository.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/auth/widgets/terms_acceptance.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Email/password sign-in.
///
/// On success the router redirect sends the user back to `?from=` (or Explore).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  bool _loading = false;

  /// The social sign-in in flight, if any (disables both buttons).
  SocialProvider? _socialLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Navigation is handled by the router's auth redirect.
    } on AuthFailure catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = authErrorMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInSocial(SocialProvider provider) async {
    if (_loading || _socialLoading != null) return;
    // Captured before the awaits: the auth redirect may unmount this screen
    // the moment the session lands, but the flow must still route
    // first-time OAuth users to the completion screen.
    final router = GoRouter.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final from = GoRouterState.of(context).uri.queryParameters['from'];

    setState(() {
      _error = null;
      _socialLoading = provider;
    });

    try {
      final session = await ref
          .read(authStateProvider.notifier)
          .signInWithOAuth(provider);
      final profile = await container
          .read(profileRepositoryProvider)
          .fetchById(session.userId);
      if (profile == null || !profile.isComplete) {
        // First OAuth sign-in: no profile yet (or an incomplete one) —
        // complete it, keeping the original destination.
        router.go(
          Uri(
            path: '/complete-profile',
            queryParameters: {
              if (from != null && from.isNotEmpty) 'from': from,
            },
          ).toString(),
        );
      }
      // Complete profile: the auth redirect already handles `from`/Explore.
    } on AuthFailure catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = authErrorMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // No app bar: it only left a blank strip above the hero. SafeArea
      // keeps the card clear of the status bar instead.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.brand,
                    ),
                    child: Column(
                      children: [
                        // Bare mark on transparent in white: the hero gradient
                        // already is the mark's field, and the green mark would
                        // sink into it.
                        Image.asset(
                          'assets/icon_white.png',
                          width: 72,
                          height: 72,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.loginTagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final ok = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email);
                          return ok ? null : l10n.invalidEmail;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                        ),
                        validator: (value) => (value ?? '').length >= 6
                            ? null
                            : l10n.passwordTooShort,
                      ),
                      // Right-aligned and compact: it sits between the
                      // password field and the sign-in button without
                      // pushing either out of the first screen.
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          // `go`, like every auth link here (see below).
                          onPressed: () {
                            final from = GoRouterState.of(
                              context,
                            ).uri.queryParameters['from'];
                            context.go(
                              Uri(
                                path: '/forgot-password',
                                queryParameters: {
                                  if (from != null && from.isNotEmpty)
                                    'from': from,
                                },
                              ).toString(),
                            );
                          },
                          child: Text(l10n.forgotPassword),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.signIn),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.orContinueWith,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _socialLoading != null
                      ? null
                      : () => _signInSocial(SocialProvider.google),
                  icon: _socialLoading == SocialProvider.google
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(l10n.continueWith(SocialProvider.google.label)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _socialLoading != null
                      ? null
                      : () => _signInSocial(SocialProvider.apple),
                  icon: _socialLoading == SocialProvider.apple
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.apple, size: 24),
                  label: Text(l10n.continueWith(SocialProvider.apple.label)),
                ),
                const SizedBox(height: 12),
                // OAuth has no form of its own, so the acceptance for
                // Google/Apple sign-ups rides here as fine print.
                Center(
                  child: TermsText(
                    prefix: l10n.socialTermsPrefix,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  // `go`, not `push`: refresh redirects re-match the base route.
                  // Carry `from` so signup + profile completion return to the
                  // screen the user originally wanted.
                  onPressed: () {
                    final from = GoRouterState.of(
                      context,
                    ).uri.queryParameters['from'];
                    context.go(
                      Uri(
                        path: '/signup',
                        queryParameters: {
                          if (from != null && from.isNotEmpty) 'from': from,
                        },
                      ).toString(),
                    );
                  },
                  child: Text(l10n.noAccountSignup),
                ),
                TextButton(
                  onPressed: () => context.go('/explore'),
                  child: Text(l10n.browseAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
