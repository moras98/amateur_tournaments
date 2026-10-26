import 'package:bracket/core/utils/country_code.dart';
import 'package:intl/intl.dart';

/// The app's Spanish locale: Uruguayan dates and the house money style.
const appLocale = 'es_UY';

/// Locale dates render in — follows the phone (set by the MaterialApp's
/// `localeResolutionCallback`): [appLocale] for any Spanish device,
/// `en_US` otherwise. Money always formats with [appLocale] (its dot
/// thousands and symbol-first style), whatever the event's currency —
/// only the symbol changes ("$ 25.000", "€ 25.000").
String activeLocale = appLocale;

/// Date and money formatting helpers.
///
/// Dates render in [activeLocale] (day/month names follow the app's
/// language); `main()` initializes the Spanish locale data and the
/// MaterialApp localization delegates keep Material widgets (pickers) in
/// the same language.
String formatEventDate(DateTime start, {DateTime? end}) {
  final startStr = DateFormat('EEE d MMM • HH:mm', activeLocale).format(start);
  if (end == null || _sameDay(start, end)) return startStr;
  return '$startStr – ${DateFormat('EEE d MMM • HH:mm', activeLocale).format(end)}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatTimeRange(DateTime start, DateTime end) =>
    '${DateFormat('HH:mm', activeLocale).format(start)} – '
    '${DateFormat('HH:mm', activeLocale).format(end)}';

/// A precise timestamp (request lists, audit-ish info).
String formatDateTime(DateTime value) =>
    DateFormat('d MMM yyyy • HH:mm', activeLocale).format(value);

/// Date-only label (e.g. the profile's birth date).
String formatDate(DateTime value) =>
    DateFormat('d MMM yyyy', activeLocale).format(value);

/// Display symbol per ISO 4217 code. The home market keeps the bare `$`
/// ("$ 25.000"); every other code carries a distinguishing prefix so the
/// dollar-family amounts don't blur together across borders (AR$, US$,
/// R$, MX$…). Codes outside the map render as the bare ISO code.
const currencySymbols = <String, String>{
  defaultCurrency: r'$',
  'ARS': r'AR$',
  'BOB': 'Bs',
  'BRL': r'R$',
  'CLP': r'CLP$',
  'COP': r'COL$',
  'EUR': '€',
  'USD': r'US$',
  'MXN': r'MX$',
  'PYG': '₲',
  'PEN': 'S/',
  'GBP': '£',
  'VES': 'Bs',
};

/// The symbol [currency] (ISO 4217, case-insensitive) renders with;
/// the bare code for anything unmapped.
String currencySymbol(String currency) {
  final code = currency.toUpperCase();
  return currencySymbols[code] ?? code;
}

/// Free events show [freeLabel] ("Gratis" / "Free"), otherwise an amount
/// in [currency] (ISO 4217, home market by default) in the house style —
/// symbol first, dot thousands, in every language: "$ 25.000" (UYU),
/// "€ 25.000" (EUR), "R$ 50.000" (BRL).
String formatCost(
  double amount, {
  required String freeLabel,
  String currency = defaultCurrency,
}) {
  if (amount <= 0) return freeLabel;
  final symbol = currencySymbol(currency);
  return NumberFormat.currency(
    // Money keeps this style regardless of the phone's language.
    locale: appLocale,
    symbol: symbol,
    decimalDigits: 0,
    // House style: "$ 25.000" (symbol first, dot thousands). `$` is not a
    // NumberFormat metacharacter, so any symbol composes into the pattern.
    customPattern: '$symbol #,##0',
  ).format(amount);
}

String formatDistanceKm(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
