import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CyberLoading extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const CyberLoading({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2E88);
    const bg = Color(0xFF0B0B0F);

    final content = Column(
      mainAxisSize: MainAxisSize.min, // Use minimum space
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Ring
            Container(
              width: 70, // Slightly smaller
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: pink.withOpacity(0.1), width: 2),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds, curve: Curves.easeInOut)
             .fadeOut(duration: 1.seconds),

            // Spinning Indicator
            const SizedBox(
              width: 50, // Slightly smaller
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(pink),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .rotate(duration: 2.seconds),

            // Center Icon
            const Icon(Icons.bolt_rounded, color: pink, size: 24)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 800.ms),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 12), // Reduced spacing from 24 to 12
          Text(
            message!.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12, // Slightly smaller font
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .fadeIn(duration: 1.seconds),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: content),
      );
    }

    return content;
  }
}
