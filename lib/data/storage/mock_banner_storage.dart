import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/storage/banner_storage.dart';

/// In-memory [BannerStorage] backed by [MockStore.banners]: the mock app
/// and the tests render seeded/picked banners without any network.
class MockBannerStorage implements BannerStorage {
  MockBannerStorage([MockStore? store]) : _store = store ?? MockStore();

  final MockStore _store;

  @override
  Future<String> upload({
    required String tournamentId,
    required Uint8List bytes,
  }) async {
    final path = '$tournamentId/${_store.nextId('banner')}.jpg';
    // Same replace semantics as the Supabase impl: the tournament keeps a
    // single object, older uploads are dropped.
    _store.banners.removeWhere(
      (key, _) => key.startsWith('$tournamentId/') && key != path,
    );
    _store.banners[path] = bytes;
    _store.bump();
    return path;
  }

  @override
  Future<void> remove(String path) async {
    _store.banners.remove(path);
    _store.bump();
  }

  @override
  ImageProvider imageFor(String path) =>
      // A missing object (stale cache, deleted banner) yields undecodable
      // bytes on purpose: the Image's errorBuilder then renders the
      // neutral placeholder, mirroring the Supabase path's failed fetch.
      MemoryImage(_store.banners[path] ?? Uint8List(0));
}
