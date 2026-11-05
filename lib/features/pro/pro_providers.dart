import 'dart:async';

import 'package:tande/core/observability/analytics.dart';
import 'package:tande/data/billing/billing_service.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paywall + entitlement state.
///
/// [available] is paying mode: Play reports our products configured (see
/// `AppConstants.proProductIds`). Before that the app is free and ungated.
class ProState {
  const ProState({
    required this.products,
    required this.isPro,
    this.busy = false,
  });

  final List<ProProduct> products;
  final bool isPro;

  /// True while a purchase/restore flow is running.
  final bool busy;

  /// Play has the products configured — paying mode is on.
  bool get available => products.isNotEmpty;
}

/// Owns the [BillingService] conversation: startup refresh, purchase and
/// restore flows. Entitlement itself lives in the service (Play is the
/// source of truth until server-side verification lands).
class ProController extends Notifier<ProState> {
  late final BillingService _billing;
  bool _alive = true;

  @override
  ProState build() {
    final billing = ref.read(billingServiceProvider);
    _billing = billing;
    ref.onDispose(() => _alive = false);
    final sub = billing.changes.listen((_) => _sync());
    ref.onDispose(sub.cancel);
    // Fire-and-forget: paying mode must never block the first frame, and
    // a failed refresh just keeps the free defaults.
    unawaited(_refreshQuietly());
    return ProState(products: billing.products, isPro: billing.isPro);
  }

  Future<void> _refreshQuietly() async {
    try {
      await _billing.refresh();
    } catch (_) {
      // BillingService promises never to throw; belt and braces anyway.
    }
    _sync();
  }

  void _sync() {
    if (!_alive) return;
    state = ProState(
      products: _billing.products,
      isPro: _billing.isPro,
      busy: state.busy,
    );
  }

  ProState _restingState({required bool busy}) =>
      ProState(products: _billing.products, isPro: _billing.isPro, busy: busy);

  /// Runs the Play purchase flow; `true` when Pro was granted.
  Future<bool> buy(ProProduct product) async {
    final analytics = ref.read(analyticsProvider)
      ..track('pro_purchase_started', {'product_id': product.id});
    state = _restingState(busy: true);
    try {
      final granted = await _billing.buy(product);
      analytics.track('pro_purchase_finished', {
        'product_id': product.id,
        'granted': granted,
      });
      return granted;
    } finally {
      if (_alive) state = _restingState(busy: false);
    }
  }

  /// Restores past purchases; `true` when an entitlement came back.
  Future<bool> restore() async {
    final analytics = ref.read(analyticsProvider);
    state = _restingState(busy: true);
    try {
      final granted = await _billing.restore();
      analytics.track('pro_restore', {'granted': granted});
      return granted;
    } finally {
      if (_alive) state = _restingState(busy: false);
    }
  }
}

final proProvider = NotifierProvider<ProController, ProState>(
  ProController.new,
);
