import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with a pre-filled message.
///
/// [phone] must include the country code, digits only
/// (e.g. `5491122334455`) or with a leading `+`.
/// Returns `true` if the chat was opened.
Future<bool> openWhatsApp({
  required String phone,
  required String message,
}) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;

  final uri = Uri.parse(
    'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
  );
  return _launchExternal(uri);
}

/// Opens the phone dialer. Returns `true` if it was opened.
Future<bool> openDialer(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  return _launchExternal(Uri(scheme: 'tel', path: digits));
}

/// Opens the email composer. Returns `true` if it was opened.
Future<bool> openEmail({
  required String address,
  String subject = '',
  String body = '',
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: address,
    queryParameters: {
      if (subject.isNotEmpty) 'subject': subject,
      if (body.isNotEmpty) 'body': body,
    },
  );
  return _launchExternal(uri);
}

Future<bool> _launchExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
