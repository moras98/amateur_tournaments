import 'package:bracket/core/utils/country_code.dart';
import 'package:bracket/core/utils/format.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Currency contract (audit 4.9): every tournament stores the ISO 4217
/// code it is charged in, the country table drives the event form's
/// default, and amounts render in the house style (symbol first, dot
/// thousands) with the right symbol per currency.
void main() {
  group('Country currency lookup', () {
    test('the home market and its fallback are UYU', () {
      expect(defaultCurrency, 'UYU');
      expect(defaultCountryCode.currency, 'UYU');
      expect(countryForIso('UY')!.currency, 'UYU');
      expect(countryForIso('uy')!.currency, 'UYU'); // case-insensitive
    });

    test('maps the table: euro zone, dollarized Ecuador, neighbours', () {
      expect(countryForIso('ES')!.currency, 'EUR');
      expect(countryForIso('PT')!.currency, 'EUR');
      expect(countryForIso('FR')!.currency, 'EUR');
      // Ecuador is dollarized: the market currency is the US dollar.
      expect(countryForIso('EC')!.currency, 'USD');
      expect(countryForIso('AR')!.currency, 'ARS');
      expect(countryForIso('BR')!.currency, 'BRL');
      expect(countryForIso('PY')!.currency, 'PYG');
      expect(countryForIso('GB')!.currency, 'GBP');
    });

    test('the selector list is deduplicated, home market first', () {
      expect(currencies, isNotEmpty);
      expect(currencies.first, defaultCurrency);
      // No repeats: EUR covers four countries but appears once.
      expect(currencies.toSet().length, currencies.length);
      expect(currencies.where((code) => code == 'EUR'), hasLength(1));
      expect(
        currencies,
        containsAll(<String>['UYU', 'ARS', 'BRL', 'EUR', 'USD']),
      );
    });
  });

  group('formatCost', () {
    test('the home market keeps the bare peso style', () {
      expect(formatCost(25000, freeLabel: 'Gratis'), r'$ 25.000');
      expect(
        formatCost(25000, freeLabel: 'Gratis', currency: 'UYU'),
        r'$ 25.000',
      );
    });

    test('every offered currency renders with its own symbol', () {
      expect(
        formatCost(25000, freeLabel: 'Gratis', currency: 'EUR'),
        '€ 25.000',
      );
      expect(
        formatCost(50000, freeLabel: 'Free', currency: 'BRL'),
        r'R$ 50.000',
      );
      expect(
        formatCost(4999, freeLabel: 'Free', currency: 'USD'),
        r'US$ 4.999',
      );
      expect(formatCost(100, freeLabel: 'Free', currency: 'ARS'), r'AR$ 100');
    });

    test('free events stay free in every currency', () {
      expect(formatCost(0, freeLabel: 'Gratis'), 'Gratis');
      expect(formatCost(0, freeLabel: 'Free', currency: 'EUR'), 'Free');
      expect(formatCost(-1, freeLabel: 'Gratis', currency: 'BRL'), 'Gratis');
    });

    test('an unknown code falls back to the bare ISO code', () {
      expect(currencySymbol('XXX'), 'XXX');
      expect(currencySymbol('xxx'), 'XXX'); // case-insensitive
      expect(formatCost(10, freeLabel: 'Free', currency: 'XXX'), 'XXX 10');
    });
  });

  group('TournamentModel.currency', () {
    test('defaults to the home market and round-trips through JSON', () {
      final tournament = TournamentModel(
        id: 't-1',
        ownerId: 'u-1',
        sport: 'football',
        title: 'Copa',
        startTime: DateTime(2026, 11, 1),
        endTime: DateTime(2026, 11, 2),
      );
      expect(tournament.currency, defaultCurrency);
      expect(tournament.toJson()['currency'], 'UYU');

      final euros = tournament.copyWith(currency: 'EUR');
      expect(euros.currency, 'EUR');
      expect(TournamentModel.fromJson(euros.toJson()).currency, 'EUR');

      // Rows written before the column existed (migration 0009) read as
      // the home market, never as null.
      final bare = Map<String, dynamic>.from(euros.toJson())
        ..remove('currency');
      expect(TournamentModel.fromJson(bare).currency, defaultCurrency);
    });
  });
}
