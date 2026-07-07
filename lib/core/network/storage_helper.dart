// lib/core/network/storage_helper.dart
//
// Helpers for uploading images to the `attachments` Supabase Storage
// bucket and retrieving their public URLs.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_providers.dart';

/// Thrown when an upload to the `attachments` bucket fails. Callers
/// can use [isPermissionDenied] to distinguish between "user denied
/// camera/gallery" and a real network / bucket error.
class StorageUploadException implements Exception {
  final String message;
  final Object? cause;
  const StorageUploadException(this.message, [this.cause]);

  bool get isPermissionDenied =>
      message.toLowerCase().contains('permission') ||
      message.toLowerCase().contains('denied');

  @override
  String toString() => 'StorageUploadException: $message';
}

class StorageHelper {
  final SupabaseClient _client;
  StorageHelper(this._client);

  /// Max allowed size for a single upload. 5 MB is enough for a
  /// 1600px-wide JPEG at quality 80 and well within Supabase's
  /// free-tier object limits.
  static const int maxBytes = 5 * 1024 * 1024;

  /// Upload [bytes] to the `attachments` bucket under
  /// `{folder}/{subdir}/{timestamp}.jpg` and return the public URL.
  ///
  /// [folder] defaults to `tickets`. [subdir] is typically the
  /// ticket code (e.g. `TKT-91595`) or the user's uuid, so each
  /// ticket's photos live in a predictable prefix (and are easy to
  /// clean up later).
  Future<String> uploadImage(
    Uint8List bytes, {
    String folder = 'tickets',
    String? subdir,
    String ext = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      throw const StorageUploadException('Image bytes are empty');
    }
    if (bytes.length > maxBytes) {
      throw StorageUploadException(
        'Foto terlalu besar '
        '(${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB, '
        'maks ${maxBytes ~/ 1024 ~/ 1024} MB)',
      );
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final segments = <String>[folder];
    if (subdir != null && subdir.isNotEmpty) segments.add(subdir);
    segments.add('$timestamp.$ext');
    final path = segments.join('/');
    debugPrint('[storage] uploading $path (${bytes.length} bytes)');
    try {
      await _client.storage.from('attachments').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );
      final url = _client.storage.from('attachments').getPublicUrl(path);
      debugPrint('[storage] uploaded $path -> $url');
      return url;
    } on StorageException catch (e) {
      debugPrint('[storage] upload FAILED: ${e.message}');
      throw StorageUploadException(e.message, e);
    } catch (e) {
      debugPrint('[storage] upload FAILED: $e');
      throw StorageUploadException('Upload gagal: $e', e);
    }
  }

  /// Delete a file by its public URL. Best-effort: if the URL
  /// doesn't look like an `attachments://` URL, this is a no-op.
  Future<void> deleteByUrl(String publicUrl) async {
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final idx = segments.indexOf('attachments');
    if (idx == -1 || idx == segments.length - 1) return;
    final path = segments.sublist(idx + 1).join('/');
    try {
      await _client.storage.from('attachments').remove([path]);
    } catch (e) {
      debugPrint('[storage] deleteByUrl FAILED: $e');
    }
  }
}

final storageHelperProvider = Provider<StorageHelper>((ref) {
  return StorageHelper(ref.watch(supabaseClientProvider));
});
