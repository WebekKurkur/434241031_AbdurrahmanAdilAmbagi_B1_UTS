// lib/presentation/widgets/fullscreen_image_viewer.dart

import 'package:flutter/material.dart';

/// Builds a `PageRoute` for the fullscreen image viewer. Use
/// this instead of `MaterialPageRoute` so we can use a fade
/// transition + a black barrier (matches the iOS image-viewer
/// pattern).
PageRouteBuilder<void> fullscreenImageRoute({
  required ImageProvider imageProvider,
  required String fileName,
}) {
  return PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => _FullscreenImageViewer(
      imageProvider: imageProvider,
      fileName: fileName,
    ),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _FullscreenImageViewer extends StatelessWidget {
  final ImageProvider imageProvider;
  final String fileName;
  const _FullscreenImageViewer({
    required this.imageProvider,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Pinch-to-zoom + pan. minScale 1 = no zoom-out past
            // the natural fit; maxScale 4 = aggressive zoom.
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button (top-right) — 36×36 white-on-black
            // circular chip, 12px from edges.
            Positioned(
              top: 12,
              right: 12,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Filename chip (bottom-center) — 12px h-padding,
            // 6px v-padding, 6px radius, black 55% alpha,
            // white text. Mirrors the in-page preview chip.
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
