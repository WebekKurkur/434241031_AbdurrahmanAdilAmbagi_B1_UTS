// lib/core/network/storage_helper.dart
//
// Helpers for uploading images to the `attachments` Supabase Storage
// bucket and retrieving their public URLs.

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_providers.dart';

class StorageHelper {
  final SupabaseClient _client;
  StorageHelper(this._client);

  /// Upload [bytes] to `tickets/<random>.jpg` and return the public URL.
  Future<String> uploadImage(Uint8List bytes, {String folder = 'tickets'}) async {
    final ext = 'jpg';
    final fileName =
        '$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('attachments').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    return _client.storage.from('attachments').getPublicUrl(fileName);
  }

  /// Delete a file by its public URL.
  Future<void> deleteByUrl(String publicUrl) async {
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final idx = segments.indexOf('attachments');
    if (idx == -1 || idx == segments.length - 1) return;
    final path = segments.sublist(idx + 1).join('/');
    await _client.storage.from('attachments').remove([path]);
  }
}

final storageHelperProvider = Provider<StorageHelper>((ref) {
  return StorageHelper(ref.watch(supabaseClientProvider));
});
