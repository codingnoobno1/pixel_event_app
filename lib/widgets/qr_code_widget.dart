import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Reusable QR code widget with customization options
class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final bool showBorder;
  final String? label;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
    this.showBorder = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: showBorder
              ? BoxDecoration(
                  color: backgroundColor ?? Colors.white,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            foregroundColor: foregroundColor ?? Colors.black,
            backgroundColor: backgroundColor ?? Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            padding: const EdgeInsets.all(0),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// QR code display with save and share functionality
class QRCodeDisplay extends StatelessWidget {
  final String data;
  final String title;
  final String? subtitle;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const QRCodeDisplay({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            QRCodeWidget(
              data: data,
              size: 250,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onSave != null) ...[
                  OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.download),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                ],
                if (onShare != null)
                  ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
