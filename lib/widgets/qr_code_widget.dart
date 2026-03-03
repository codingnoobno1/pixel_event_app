import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    const pink = Color(0xFFFF2E88);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // QR needs white background for best scanning
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: pink.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: pink.withOpacity(0.5), width: 2),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
    const pink = Color(0xFFFF2E88);

    return CyberCard(
      color: pink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          QRCodeWidget(
            data: data,
            size: 200,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: pink.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              Text(
                "ENCRYPTED PIXEL PASS",
                style: TextStyle(
                  color: pink.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
