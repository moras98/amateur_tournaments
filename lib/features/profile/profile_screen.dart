import 'package:bracket/core/sports.dart';
import 'package:bracket/core/theme/adaptive.dart';
import 'package:bracket/core/theme/app_gradients.dart';
import 'package:bracket/core/utils/format.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:bracket/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Signed-in user's profile: data, organizer badge, edit and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentProfileProvider);
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
