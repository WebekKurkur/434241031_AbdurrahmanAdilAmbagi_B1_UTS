// lib/domain/usecases/ticket/upload_ticket_image_usecase.dart
//
// Single-purpose use case: upload a photo for a (future) ticket and
// return the public URL. The screen calls this *before* the ticket
// is created, so the "Kirim" button can show "Mengunggah foto…"
// progress. If the upload fails, the screen can offer a retry
// without rolling back the ticket.

import 'dart:typed_data';

import '../../repositories/ticket_repository.dart';
import '../../../core/usecases/usecase.dart';

class UploadTicketImageParams {
  /// Raw image bytes from `image_picker`.
  final Uint8List bytes;

  /// Original file name from the picker (e.g. `photo.jpg`). Used
  /// to derive the file extension; not used as the Storage path.
  final String fileName;

  /// Per-ticket folder name. Most callers pass the ticket's
  /// public `ticket_code` (e.g. `TKT-91595`); if the ticket hasn't
  /// been created yet, pass a `uuid` or a timestamp instead.
  final String subdir;

  const UploadTicketImageParams({
    required this.bytes,
    required this.fileName,
    required this.subdir,
  });
}

class UploadTicketImageUseCase
    implements UseCase<String, UploadTicketImageParams> {
  final TicketRepository repository;

  UploadTicketImageUseCase(this.repository);

  @override
  Future<String> call(UploadTicketImageParams params) async {
    return await repository.uploadTicketImage(
      bytes: params.bytes,
      fileName: params.fileName,
      subdir: params.subdir,
    );
  }
}
