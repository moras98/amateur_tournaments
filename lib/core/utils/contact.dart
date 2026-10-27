import 'package:tande/models/contact_channel.dart';
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

/// Opens an Instagram profile. The handle is bare (`club_atletico`); the web
/// URL is what both platforms resolve to the installed app.
Future<bool> openInstagram(String handle) async {
  final clean = normalizeInstagram(handle);
  if (clean.isEmpty) return false;
  return _launchExternal(Uri.parse('https://instagram.com/$clean'));
}

/// Opens a Telegram chat. Same story: `t.me` is a universal link.
Future<bool> openTelegram(String handle) async {
  final clean = normalizeTelegram(handle);
  if (clean.isEmpty) return false;
  return _launchExternal(Uri.parse('https://t.me/$clean'));
}

/// Opens any absolute URL (a Google Form, a club site, a spreadsheet).
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || uri.scheme != 'https') return false;
  return _launchExternal(uri);
}

/// Opens whatever [channel] is, with an optional pre-filled message where the
/// channel supports one (only WhatsApp does).
Future<bool> openContactChannel(ContactChannel channel, {String message = ''}) {
  return switch (channel.kind) {
    ContactKind.whatsapp => openWhatsApp(
      phone: channel.target,
      message: message,
    ),
    ContactKind.call => openDialer(channel.target),
    ContactKind.instagram => openInstagram(channel.target),
    ContactKind.telegram => openTelegram(channel.target),
    ContactKind.link => openLink(channel.target),
  };
}

/// Accepts `@club`, `club`, `instagram.com/club` or the full profile URL and
/// returns the bare handle, because organizers paste all four.
String normalizeInstagram(String raw) =>
    _bareHandle(raw, hosts: const ['instagram.com', 'www.instagram.com']);

/// Accepts `@club`, `club`, `t.me/club` or `telegram.me/club`.
String normalizeTelegram(String raw) =>
    _bareHandle(raw, hosts: const ['t.me', 'telegram.me', 'www.t.me']);

/// Accepts anything without a scheme and makes it `https://`. Returns an empty
/// string for blank input so callers can treat "not set" and "empty" alike.
String normalizeContactUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

String _bareHandle(String raw, {required List<String> hosts}) {
  var value = raw.trim();
  if (value.isEmpty) return '';
  value = value.replaceFirst(RegExp(r'^https?://'), '');
  for (final host in hosts) {
    if (value.toLowerCase().startsWith('$host/')) {
      value = value.substring(host.length + 1);
      break;
    }
  }
  value = value.split('?').first.split('#').first;
  value = value.replaceAll(RegExp(r'/+$'), '');
  value = value.replaceFirst(RegExp(r'^@'), '');
  // A handle is one path segment: anything deeper is not a profile.
  return value.split('/').first;
}

Future<bool> _launchExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
