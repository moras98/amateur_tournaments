import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Picks the optional tournament banner (the event form's "Agregar
/// imagen" button). Injected through `bannerPickerProvider` so tests
/// never touch the platform image channel.
abstract class BannerPicker {
  /// Returns the picked image bytes, or `null` when the organizer
  /// cancelled.
  Future<Uint8List?> pick();
}

/// Gallery picker used by the app: downscales to 1600 px wide and
/// re-encodes as JPEG (~85 quality), so a 12 MP photo lands around a few
/// hundred KB instead of several MB — cheap to upload and to render in
/// Explore lists.
class GalleryBannerPicker implements BannerPicker {
  const GalleryBannerPicker();

  @override
  Future<Uint8List?> pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
