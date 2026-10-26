import 'package:tande/core/constants.dart';
import 'package:tande/data/billing/billing_service.dart';
import 'package:tande/features/auth/widgets/terms_acceptance.dart';
import 'package:tande/features/pro/pro_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Tande Pro paywall (LAUNCH.md §7): benefits, plans, Play purchase.
///
/// Reached from the profile card and from the free-tier gate. Three
/// states: products not configured yet ("Próximamente"), already
/// subscribed, and the buy flow. On a successful purchase the state flips
/// under us — the screen simply re-renders as "already Pro".
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = AppConstants.proMonthlyId;

  ProProduct _productOf(ProState pro, String id) => pro.products.firstWhere(
    (p) => p.id == id,
    orElse: () => pro.products.first,
  );

  Future<void> _buy(ProState pro) async {
    final ok = await ref
        .read(proProvider.notifier)
        .buy(_productOf(pro, _selected));
    if (!mounted || ok) return; // Success flips the state below.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_l10n().proPurchaseError)));
  }

  Future<void> _restore() async {
    final found = await ref.read(proProvider.notifier).restore();
    if (!mounted) return;
    if (!found) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l10n().proRestoreMissing)));
    }
    // Found → the state flips to "already Pro".
  }

  AppLocalizations _l10n() => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n();
    final theme = Theme.of(context);
    final pro = ref.watch(proProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proTitle)),
      body: switch ((pro.available, pro.isPro)) {
        (false, _) => _StatusNote(
          icon: Icons.schedule,
          title: l10n.proComingSoon,
          body: l10n.proComingSoonBody,
        ),
        (true, true) => _StatusNote(
          icon: Icons.check_circle_outline,
          title: l10n.proAlready,
          body: l10n.proAlreadyBody,
        ),
        _ => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header: the brand mark and the promise, centered.
            Icon(
              Icons.workspace_premium,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.proProfileHint,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Benefits.
            for (final benefit in [
              l10n.proBenefit1,
              l10n.proBenefit2,
              l10n.proBenefit3,
              l10n.proBenefit4,
              l10n.proBenefit5,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(l10n.proChoosePlan, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            // Plans — fixed monthly/yearly slots, rendered when Play has
            // them (service order is not guaranteed).
            for (final id in [
              AppConstants.proMonthlyId,
              AppConstants.proYearlyId,
            ])
              if (pro.products.any((p) => p.id == id)) ...[
                _PlanCard(
                  product: _productOf(pro, id),
                  label: id == AppConstants.proMonthlyId
                      ? l10n.proMonthly
                      : l10n.proYearly,
                  badge: id == AppConstants.proYearlyId
                      ? l10n.proBestValue
                      : null,
                  selected: _selected == id,
                  onTap: () => setState(() => _selected = id),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: pro.busy ? null : () => _buy(pro),
              child: pro.busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppConstants.proTrialDays == null
                          ? l10n.proSubscribeCta
                          : l10n.proTrialCta,
                    ),
            ),
            if (AppConstants.proTrialDays != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.proTrialNotice(AppConstants.proTrialDays!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: pro.busy ? null : _restore,
              child: Text(l10n.proRestore),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.proDisclosure,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                TermsText(prefix: l10n.proLegalPrefix),
                LegalLink(
                  label: l10n.privacyPolicy,
                  url: AppConstants.privacyUrl,
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

/// Full-screen informational state (coming soon / already subscribed).
class _StatusNote extends StatelessWidget {
  const _StatusNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable plan row: radio + plan name + Play's formatted price, with
/// a tonal badge on the yearly slot.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final ProProduct product;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: theme.textTheme.titleMedium),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      product.price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
