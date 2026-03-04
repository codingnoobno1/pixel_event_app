import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CyberBadgeType { filled, outline, glow }

class CyberBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final CyberBadgeType type;
  final IconData? icon;

  const CyberBadge({
    super.key,
    required this.label,
    this.color,
    this.type = CyberBadgeType.filled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    final accentColor = color ?? cyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type == CyberBadgeType.filled
            ? accentColor
            : type == CyberBadgeType.glow
                ? accentColor.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: type != CyberBadgeType.filled
            ? Border.all(color: accentColor.withOpacity(0.5), width: 1)
            : null,
        boxShadow: type == CyberBadgeType.glow
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 10,
              color: type == CyberBadgeType.filled ? Colors.black : accentColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: type == CyberBadgeType.filled ? Colors.black : accentColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
