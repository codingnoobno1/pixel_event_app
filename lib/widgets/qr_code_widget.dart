import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cyber_card.dart';

/// Cyber-themed QR code widget
class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final String? label;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cyan.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 0,
              )
            ],
            border: Border.all(color: cyan.withOpacity(0.5), width: 1.5),
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            foregroundColor: Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            gapless: false,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(
            label!.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// QR code display card for event passes
class CyberQRPass extends StatelessWidget {
  final String data;
  final String title;
  final String? subtitle;

  const CyberQRPass({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);

    return CyberCard(
      color: cyan.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: cyan,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          QRCodeWidget(
            data: data,
            size: 180,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security_rounded, color: cyan, size: 14),
                const SizedBox(width: 8),
                Text(
                  "ENCRYPTED_PIXEL_PASS",
                  style: GoogleFonts.jetBrainsMono(
                    color: cyan.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
