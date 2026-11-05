import 'package:tande/core/sports.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/theme/app_gradients.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/widgets/tande_toast.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/pro/pro_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Signed-in user's profile: data, organizer badge, edit, sign out and
/// account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// True from the first confirmation until the deletion resolves: the
  /// dialogs are modal, but the gap between them (and the banner cleanup)
  /// is not — a second tap must not stack a second flow.
  bool _deleting = false;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Reversible, but still an exit: error-tinted confirm (design.md §7)
    // on Material, native red action on iOS.
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOutConfirmTitle,
      message: l10n.signOutConfirmMessage,
      confirmLabel: l10n.signOut,
      destructive: true,
      icon: Icons.logout,
    );
    if (confirmed != true) return;
    await ref.read(authStateProvider.notifier).signOut();
    // The router redirect takes over from here.
  }

  /// In-app account deletion — the flow both stores require (App Store
  /// guideline 5.1.1(v) and Play's account-deletion policy): two explicit
  /// confirmations, the uploaded banners cleaned first, then the backend
  /// cascade (migration 0012). A failure surfaces as a toast and leaves the
  /// account untouched.
  Future<void> _deleteAccount() async {
    if (_deleting) return;
    final l10n = AppLocalizations.of(context)!;

    // First confirmation: what is about to happen, in plain words.
    final first = await showConfirmDialog(
      context,
      title: l10n.deleteAccountConfirmTitle,
      message: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccountContinue,
      destructive: true,
      icon: Icons.delete_forever_outlined,
    );
    if (first != true || !mounted) return;

    // Second: the irreversible action itself. Deleting an account can
    // never be one tap away from the warning screen.
    final second = await showConfirmDialog(
      context,
      title: l10n.deleteAccountFinalTitle,
      message: l10n.deleteAccountFinalMessage,
      confirmLabel: l10n.deleteAccount,
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (second != true || !mounted) return;

    setState(() => _deleting = true);
    // Captured before the first await: `ref` throws once this state is
    // disposed, and the redirect after deletion can unmount us mid-flow.
    final storage = ref.read(bannerStorageProvider);
    final myTournaments = ref.read(myTournamentsProvider.future);
    final auth = ref.read(authStateProvider.notifier);

    // Banners live in a public bucket with no FK to the account — they
    // don't cascade, so they go first. Best effort: an orphaned image must
    // never block the deletion the user just confirmed twice.
    try {
      for (final t in await myTournaments) {
        final path = t.bannerPath;
        if (path != null) await storage.remove(path);
      }
    } catch (_) {
      // Best effort (see above).
    }

    try {
      await auth.deleteAccount();
      if (!mounted) return;
      showTandeToast(
        context,
        l10n.deleteAccountSuccess,
        kind: ToastKind.success,
      );
    } catch (error) {
      if (!mounted) return;
      showTandeToast(
        context,
        l10n.deleteAccountFailed('$error'),
        kind: ToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentProfileProvider);
    final pro = ref.watch(proProvider);
    final theme = Theme.of(context);

    return Scaffold(
      // No app bar: with the title gone it was a blank strip content
      // scrolled under. SafeArea carries the status-bar inset; the bottom
      // is already inset by the floating nav capsule (non-extendBody tab).
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(l10n.loadError(error))),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.notSignedIn),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/login?from=%2Fprofile'),
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              );
            }

            final incomplete = !profile.isComplete;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.brand,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName
                                      .trim()
                                      .split(RegExp(r'\s'))
                                      .take(2)
                                      .map((w) => w[0].toUpperCase())
                                      .join()
                                : '?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '@${profile.username}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (incomplete) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      title: Text(
                        l10n.incompleteProfile,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      subtitle: Text(
                        l10n.completeProfileHint,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: () => context.push('/complete-profile'),
                      ),
                    ),
                  ),
                ],
                // Tande Pro entry: visible to organizers while they don't
                // hold the entitlement. Before Play has products the
                // paywall shows the benefits and a "próximamente" note —
                // informational, nothing is gated. Once products exist the
                // same screen runs the store purchase.
                if (profile.isOrganizer && !(pro.available && pro.isPro)) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.workspace_premium,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(l10n.proTitle),
                      subtitle: Text(l10n.proProfileHint),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.push('/pro'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _Section(
                  title: l10n.aboutYou,
                  children: [
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      label: l10n.birthDate,
                      value: profile.birthDate == null
                          ? '—'
                          // Date only (es_UY via appLocale): a birth date never
                          // shows a time — formatEventDate would add "• 00:00".
                          : formatDate(profile.birthDate!),
                    ),
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: l10n.gender,
                      value: profile.gender.isEmpty
                          ? '—'
                          : l10n.genderLabel(profile.gender),
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: l10n.phoneLabel,
                      value: profile.phone.isEmpty ? '—' : profile.phone,
                    ),
                    _InfoTile(
                      icon: Icons.emoji_events_outlined,
                      label: l10n.role,
                      value: profile.isOrganizer ? l10n.organizer : l10n.player,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: l10n.sportsTitle,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      // Same dash convention as the info tiles above.
                      child: profile.sports.isEmpty
                          ? const Text('—')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final sport in profile.sports)
                                  _SportChip(sport),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push('/complete-profile'),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editProfile),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
                const SizedBox(height: 12),
                // Destructive action kept apart from sign-out and tinted
                // with error (design.md §7) so nobody taps it thinking
                // it's "leave".
                OutlinedButton.icon(
                  onPressed: _deleting ? null : _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteAccount),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Read-only sport tag (profile "Deportes"): no fill and no border — just
/// the sport glyph in full accent + a semibold `onSurface` label, padded to
/// keep the row rhythm (a lone tinted pill reads odd; display tags never
/// borrow the filter-chip recipe).
class _SportChip extends StatelessWidget {
  const _SportChip(this.sport);

  final String sport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = sportColor(sport);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sportIcon(sport), size: 18, color: accent),
          const SizedBox(width: 6),
          Text(
            l10n.sportLabel(sport),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
