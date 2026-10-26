import 'package:bracket/data/auth/auth_repository.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:bracket/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Forgot password?": emails a reset link that returns into the app
/// (`emailRedirectTo` deep link), where it opens the recovery session the
/// router holds on /reset-password.
///
/// No app bar, like the other auth screens; the success copy is hedged
/// ("if an account exists…") because the backend never reveals whether
/// the address is registered.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// The destination the user originally asked for, carried login → here →
  /// back so signing in after the reset still lands where they wanted.
  String get _from =>
      GoRouterState.of(context).uri.queryParameters['from'] ?? '';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ref
          .read(authStateProvider.notifier)
          .resetPasswordForEmail(_emailController.text.trim());
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      // Root-level messenger: the snackbar outlives the navigation below.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
      final from = _from;
      context.go(
        Uri(
          path: '/login',
          queryParameters: {if (from.isNotEmpty) 'from': from},
        ).toString(),
      );
    } on AuthFailure catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = authErrorMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // No app bar (auth screens, design): SafeArea keeps the card clear
      // of the status bar; going back is the button at the bottom.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(
                  l10n.forgotPasswordTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forgotPasswordBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(labelText: l10n.emailLabel),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final ok = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email);
                          return ok ? null : l10n.invalidEmail;
                        },
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
                            : Text(l10n.sendResetLink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    final from = _from;
                    context.go(
                      Uri(
                        path: '/login',
                        queryParameters: {if (from.isNotEmpty) 'from': from},
                      ).toString(),
                    );
                  },
                  child: Text(l10n.backToSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
