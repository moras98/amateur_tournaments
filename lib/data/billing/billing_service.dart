/// A purchasable Bracket Pro plan, as shown on the paywall.
///
/// Play's formatted price is carried verbatim — the store decides the
/// currency and locale for the buyer.
class ProProduct {
  const ProProduct({
    required this.id,
    required this.price,
    this.title = '',
    this.description = '',
  });

  /// Play Console product id (`AppConstants.proMonthlyId` /
  /// `AppConstants.proYearlyId`).
  final String id;

  /// Formatted price ("US$ 4.99"), straight from Play.
  final String price;

  final String title;
  final String description;
}

/// Subscription plumbing behind Bracket Pro (LAUNCH.md §7).
///
/// Entitlement contract: [isPro] starts `true` and only becomes a real
/// gate once Play reports configured products — an app without products
/// in Play Console must never block anyone (closed testers, dev builds,
/// tests).
abstract class BillingService {
  /// The plans Play offers here. Empty = paying mode off.
  List<ProProduct> get products;

  /// Whether this buyer may use the Pro features.
  bool get isPro;

  /// Fires after [products]/[isPro] change (purchase, restore).
  Stream<void> get changes;

  /// Queries Play for products and entitlement. Never throws.
  Future<void> refresh();

  /// Launches the Play purchase flow; `true` once it completes and the
  /// entitlement was granted.
  Future<bool> buy(ProProduct product);

  /// Re-checks past purchases; `true` when an entitlement was restored.
  Future<bool> restore();
}
