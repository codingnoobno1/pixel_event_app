import 'package:flutter/material.dart';

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
    const pink = Color(0xFFFF2E88);
    final accentColor = color ?? pink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type == CyberBadgeType.filled
            ? accentColor
            : type == CyberBadgeType.glow
                ? accentColor.withOpacity(0.15)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: type != CyberBadgeType.filled
            ? Border.all(color: accentColor, width: 1)
            : null,
        boxShadow: type == CyberBadgeType.glow
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 8,
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
              size: 12,
              color: type == CyberBadgeType.filled ? Colors.white : accentColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: type == CyberBadgeType.filled ? Colors.white : accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
