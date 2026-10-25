import 'package:intl/intl.dart';

/// The app's Spanish locale: Uruguayan dates and the ARS money style.
const appLocale = 'es_UY';

/// Locale dates render in — follows the phone (set by the MaterialApp's
/// `localeResolutionCallback`): [appLocale] for any Spanish device,
/// `en_US` otherwise. Money always formats with [appLocale]: amounts are
/// always Uruguayan pesos ("$ 25.000") in every language.
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

/// Free events show [freeLabel] ("Gratis" / "Free"), otherwise an ARS
/// amount ("$ 25.000").
String formatCost(double amount, {required String freeLabel}) {
  if (amount <= 0) return freeLabel;
  return NumberFormat.currency(
    // Money stays Uruguayan-styled in every language.
    locale: appLocale,
    symbol: r'$',
    decimalDigits: 0,
    // Uruguayan style: "$ 25.000" (symbol first, dot thousands).
    customPattern: r'$ #,##0',
  ).format(amount);
}

String formatDistanceKm(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
