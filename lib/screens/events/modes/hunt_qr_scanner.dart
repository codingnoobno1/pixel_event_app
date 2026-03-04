import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/widgets.dart';

class HuntQrScanner extends ConsumerStatefulWidget {
  final Event event;
  final String participantId;

  const HuntQrScanner({
    super.key,
    required this.event,
    required this.participantId,
  });

  @override
  ConsumerState<HuntQrScanner> createState() => _HuntQrScannerState();
}

class _HuntQrScannerState extends ConsumerState<HuntQrScanner> {
  bool _isScanning = true;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onScan(BarcodeCapture capture) async {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith("pixel://hunt/")) {
        setState(() => _isScanning = false);
        _processCheckpoint(code);
        return;
      }
    }
  }

  Future<void> _processCheckpoint(String code) async {
    // Format: pixel://hunt/[eventId]/[checkpointId]
    final parts = code.replaceFirst("pixel://hunt/", "").split("/");
    if (parts.length < 2) {
      _showError("INVALID_TRANSMISSION_PROTOCOL");
      return;
    }

    final eventId = parts[0];
    final checkpointId = parts[1];

    if (eventId != widget.event.id) {
       _showError("ACCESS_DENIED: EVENT_MISMATCH");
       return;
    }

    try {
      final repo = ref.read(eventRepositoryProvider);
      // In a real app, this would call a scan endpoint
      // For now, we'll simulate the update
      await repo.updateEvent(widget.event.id, {
        "action": "scan_checkpoint",
        "participantId": widget.participantId,
        "checkpointId": checkpointId,
      });

      if (mounted) {
        Navigator.pop(context, {"id": checkpointId, "status": "verified"});
      }
    } catch (e) {
      _showError("UPLINK_FAILURE: ${e.toString().toUpperCase()}");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => CyberDialog(
        title: "SCAN_ERROR",
        message: message,
        onConfirm: () {
          Navigator.pop(context);
          setState(() => _isScanning = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onScan,
          ),
          
          // Tactical Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(borderColor: cyan),
            ),
          ),

          // Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "SCANNING_OPTICS_ACTIVE",
                  style: GoogleFonts.jetBrainsMono(
                    color: cyan,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: cameraController.torchState,
                    builder: (context, state, child) {
                      switch (state) {
                        case TorchState.off:
                          return const Icon(Icons.flash_off_rounded, color: Colors.white);
                        case TorchState.on:
                          return const Icon(Icons.flash_on_rounded, color: cyan);
                      }
                    },
                  ),
                  onPressed: () => cameraController.toggleTorch(),
                ),
              ],
            ),
          ),

          // Bottom Hint
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyan.withOpacity(0.3)),
              ),
              child: Text(
                "ALIGN_TACTICAL_QR_WITHIN_RETICLE",
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).shimmer(),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const scanAreaSize = 250.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw darkened background
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24))),
      ),
      paint,
    );

    // Draw corners
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerLength = 30.0;
    const radius = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize - radius, top)
        ..arcToPoint(Offset(left + scanAreaSize, top + radius), radius: const Radius.circular(radius))
        ..lineTo(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize - radius)
        ..arcToPoint(Offset(left + radius, top + scanAreaSize), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
        ..lineTo(left + scanAreaSize - radius, top + scanAreaSize)
        ..arcToPoint(Offset(left + scanAreaSize, top + scanAreaSize - radius), radius: const Radius.circular(radius))
        ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    // Animated Scan Line (Simulation)
    final linePaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..strokeWidth = 2;
    
    // We can't easily animate here without a controller, but we can draw a static highlight
    canvas.drawLine(
      Offset(left + 10, top + 10),
      Offset(left + scanAreaSize - 10, top + 10),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const CyberDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: CyberGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(color: cyan, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            CyberButton(
              onPressed: onConfirm,
              text: "ACKNOWLEDGE",
              color: cyan,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
