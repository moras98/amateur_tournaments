import 'dart:async';

import 'package:bracket/core/theme/app_gradients.dart';
import 'package:bracket/core/theme/adaptive.dart';
import 'package:bracket/data/auth/auth_repository.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/auth/widgets/profile_fields.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:bracket/l10n/labels.dart';
import 'package:bracket/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Account creation in three in-screen steps (design.md §7): the
/// credential, the profile basics and the sports — dot indicator with the
/// back arrow on top, a single full-width action at the bottom. Email and
/// username are checked live (250 ms debounce) so a duplicate surfaces
/// while typing, not at submit. A new account lands in the app already
/// complete; the profile edit form (`/complete-profile`) remains for OAuth
/// first sign-ins, the email-confirmation flow and later edits.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  /// 0 = account, 1 = basics, 2 = sports.
  int _step = 0;
  DateTime? _birthDate;
  String _gender = '';
  List<String> _sports = ['football'];

  // Debounced live duplicate checks (250 ms, like the inscriptions
  // search): each flag feeds its field's validator.
  Timer? _emailDebounce;
  bool _emailTaken = false;
  Timer? _usernameDebounce;
  bool _usernameTaken = false;

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<bool> _lookupEmail(String email) {
    final looksLikeEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    if (email.isEmpty || !looksLikeEmail) return Future.value(false);
    return ref.read(authStateProvider.notifier).isEmailRegistered(email);
  }

  Future<bool> _lookupUsername(String username) {
    if (username.isEmpty) return Future.value(false);
    return ref.read(profileRepositoryProvider).isUsernameTaken(username);
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    final email = value.trim();
    _emailDebounce = Timer(const Duration(milliseconds: 250), () async {
      final taken = await _lookupEmail(email);
      // A newer edit owns the field now.
      if (!mounted || email != _emailController.text.trim()) return;
      setState(() => _emailTaken = taken);
    });
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final username = value.trim();
    _usernameDebounce = Timer(const Duration(milliseconds: 250), () async {
      final taken = await _lookupUsername(username);
      if (!mounted || username != _usernameController.text.trim()) return;
      setState(() => _usernameTaken = taken);
    });
  }

  /// Runs the check now, replacing the debounce's (possibly stale) result:
  /// the tap decides with current data, never with a pending timer.
  Future<void> _refreshEmailTaken() async {
    _emailDebounce?.cancel();
    final email = _emailController.text.trim();
    final taken = await _lookupEmail(email);
    if (!mounted || email != _emailController.text.trim()) return;
    setState(() => _emailTaken = taken);
  }

  Future<void> _refreshUsernameTaken() async {
    _usernameDebounce?.cancel();
    final username = _usernameController.text.trim();
    final taken = await _lookupUsername(username);
    if (!mounted || username != _usernameController.text.trim()) return;
    setState(() => _usernameTaken = taken);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(
      context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  /// Runs the step's availability check now (the tap must not race the
  /// 250 ms debounce), validates the current step's fields (the form only
  /// mounts those) and advances.
  Future<void> _next() async {
    if (_loading) return;
    // Spinner + disabled action while the check answers.
    setState(() => _loading = true);
    if (_step == 0) {
      await _refreshEmailTaken();
    } else if (_step == 1) {
      await _refreshUsernameTaken();
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 1 && _birthDate == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseBirthDate)));
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    if (_sports.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseSport)));
      return;
    }
    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseBirthDate)));
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    // Captured before the awaits: the auth state change can unmount this
    // screen the moment the session lands, but the profile write and the
    // navigation must still happen.
    final container = ProviderScope.containerOf(context, listen: false);
    final from = GoRouterState.of(context).uri.queryParameters['from'];

    try {
      final session = await ref
          .read(authStateProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (!mounted) return;
      if (session == null) {
        // Email confirmation pending (Supabase default): informational, not
        // an error — the account was created. The profile form picks the
        // rest up after confirming and signing in.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountCreatedConfirmEmail)),
        );
        context.go('/login');
        return;
      }

      // The sign-up already wrote the account row — top it up with what
      // the form collected so the profile is complete from the start.
      final existing = await ref
          .read(profileRepositoryProvider)
          .fetchById(session.userId);
      final profile =
          (existing ??
                  UserModel(
                    id: session.userId,
                    username: '',
                    fullName: '',
                    gender: '',
                  ))
              .copyWith(
                username: _usernameController.text.trim(),
                fullName: _nameController.text.trim(),
                birthDate: () => _birthDate,
                gender: _gender,
                sports: _sports,
              );
      await ref.read(profileRepositoryProvider).save(profile);
      if (!mounted) return;
      container.invalidate(currentProfileProvider);

      context.go(from != null && from.isNotEmpty ? from : '/explore');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e, l10n));
    } on StateError {
      // The mock store's username-unique guard (the DB has the real one).
      if (mounted) setState(() => _error = l10n.usernameTaken);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Step header: the dots centered, with the back arrow on the left
  /// (steps 2+).
  Widget _stepHeader() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _StepDots(step: _step),
          if (_step > 0)
            Positioned(
              // Optical: the glyph lands on the 16 gutter, not the 24 pad.
              left: -8,
              child: IconButton(
                tooltip: l10n.back,
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
        ],
      ),
    );
  }

  /// The step's single full-width filled action (design.md §7).
  Widget _filledAction(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }

  Widget _errorText(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // No app bar: it only left a blank strip above the hero. SafeArea
      // keeps the card clear of the status bar instead.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            // The form stays mounted across steps (a GlobalKey cannot live
            // inside the switching children); since only the current
            // step's fields are in the tree, `validate` is step-scoped.
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  // Identifies the step to the switcher (fresh scroll each).
                  key: ValueKey(_step),
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  children: switch (_step) {
                    0 => _accountStep(theme),
                    1 => _basicsStep(theme),
                    _ => _sportsStep(theme),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1 — the credential, on the brand hero.
  List<Widget> _accountStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(gradient: AppGradients.brand),
          child: Column(
            children: [
              // Same bare mark as the login hero — keeps both auth
              // screens speaking the same visual language.
              Image.asset('assets/icon_fg.png', width: 72, height: 72),
              const SizedBox(height: 16),
              Text(
                l10n.signupHeroTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.signupHeroSubtitle,
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
      _stepHeader(),
      const SizedBox(height: 24),
      TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: l10n.fullName),
        validator: (value) =>
            (value ?? '').trim().isEmpty ? l10n.enterName : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: _onEmailChanged,
        decoration: InputDecoration(labelText: l10n.emailLabel),
        validator: (value) {
          final email = value?.trim() ?? '';
          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
          if (!ok) return l10n.invalidEmail;
          if (_emailTaken) return l10n.authEmailTaken;
          return null;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        onFieldSubmitted: (_) => _next(),
        decoration: InputDecoration(labelText: l10n.passwordLabel),
        // The live checklist below mirrors these rules.
        validator: (value) => PasswordRules.validate(value ?? '', l10n),
        onChanged: (_) => setState(() {}),
      ),
      PasswordChecklist(password: _passwordController.text),
      const SizedBox(height: 20),
      _filledAction(l10n.next, _next),
      const SizedBox(height: 12),
      TextButton(
        // `go`, not `push`: refresh redirects re-match the base route.
        onPressed: () => context.go('/login'),
        child: Text(l10n.alreadyHaveAccount),
      ),
    ];
  }

  /// Step 2 — username (with live uniqueness), birth date, gender.
  List<Widget> _basicsStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 8),
      _stepHeader(),
      const SizedBox(height: 16),
      Text(
        l10n.aboutYou,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      UsernameField(
        controller: _usernameController,
        isTaken: _usernameTaken,
        onChanged: _onUsernameChanged,
      ),
      const SizedBox(height: 12),
      BirthDateField(value: _birthDate, onTap: _pickBirthDate),
      const SizedBox(height: 16),
      Text(l10n.gender, style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      GenderChips(
        selected: _gender,
        onChanged: (gender) => setState(() => _gender = gender),
      ),
      const SizedBox(height: 24),
      _filledAction(l10n.next, _next),
    ];
  }

  /// Step 3 — the sports, then create the account.
  List<Widget> _sportsStep(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return [
      const SizedBox(height: 8),
      _stepHeader(),
      const SizedBox(height: 16),
      Text(
        l10n.whatDoYouPlay,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        l10n.sportsFilterHint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      SportsChips(
        selected: _sports,
        onToggle: (sport) => setState(() {
          _sports = List.of(_sports);
          _sports.contains(sport) ? _sports.remove(sport) : _sports.add(sport);
        }),
      ),
      if (_error != null) _errorText(theme),
      const SizedBox(height: 24),
      _filledAction(l10n.createAccount, _submit),
    ];
  }
}

/// Three-dot step indicator: the current step is the long pill.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: i == step ? 24 : 8,
            height: 8,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            decoration: BoxDecoration(
              color: i <= step
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
