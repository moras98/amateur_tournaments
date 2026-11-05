import 'package:tande/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// The legal links are opened from the sign-up form and the paywall, so a
/// broken URL is a store rejection. They must point at the published Pages
/// site (`docs/`), not at the repository files.
void main() {
  test('legal URLs point to the published docs site', () {
    final urls = [AppConstants.privacyUrl, AppConstants.termsUrl];
    for (final url in urls) {
      expect(url, startsWith('https://'));
      expect(url, startsWith(AppConstants.legalBaseUrl));
      expect(url, isNot(contains('github.com')));
      expect(url, endsWith('/'));
    }
    expect(AppConstants.privacyUrl, isNot(AppConstants.termsUrl));
  });
}
