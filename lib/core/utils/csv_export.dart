/// CSV export of a tournament's registrations (Tande Pro, feature 2).
///
/// The organizer lives in a spreadsheet: until now the only way to get the
/// list out of the app was copying names by hand. This builds a file the
/// phone can share to WhatsApp, Drive, mail or Excel.
///
/// Deliberate choices:
/// - **UTF-8 with BOM**: without it Excel mangles `ñ`, accents and `$`.
/// - **CRLF** line endings and RFC 4180 quoting: commas, quotes and newlines
///   inside a team name must not break the columns.
/// - **Comma separator**: if a Spanish-locale Excel opens everything in one
///   column, `Datos → Texto en columnas` fixes it; that is still better than
///   a `sep=,` header line, which other tools render as a bogus first row.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:tande/models/inscription_model.dart';

const csvBom = '\uFEFF';

/// Escapes one field per RFC 4180.
String csvField(String value) {
  final needsQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

/// Builds the CSV body for [inscriptions].
///
/// [statusLabel] and [dateFormat] are injected so the util stays free of
/// localization and locale globals — the screen passes the localized ones.
String buildInscriptionsCsv({
  required List<InscriptionModel> inscriptions,
  required String Function(InscriptionStatus status) statusLabel,
  required String Function(DateTime value) dateFormat,
}) {
  const header = [
    'Equipo',
    'Jugador',
    'Usuario',
    'Telefono',
    'Estado',
    'Solicitado',
    'Confirmado',
    'Nota',
  ];

  final rows = <String>[header.map(csvField).join(',')];
  for (final inscription in inscriptions) {
    final player = inscription.player;
    rows.add(
      [
        csvField(inscription.teamName),
        csvField(player?.fullName ?? ''),
        csvField(player?.username ?? ''),
        csvField(player?.phone ?? ''),
        csvField(statusLabel(inscription.status)),
        csvField(dateFormat(inscription.createdAt)),
        csvField(
          inscription.confirmedAt == null
              ? ''
              : dateFormat(inscription.confirmedAt!),
        ),
        csvField(inscription.note),
      ].join(','),
    );
  }
  return '$csvBom${rows.join('\r\n')}\r\n';
}

/// A filesystem-safe name: `tande-copa-centro-20261102.csv`.
String csvFileName({required String title, required DateTime now}) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final stamp =
      '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  return 'tande-${slug.isEmpty ? 'torneo' : slug}-$stamp.csv';
}

/// Opens the system share sheet with [csv] as a `.csv` attachment.
///
/// Returns `false` when the platform could not share (no share sheet, plugin
/// error) so the caller can show a message instead of failing silently.
Future<bool> shareCsv({
  required String fileName,
  required String csv,
  String? subject,
}) async {
  try {
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'text/csv', name: fileName),
        ],
        fileNameOverrides: [fileName],
        subject: subject,
      ),
    );
    return result.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}
