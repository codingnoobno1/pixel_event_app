import 'package:flutter/material.dart';

class CyberAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final bool isOnline;

  const CyberAvatar({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.borderColor,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2E88);
    final accentColor = borderColor ?? pink;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFF15151F),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: accentColor, size: size * 0.6)
                  : null,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: size * 0.25,
              width: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF9F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0B0B0F),
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
