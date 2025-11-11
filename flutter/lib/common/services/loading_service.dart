import 'package:flutter/material.dart';

/// A service that provides a global, modal loading overlay.
/// It uses Flutter's `Overlay` to draw on top of the entire application,
/// bypassing any local layout constraints.
class LoadingService {
  static OverlayEntry? _overlayEntry;

  /// Shows a fullscreen modal loading overlay with a customizable [text].
  static void show(BuildContext context, {String text = '正在加载...'}) {
    // Hide any existing overlay before showing a new one.
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material( // Using Material to ensure theming and text styles are applied correctly.
          color: Colors.black.withOpacity(0.5),
          child: WillPopScope(
            // Prevent the user from dismissing the loader with the back button.
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      text,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay into the widget tree.
    // We use the root navigator's overlay to ensure it's on top of everything.
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
    }
  }

  /// Hides the currently shown loading overlay.
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}