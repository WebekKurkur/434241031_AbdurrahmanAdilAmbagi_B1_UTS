// lib/presentation/screens/create_ticket_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
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
  bool _hasImage = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  final _categories = ['Hardware', 'Software', 'Network', 'General'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }
    final newTicket = TicketEntity(
      id: 'TKT-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(3, '0')}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      createdBy: user.name,
      category: _selectedCategory,
      comments: [],
      imageUrl: _hasImage ? 'https://picsum.photos/seed/${DateTime.now().millisecond}/400/300' : null,
    );

    final created = await ref.read(addTicketUseCaseProvider)(newTicket);
    ref.invalidate(allTicketsProvider);
    ref.invalidate(userTicketsProvider);
    ref.invalidate(ticketStatsProvider);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show success
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
                const Icon(Icons.lock_outline_rounded, size: 56, color: Colors.grey),
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
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
            GestureDetector(
              onTap: () => setState(() => _hasImage = !_hasImage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: _hasImage ? 160 : 100,
                decoration: BoxDecoration(
                  color: _hasImage
                      ? AppColors.statusDoneBg
                      : isDark
                          ? AppColors.cardDark
                          : const Color(0xFFF1F5FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasImage
                        ? AppColors.statusDone
                        : isDark
                            ? const Color(0xFF2D3F55)
                            : const Color(0xFFE8EDF5),
                    style: _hasImage ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                child: _hasImage
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://picsum.photos/seed/attach/400/200',
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _hasImage = false),
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
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.image_outlined,
                                      color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('preview_image.jpg',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 28,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk upload foto/file',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            'JPG, PNG, PDF (maks. 10MB)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFB0BAC9),
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitTicket,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Tiket'),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 40),
          ],
        ),
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
