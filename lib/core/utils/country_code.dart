/// A country's international calling code and market currency: pre-fills
/// the phone field on the profile form and the currency selector on the
/// event form.
///
/// The list is curated for this app's audience (Uruguay first, then the
/// rest of South/Central America and the usual extra destinations), not a
/// complete world table.
class CountryCode {
  const CountryCode({
    required this.iso,
    required this.dial,
    required this.name,
    required this.currency,
    this.exactNational,
  });

  /// ISO 3166-1 alpha-2 code, e.g. `UY`.
  final String iso;

  /// Digits dialled internationally, without `+`, e.g. `598`.
  final String dial;

  /// Spanish name, e.g. `Uruguay`.
  final String name;

  /// ISO 4217 currency of the country's market, e.g. `UYU` — the event
  /// form defaults to the device region's currency (audit 4.9).
  final String currency;

  /// Exact national length when the numbering plan fixes it (NANP: 10).
  /// Without it, legacy national inputs that merely start with `1`
  /// (`11 2233-4455`, `11 99876-5432`) would split as US numbers.
  final int? exactNational;

  /// Label for the closed country dropdown, e.g. `+598`.
  String get dialLabel => '+$dial';
}

/// The home market's ISO 4217 currency: default for new tournaments and
/// for rows written before the column existed (migration 0009).
const defaultCurrency = 'UYU';

/// The app's home market and the fallback when the device location is
/// unavailable (denied, offline, unrecognised country).
const defaultCountryCode = CountryCode(
  iso: 'UY',
  dial: '598',
  name: 'Uruguay',
  currency: defaultCurrency,
);

/// Dropdown entries: Uruguay first, then alphabetical by name.
const countryCodes = <CountryCode>[
  defaultCountryCode,
  CountryCode(iso: 'AR', dial: '54', name: 'Argentina', currency: 'ARS'),
  CountryCode(iso: 'BO', dial: '591', name: 'Bolivia', currency: 'BOB'),
  CountryCode(iso: 'BR', dial: '55', name: 'Brasil', currency: 'BRL'),
  CountryCode(iso: 'CL', dial: '56', name: 'Chile', currency: 'CLP'),
  CountryCode(iso: 'CO', dial: '57', name: 'Colombia', currency: 'COP'),
  // Dollarized: Ecuador's official currency is the US dollar.
  CountryCode(iso: 'EC', dial: '593', name: 'Ecuador', currency: 'USD'),
  CountryCode(iso: 'ES', dial: '34', name: 'España', currency: 'EUR'),
  CountryCode(
    iso: 'US',
    dial: '1',
    name: 'Estados Unidos',
    currency: 'USD',
    exactNational: 10,
  ),
  CountryCode(iso: 'FR', dial: '33', name: 'Francia', currency: 'EUR'),
  CountryCode(iso: 'IT', dial: '39', name: 'Italia', currency: 'EUR'),
  CountryCode(iso: 'MX', dial: '52', name: 'México', currency: 'MXN'),
  CountryCode(iso: 'PY', dial: '595', name: 'Paraguay', currency: 'PYG'),
  CountryCode(iso: 'PE', dial: '51', name: 'Perú', currency: 'PEN'),
  CountryCode(iso: 'PT', dial: '351', name: 'Portugal', currency: 'EUR'),
  CountryCode(iso: 'GB', dial: '44', name: 'Reino Unido', currency: 'GBP'),
  CountryCode(iso: 'VE', dial: '58', name: 'Venezuela', currency: 'VES'),
];

/// Every currency the app can price an event in — deduplicated across the
/// countries that share one (EUR, USD), home market first: the event
/// form's selector order.
final currencies = <String>{
  for (final country in countryCodes) country.currency,
}.toList();

/// The country for an ISO 3166-1 alpha-2 code (case-insensitive), or `null`
/// when it is not offered in [countryCodes].
CountryCode? countryForIso(String iso) {
  final needle = iso.trim().toUpperCase();
  if (needle.isEmpty) return null;
  for (final country in countryCodes) {
    if (country.iso == needle) return country;
  }
  return null;
}

/// Shortest national part a split may leave behind (guards degenerate
/// splits like `54` + `9`; real numbering plans are longer).
const _minNational = 4;

/// Splits a stored international phone number (digits only, e.g.
/// `5491122334455`) into dial code + national part.
///
/// Country calling codes are prefix-free by ITU design, so matching
/// longest-first is unambiguous. Rejoining `dial + national` always
/// reproduces the input digits, which keeps formats we cannot parse (a
/// country outside the table, a legacy national number) lossless on save.
({String dial, String national})? splitIntlPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < _minNational) return null;

  final byLongestDial = [...countryCodes]
    ..sort((a, b) => b.dial.length.compareTo(a.dial.length));
  for (final country in byLongestDial) {
    if (!digits.startsWith(country.dial)) continue;
    final national = digits.substring(country.dial.length);
    final lengthOk = country.exactNational == null
        ? national.length >= _minNational
        : national.length == country.exactNational;
    if (lengthOk) return (dial: country.dial, national: national);
  }
  return null;
}
