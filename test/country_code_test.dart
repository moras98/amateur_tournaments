import 'package:bracket/core/utils/country_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('countryForIso', () {
    test('matches the ISO code case-insensitively', () {
      expect(countryForIso('ar')!.dial, '54');
      expect(countryForIso('UY')!.dial, '598');
      expect(countryForIso(' cl ')!.dial, '56');
    });

    test('returns null for empty and unlisted countries', () {
      expect(countryForIso(''), isNull);
      expect(countryForIso('jp'), isNull); // Curated list, not the world.
    });
  });

  group('splitIntlPhone', () {
    test('splits a stored Argentine number into dial + national', () {
      final split = splitIntlPhone('5491122334455');

      expect(split, isNotNull);
      expect(split!.dial, '54');
      expect(split.national, '91122334455');
    });

    test('prefers the longest dial code (three-digit over two-digit)', () {
      // Uruguay 598 must win over a hypothetical 59; Peru 51 is not 54.
      expect(splitIntlPhone('59829112345')!.dial, '598');
      expect(splitIntlPhone('5491155551234')!.dial, '54');
      expect(splitIntlPhone('51987654321')!.dial, '51');
      expect(splitIntlPhone('14155551234')!.dial, '1');
    });

    test('returns null for formats outside the table (lossless fallback)', () {
      // Legacy national input: no dial code fits (or, after a leading 1,
      // not the exact 10 NANP digits), so the digits stay untouched.
      expect(splitIntlPhone('1122334455'), isNull); // AR landline 11 2233-4455
      expect(splitIntlPhone('9112233445'), isNull); // AR mobile, no code
      expect(splitIntlPhone('8190123456'), isNull); // Japan: not in table.
      expect(splitIntlPhone('549'), isNull); // Too short to split.
      expect(splitIntlPhone(''), isNull);
    });

    test('rejoining dial + national reproduces the stored digits', () {
      for (final phone in [
        '5491122334455',
        '59829112345',
        '5511998765432',
        '14155551234',
        '541122334455',
      ]) {
        final split = splitIntlPhone(phone)!;
        expect(split.dial + split.national, phone);
      }
    });

    test('tolerates non-digit noise', () {
      final split = splitIntlPhone('+54 911 2233-4455');

      expect(split!.dial, '54');
      expect(split.national, '91122334455');
    });
  });

  test('the default country is Uruguay', () {
    expect(defaultCountryCode.dial, '598');
    expect(defaultCountryCode.dialLabel, '+598');
  });
}
