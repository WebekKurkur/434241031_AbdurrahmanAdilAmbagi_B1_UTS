// lib/presentation/screens/create_ticket_screen.dart
//
// Form for creating a new ticket. The image field is backed by
// `image_picker` (camera or gallery) and uploads to the
// `attachments` Supabase Storage bucket via `StorageHelper`.
//
// Flow:
//   1. User picks a photo (camera or gallery) → `_pickedBytes`
//   2. User taps "Kirim Tiket" → upload use case runs first
//   3. If the upload succeeds, `addTicket` runs with the URL
//   4. If the upload fails, the user is asked to retry
//      (we don't submit a text-only ticket in that case so the
//      photo is never silently lost)

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/storage_helper.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/ticket/upload_ticket_image_usecase.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Hardware';

  // Image-picker state.
  // `_pickedBytes` is null until the user picks something.
  // `_pickedFileName` comes from the OS (`XFile.name`).
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _picking = false; // showing the OS camera/gallery sheet

  // Submit state.
  // `_uploading` is true while the photo is being pushed to
  // Supabase Storage; `_submitting` is true while the ticket row
  // is being created.
  bool _uploading = false;
  bool _submitting = false;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _categories = ['Hardware', 'Software', 'Network', 'General'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------- pickers

  Future<void> _pickFromCamera() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return; // user cancelled, silent
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = file.name;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickError('kamera', e);
    } catch (e) {
      if (!mounted) return;
      _showPickError('kamera', e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return; // user cancelled, silent
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = file.name;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickError('galeri', e);
    } catch (e) {
      if (!mounted) return;
      _showPickError('galeri', e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPickError(String source, Object e) {
    final code = e is PlatformException ? e.code : '';
    final msg = code.contains('denied') || code.contains('permanently')
        ? 'Akses $source ditolak. Buka Pengaturan → Aplikasi → Helpdesk → Izin.'
        : 'Gagal membuka $source: $e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearPicked() {
    setState(() {
      _pickedBytes = null;
      _pickedFileName = null;
    });
  }

  // --------------------------------------------------------- submit

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting || _uploading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    String? imageUrl;
    if (_pickedBytes != null) {
      setState(() => _uploading = true);
      // Use a temporary subdir until the ticket is created and
      // we have its real `ticket_code`. A short uuid-shaped
      // subdir keeps uploads isolated per submit.
      final subdir = 'pending-${DateTime.now().millisecondsSinceEpoch}';
      try {
        imageUrl = await ref.read(uploadTicketImageUseCaseProvider)(
              UploadTicketImageParams(
                bytes: _pickedBytes!,
                fileName: _pickedFileName ?? 'photo.jpg',
                subdir: subdir,
              ),
            );
      } on StorageUploadException catch (e) {
        if (!mounted) return;
        setState(() => _uploading = false);
        await _showUploadRetryDialog(e);
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _uploading = false);
        await _showUploadRetryDialog(
          const StorageUploadException('Upload gagal (unknown)'),
        );
        return;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }

    if (!mounted) return;
    setState(() => _submitting = true);
    final newTicket = TicketEntity(
      id:
          'TKT-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(3, '0')}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      createdBy: user.name,
      category: _selectedCategory,
      comments: [],
      imageUrl: imageUrl,
    );

    final created = await ref.read(addTicketUseCaseProvider)(newTicket);
    ref.invalidate(allTicketsProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(ticketStatsProvider);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _pickedBytes = null;
      _pickedFileName = null;
    });

    _showSuccessDialog(created);
  }

  Future<void> _showUploadRetryDialog(StorageUploadException e) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Upload foto gagal'),
        content: Text('${e.message}\n\nCoba unggah ulang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      await _submitTicket();
    }
  }

  void _showSuccessDialog(TicketEntity created) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.statusDone,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tiket Berhasil Dibuat!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${created.id}',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tim helpdesk akan segera menangani tiket Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              child: const Text('Lihat Tiket'),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    // Hard guard: only `user` role may create tickets. Admin and
    // helpdesk should never reach this screen, but if they do
    // (deep link, hot reload, race after sign-out) we block them
    // with a clear message rather than silently failing.
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buat Tiket Baru')),
        body: const Center(child: Text('Silakan login kembali')),
      );
    }
    if (user.role != UserRole.user) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buat Tiket Baru'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Hanya user yang dapat membuat tiket',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Anda login sebagai ${getRoleLabel(user.role)}. '
                  'Fitur ini dikhususkan untuk role User.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Web fallback: hide the camera button (no native camera on
    // laptop browsers). The gallery button still works via the
    // <input type="file"> shim that `image_picker` injects.
    final showCamera = !kIsWeb;

    final canSubmit = !_submitting && !_uploading && !_picking;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _SectionHeader(label: 'Judul Tiket', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Laptop tidak bisa menyala',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Judul tidak boleh kosong'
                  : null,
              maxLength: 100,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            // Category
            _SectionHeader(label: 'Kategori', isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? const Color(0xFF2D3F55)
                            : const Color(0xFFE8EDF5),
                  ),
                  backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                );
              }).toList(),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),

            // Description
            _SectionHeader(label: 'Deskripsi', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Jelaskan masalah yang Anda alami secara detail...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Deskripsi tidak boleh kosong'
                  : null,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // Attachment
            _SectionHeader(label: 'Lampiran (Opsional)', isDark: isDark),
            const SizedBox(height: 8),
            _buildAttachmentArea(isDark, showCamera)
                .animate()
                .fadeIn(delay: 250.ms),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submitTicket : null,
                icon: _submitting || _uploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _uploading
                      ? 'Mengunggah foto...'
                      : _submitting
                          ? 'Mengirim tiket...'
                          : 'Kirim Tiket',
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentArea(bool isDark, bool showCamera) {
    if (_pickedBytes != null) {
      // Preview of the picked image with a "remove" affordance.
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3F55) : const Color(0xFFE8EDF5),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(
                  _pickedBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // File-name pill (bottom-left)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image_outlined,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _pickedFileName ?? 'photo.jpg',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                    if (_pickedBytes != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${(int.parse((_pickedBytes!.length / 1024).toStringAsFixed(0)))} KB)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // "Remove" button (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _clearPicked,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
            // "Re-pick" overlay (small, bottom-right)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCamera)
                    _PillButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Kamera',
                      onTap: _picking ? null : _pickFromCamera,
                    ),
                  const SizedBox(width: 6),
                  _PillButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: _picking ? null : _pickFromGallery,
                  ),
                ],
              ),
            ),
            // Spinner while the OS sheet is open
            if (_picking)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Empty state: two CTAs (camera + gallery).
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3F55) : const Color(0xFFE8EDF5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Lampirkan foto (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'JPG atau PNG, maks 5 MB',
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (showCamera)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _picking ? null : _pickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Ambil Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (showCamera) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _picking ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (_picking) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Membuka...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PillButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
