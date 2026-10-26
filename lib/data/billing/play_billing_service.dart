import 'dart:async';

import 'package:tande/core/constants.dart';
import 'package:tande/data/billing/billing_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Real [BillingService] backed by Google Play Billing.
///
/// Entitlement comes from Play itself (past purchases of our products):
/// there is no server verification yet — LAUNCH.md §7 tracks it as the
/// follow-up. Until products exist in Play Console [isPro] stays `true`,
/// so nothing gates (see the contract on [BillingService]).
class PlayBillingService implements BillingService {
  PlayBillingService({InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance {
    _purchaseSub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
  }

  final InAppPurchase _iap;
  // Kept referenced for the app's lifetime: cancelling would stop the
  // entitlement updates (there is no dispose — one service per process).
  // ignore: unused_field
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  final List<ProProduct> _products = [];
  final Map<String, ProductDetails> _details = {};
  final Set<String> _entitled = {};
  final _changes = StreamController<void>.broadcast();

  Completer<bool>? _pendingBuy;
  String? _pendingProductId;

  @override
  List<ProProduct> get products => List.unmodifiable(_products);

  @override
  bool get isPro => _products.isEmpty || _entitled.isNotEmpty;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> refresh() async {
    try {
      if (!await _iap.isAvailable()) return; // No Play here → stay free.
      final response = await _iap.queryProductDetails(
        AppConstants.proProductIds.toSet(),
      );
      _details
        ..clear()
        ..addEntries(response.productDetails.map((d) => MapEntry(d.id, d)));
      _products
        ..clear()
        ..addAll(
          (response.productDetails.map(_map).toList()
            ..sort((a, b) => _order(a).compareTo(_order(b)))),
        );
      // Past purchases arrive on the stream: kick a restore and give Play
      // a beat to deliver the batch before publishing the entitlement.
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      // Play flaking must never break the app: the defaults (free) stand.
    }
    _changes.add(null);
  }

  @override
  Future<bool> buy(ProProduct product) async {
    if (_pendingBuy != null) return false;
    final details = _details[product.id];
    if (details == null) return false;
    final completer = Completer<bool>();
    _pendingBuy = completer;
    _pendingProductId = product.id;
    try {
      final launched = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!launched) return false;
      // Resolved by [_onPurchases] — a canceled sheet counts as false.
      return await completer.future.timeout(const Duration(minutes: 2));
    } on TimeoutException {
      return false;
    } finally {
      _pendingBuy = null;
      _pendingProductId = null;
    }
  }

  @override
  Future<bool> restore() async {
    try {
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      // Same rule as refresh: never surface a Play failure.
    }
    _changes.add(null);
    return _entitled.isNotEmpty;
  }

  /// Monthly first on the paywall, yearly (and anything else) after.
  int _order(ProProduct product) =>
      product.id == AppConstants.proMonthlyId ? 0 : 1;

  ProProduct _map(ProductDetails details) => ProProduct(
    id: details.id,
    price: details.price,
    title: details.title,
    description: details.description,
  );

  void _onPurchases(List<PurchaseDetails> purchases) {
    var entitled = false;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _entitled.add(purchase.productID);
          entitled = true;
          // Android refunds unacknowledged purchases after 3 days.
          unawaited(_iap.completePurchase(purchase).catchError((_) {}));
          if (purchase.productID == _pendingProductId) {
            _finishPending(true);
          }
        case PurchaseStatus.canceled || PurchaseStatus.error:
          if (purchase.productID == _pendingProductId) {
            _finishPending(false);
          }
        case PurchaseStatus.pending:
          break;
      }
    }
    if (entitled) _changes.add(null);
  }

  void _finishPending(bool granted) {
    final completer = _pendingBuy;
    if (completer != null && !completer.isCompleted) {
      completer.complete(granted);
    }
  }
}
