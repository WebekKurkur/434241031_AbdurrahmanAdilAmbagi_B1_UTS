// lib/presentation/screens/create_ticket_screen.dart
//
// Create ticket — Figma `8071:435` redesign (2026-06-24).
//
// Implements the Figma system documented in
// `ignore/redesign-main.md` + `ignore/redesign-auth.md`:
//   - frosted AppHeader 81 px
//   - `_InputShell` for Subject + Description
//   - `_CategoryDropdown` (modal bottom sheet of 4 category tiles)
//   - `_AttachmentDropzone` (dashed, 18 px radius)
//   - `_ActionBar` footer (Cancel outlined / Submit filled)
//
// Behaviour preserved from the legacy screen:
//   - addTicketUseCaseProvider to create the ticket
//   - uploadTicketImageUseCaseProvider for the (single) attachment
//   - provider invalidations on success
//   - role guard: only UserRole.user may reach this screen
//   - form validation (subject 1-100 / category required / desc 10-2000)
//   - spinner + disabled while uploading / submitting
//   - retry dialog on upload failure
//   - web fallback (camera hidden, gallery still works via file input)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/storage_helper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/ticket/add_ticket_usecase.dart';
import '../../domain/usecases/ticket/upload_ticket_image_usecase.dart';
import '../providers/auth_provider.dart';
import '../providers/paginated_tickets_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_theme.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const List<String> _categories = [
    'Hardware',
    'Software',
    'Network',
    'General',
  ];

  String? _selectedCategory;

  // The data model only supports one imageUrl per ticket, so we
  // keep a single attachment slot.
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _picking = false;

  // Submit state.
  bool _uploading = false;
  bool _submitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  String? _validateSubject(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Subject is required';
    if (t.length > 100) return 'Subject is too long (max 100 characters)';
    return null;
  }

  String? _validateDescription(String? v) {
    final t = v?.trim() ?? '';
    if (t.length < 10) {
      return 'Description is too short (at least 10 characters)';
    }
    if (t.length > 2000) {
      return 'Description is too long (max 2000 characters)';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------------------

  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB (Figma spec)

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
      if (file == null) return;
      await _acceptPicked(file);
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickError('camera', e);
    } catch (e) {
      if (!mounted) return;
      _showPickError('camera', e);
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
      if (file == null) return;
      await _acceptPicked(file);
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPickError('gallery', e);
    } catch (e) {
      if (!mounted) return;
      _showPickError('gallery', e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _acceptPicked(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File too large (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB). '
            'Maximum is 10 MB.',
          ),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _pickedFileName = file.name;
    });
  }

  void _showPickError(String source, Object e) {
    final code = e is PlatformException ? e.code : '';
    final msg = code.contains('denied') || code.contains('permanently')
        ? 'Access to $source denied. Open Settings to enable it.'
        : 'Failed to open $source: $e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.authError,
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

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting || _uploading || _picking) return;
    if (_selectedCategory == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    String? imageUrl;
    if (_pickedBytes != null) {
      setState(() => _uploading = true);
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
        await _showUploadRetryDialog(e);
        return;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }

    if (!mounted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(addTicketUseCaseProvider)(
        AddTicketParams(
          title: _subjectController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory!,
          imageUrl: imageUrl,
        ),
      );
      ref.invalidate(allTicketsProvider);
      ref.invalidate(userTicketsProvider);
      ref.invalidate(ticketStatsProvider);
      invalidateAllPaginatedProviders(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create ticket: $e'),
          backgroundColor: AppColors.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showUploadRetryDialog(Object error) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload failed'),
        content: Text(
          'We could not upload the attachment:\n\n$error\n\n'
          'Retry the upload?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) {
      await _submitTicket();
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New ticket')),
        body: const Center(child: Text('Please sign in again')),
      );
    }
    if (user.role != UserRole.user) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New ticket'),
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
                  'Only users can create tickets',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'You are signed in as ${getRoleLabel(user.role)}. '
                  'This feature is restricted to the User role.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showCamera = !kIsWeb;

    final canSubmit =
        !_submitting && !_uploading && !_picking && _selectedCategory != null;

    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18.75, 96, 18.75, 105),
                children: [
                  _Field(
                    label: 'Subject',
                    child: _InputShell(
                      controller: _subjectController,
                      hint: "Short summary, e.g. Laptop won't power on",
                      icon: Icons.edit_rounded,
                      validator: _validateSubject,
                      maxLines: 1,
                    ),
                  ),
                  _Field(
                    label: 'Category',
                    child: _CategoryDropdown(
                      value: _selectedCategory,
                      categories: _categories,
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                  _Field(
                    label: 'Description',
                    child: _InputShell(
                      controller: _descController,
                      hint:
                          "Tell us what happened, when it started, and what you've already tried…",
                      validator: _validateDescription,
                      maxLines: 6,
                    ),
                  ),
                  _Field(
                    label: 'Attachments',
                    child: _AttachmentDropzone(
                      bytes: _pickedBytes,
                      fileName: _pickedFileName,
                      picking: _picking,
                      uploading: _uploading,
                      showCamera: showCamera,
                      onPickCamera: _pickFromCamera,
                      onPickGallery: _pickFromGallery,
                      onClear: _clearPicked,
                    ),
                  ),
                ].animate(interval: 50.ms).fadeIn(),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _AppHeader(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _ActionBar(
                submitting: _submitting,
                uploading: _uploading,
                canSubmit: canSubmit,
                onCancel: () => Navigator.pop(context),
                onSubmit: _submitTicket,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppHeader — 81 px frosted
// ---------------------------------------------------------------------------

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,
      decoration: const BoxDecoration(
        color: Color(0xCCF5F7FA), // 80% #f5f7fa — frosted
        border: Border(
          bottom: BorderSide(color: AppColors.authBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.75),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 26.25,
              height: 33.75,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -7.5,
                    top: 0,
                    child: _IconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11.25),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'New ticket',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1115),
                      letterSpacing: -0.17,
                      height: 22.1 / 17,
                    ),
                  ),
                  Text(
                    'Describe your issue clearly',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 15.6 / 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
  const _IconButton({required this.icon, this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 33.75,
        height: 33.75,
        child: Icon(icon, size: 20, color: const Color(0xFF0F1115)),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ---------------------------------------------------------------------------
// Field wrapper — label + content
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.24,
              height: 16.8 / 12,
            ),
          ),
          const SizedBox(height: 5.625),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input shell — 18 px radius, 1 px border, optional icon
// ---------------------------------------------------------------------------

class _InputShell extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputShell({
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.25, vertical: 1),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF0F1115),
            height: 21 / 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0x800F1115),
            ),
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 11.25),
                    child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category dropdown — modal bottom sheet of 4 tiles
// ---------------------------------------------------------------------------

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final display = value ?? 'Select a category';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSheet(context),
      child: Container(
        height: 41.25,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.authBorder, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? const Color(0xFF0F1115)
                        : const Color(0x800F1115),
                    height: 21 / 14,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 12.25,
              top: 12.625,
              child: Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.authBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select category',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1115),
                      ),
                    ),
                  ),
                ),
                for (final cat in categories)
                  ListTile(
                    title: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: cat == value
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: cat == value
                            ? AppColors.authPrimary
                            : const Color(0xFF0F1115),
                      ),
                    ),
                    trailing: cat == value
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.authPrimary,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onChanged(cat);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Attachment dropzone — dashed, 18 px radius, real picker flow
// ---------------------------------------------------------------------------

class _AttachmentDropzone extends StatelessWidget {
  final Uint8List? bytes;
  final String? fileName;
  final bool picking;
  final bool uploading;
  final bool showCamera;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onClear;

  const _AttachmentDropzone({
    required this.bytes,
    required this.fileName,
    required this.picking,
    required this.uploading,
    required this.showCamera,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return _AttachmentPreview(
        bytes: bytes!,
        fileName: fileName ?? 'photo.jpg',
        onClear: onClear,
        uploading: uploading,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: picking
              ? null
              : () => _openSourceSheet(
                    context,
                    showCamera: showCamera,
                    onCamera: onPickCamera,
                    onGallery: onPickGallery,
                  ),
          child: DashedBorderContainer(
            radius: 18,
            color: AppColors.authBorder,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(height: 3.75),
                  Text(
                    'Click to attach files',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      height: 18.2 / 13,
                    ),
                  ),
                  Text(
                    'PNG, JPG, PDF up to 10MB',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      height: 15.4 / 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (picking || uploading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  void _openSourceSheet(
    BuildContext context, {
    required bool showCamera,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.authBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onCamera();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onGallery();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final bool uploading;
  final VoidCallback onClear;

  const _AttachmentPreview({
    required this.bytes,
    required this.fileName,
    required this.uploading,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.authBorder, width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: 11.25,
            bottom: 11.25,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${(bytes.length / 1024).toStringAsFixed(0)} KB)',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 11.25,
            top: 11.25,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: uploading ? null : onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          if (uploading)
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
}

// ---------------------------------------------------------------------------
// Dashed border container — Flutter has no built-in `border-dashed`,
// so we paint one as a CustomPainter.
// ---------------------------------------------------------------------------

class DashedBorderContainer extends StatelessWidget {
  final double radius;
  final Color color;
  final Widget child;

  const DashedBorderContainer({
    super.key,
    required this.radius,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: radius, color: color),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;
  final Color color;
  static const double _strokeWidth = 1;
  static const double _dashLength = 5;
  static const double _gapLength = 4;

  _DashedBorderPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + _dashLength;
        dashed.addPath(
          metric.extractPath(dist, next.clamp(0, metric.length)),
          Offset.zero,
        );
        dist = next + _gapLength;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Action bar — Cancel / Submit
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  final bool submitting;
  final bool uploading;
  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _ActionBar({
    required this.submitting,
    required this.uploading,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final busy = submitting || uploading;
    return Material(
      color: AppColors.authBg,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.authBg,
            border: Border(
              top: BorderSide(color: AppColors.authBorder, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18.75, 12.25, 18.75, 11.25),
          child: Row(
            children: [
              Expanded(
                child: _OutlineButton(
                  label: 'Cancel',
                  onTap: busy ? null : onCancel,
                ),
              ),
              const SizedBox(width: 7.5),
              Expanded(
                child: _FilledButton(
                  label: submitting
                      ? 'Submitting…'
                      : uploading
                          ? 'Uploading…'
                          : 'Submit ticket',
                  iconWidget: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : null,
                  onTap: canSubmit ? onSubmit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _OutlineButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 41.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.authBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F1115),
              height: 21 / 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final Widget? iconWidget;
  final VoidCallback? onTap;

  const _FilledButton({
    required this.label,
    this.iconWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.authPrimary
          : AppColors.authPrimary.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 41.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[
                iconWidget!,
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 21 / 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}