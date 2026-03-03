import 'package:flutter/material.dart';
import 'cyber_button.dart';
import 'cyber_glass_card.dart';
import 'cyber_badge.dart';

/// Cyber-themed Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    this.title = 'SYSTEM ERROR',
    required this.message,
    this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'SYSTEM ERROR',
    required String message,
    VoidCallback? onRetry,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2E88);
    const bg = Color(0xFF0B0B0F);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Material(
          color: Colors.transparent,
          child: CyberGlassCard(
            color: Colors.redAccent,
            opacity: 0.15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.redAccent),
                ),
                const SizedBox(height: 20),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (onRetry != null) ...[
                      Expanded(
                        child: CyberButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onRetry!();
                          },
                          text: 'RETRY',
                          height: 45,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: CyberButton(
                        onPressed: () => Navigator.pop(context),
                        text: onRetry != null ? 'CANCEL' : 'DISMISS',
                        color: Colors.grey[800],
                        height: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cyber-themed Success dialog
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOk;

  const SuccessDialog({
    super.key,
    this.title = 'PROCESS COMPLETE',
    required this.message,
    this.onOk,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'PROCESS COMPLETE',
    required String message,
    VoidCallback? onOk,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => SuccessDialog(
        title: title,
        message: message,
        onOk: onOk,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00FF9F);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Material(
          color: Colors.transparent,
          child: CyberGlassCard(
            color: accent,
            opacity: 0.15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.1),
                    border: Border.all(color: accent.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 40, color: accent),
                ),
                const SizedBox(height: 20),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                CyberButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onOk?.call();
                  },
                  text: 'CONFIRM',
                  color: accent,
                  height: 45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
