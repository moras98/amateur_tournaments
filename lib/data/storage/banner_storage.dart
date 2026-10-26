import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage bucket holding the optional organizer-uploaded tournament
/// banners (migration 0010). Public read — banners advertise public
/// events; the write policies check the uploader owns the tournament whose
/// id is the object's folder name.
const tournamentBannerBucket = 'tournament-banners';

/// Reads and writes the optional per-tournament banner image.
///
/// Supabase implementation: `SupabaseBannerStorage`;
/// mock: `MockBannerStorage`.
abstract class BannerStorage {
  /// Stores [bytes] as a new banner for [tournamentId] and returns the
  /// object path to save in `TournamentModel.bannerPath`. Any previous
  /// banner is replaced.
  Future<String> upload({
    required String tournamentId,
    required Uint8List bytes,
  });

  /// Deletes the object at [path]; a missing object is not an error.
  Future<void> remove(String path);

  /// Resolves a stored path into something [Image] can render.
  ImageProvider imageFor(String path);
}

/// Supabase Storage-backed banners.
///
/// Paths are `{tournamentId}/{millis}.jpg` — a fresh name per upload, so a
/// re-uploaded banner is a new URL and can never be served from the image
/// cache; the previous objects are dropped once the new upload landed.
class SupabaseBannerStorage implements BannerStorage {
  SupabaseBannerStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<String> upload({
    required String tournamentId,
    required Uint8List bytes,
  }) async {
    final path = '$tournamentId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage
        .from(tournamentBannerBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    // Cleanup is best-effort and runs *after* the new upload succeeded: a
    // leftover object costs a few bytes, a thrown error here would fail a
    // save that already went through.
    await _removeFolder(tournamentId, keep: path);
    return path;
  }

  Future<void> _removeFolder(String tournamentId, {String? keep}) async {
    try {
      final entries = await _client.storage
          .from(tournamentBannerBucket)
          .list(path: tournamentId);
      final stale = [
        for (final entry in entries)
          if (entry.name != keep) '$tournamentId/${entry.name}',
      ];
      if (stale.isNotEmpty) {
        await _client.storage.from(tournamentBannerBucket).remove(stale);
      }
    } catch (_) {
      // Best-effort cleanup (see [upload]).
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await _client.storage.from(tournamentBannerBucket).remove([path]);
    } catch (_) {
      // Best-effort cleanup: the row no longer points at the object, so a
      // failed delete only leaves an orphaned file.
    }
  }

  @override
  ImageProvider imageFor(String path) => NetworkImage(
    _client.storage.from(tournamentBannerBucket).getPublicUrl(path),
  );
}
