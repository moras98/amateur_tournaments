import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/pro/paywall_screen.dart';
import 'package:tande/features/pro/pro_providers.dart';
import 'package:tande/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Route guard for the two flows that create a **new** tournament:
/// `/organize/create` and `/organize/duplicate/:id`.
///
/// The Organizar tab already sends the organizer to the paywall when the
/// free tier is full, but a deep link (or a stale screen) used to open the
/// form anyway. This wrapper closes that path; `EventFormScreen._save` keeps
/// a second check because the count can change while the form is open.
///
/// Paying mode off (Play has no products) and Pro both render [child]
/// untouched. A failed tournaments load never blocks creation.
class ProGate extends ConsumerWidget {
  const ProGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    if (!pro.available || pro.isPro) return child;

    final tournaments = ref.watch(myTournamentsProvider);
    return tournaments.when(
      // A spinner is better than flashing the form and then replacing it.
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Never turn a network failure into a paywall: the organizer gets the
      // form and the final save check still runs.
      error: (error, stack) => child,
      data: (tournaments) {
        final active = activeTournamentCount(tournaments);
        if (active < AppConstants.freeActiveTournaments) return child;
        return const PaywallScreen();
      },
    );
  }
}
