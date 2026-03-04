import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cyber_glass_card.dart';
import 'cyber_button.dart';

class CyberDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;

  const CyberDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.onCancel,
    this.confirmText = "CONFIRM",
    this.cancelText = "CANCEL",
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    const bg = Color(0xFF0B0B0F);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: CyberGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, color: cyan, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              message.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                height: 1.6,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: CyberButton(
                    onPressed: onCancel ?? () => Navigator.pop(context),
                    text: cancelText,
                    color: Colors.transparent,
                    height: 45,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CyberButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    text: confirmText,
                    color: cyan,
                    height: 45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
