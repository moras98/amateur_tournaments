import 'dart:async';

import 'package:tande/data/billing/billing_service.dart';

/// Fake [BillingService] for tests and non-release builds.
///
/// The defaults model a pre-launch app: no products in Play Console, so
/// everything stays free and ungated. Tests inject products and
/// `pro: false` to exercise paying mode.
class MockBillingService implements BillingService {
  MockBillingService({List<ProProduct> products = const [], this.pro = true})
    : _products = List.of(products);

  final List<ProProduct> _products;

  /// The fixed entitlement (see [isPro]).
  bool pro;

  final _changes = StreamController<void>.broadcast();

  @override
  List<ProProduct> get products => List.unmodifiable(_products);

  @override
  bool get isPro => pro;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> refresh() async {
    // State is fixed at construction — nothing to query.
  }

  @override
  Future<bool> buy(ProProduct product) async {
    if (!_products.any((p) => p.id == product.id)) return false;
    pro = true;
    _changes.add(null);
    return true;
  }

  @override
  Future<bool> restore() async => pro;
}
