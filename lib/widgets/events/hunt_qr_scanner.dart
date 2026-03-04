import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../providers/providers.dart';

class HuntQrScanner extends ConsumerStatefulWidget {
  final Event event;
  final String participantId;
  final String? teamId;

  const HuntQrScanner({
    super.key,
    required this.event,
    required this.participantId,
    this.teamId,
  });

  @override
  ConsumerState<HuntQrScanner> createState() => _HuntQrScannerState();
}

class _HuntQrScannerState extends ConsumerState<HuntQrScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    // Format check: pixel://hunt/[eventId]/[checkpointId]
    if (!code.startsWith('pixel://hunt/')) {
      _showError('Invalid Treasure Hunt QR Code');
      return;
    }

    final parts = code.replaceFirst('pixel://hunt/', '').split('/');
    if (parts.length < 2) {
      _showError('Malformed QR Code');
      return;
    }

    final String scannedEventId = parts[0];
    final String checkpointId = parts[1];

    if (scannedEventId != widget.event.id) {
      _showError('This code is for a different event!');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final engine = ref.read(eventEngineServiceProvider);
      final result = await engine.scanCheckpoint(
        eventId: widget.event.id,
        checkpointId: checkpointId,
        participantId: widget.participantId,
        teamId: widget.teamId,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context, result['checkpoint']);
        }
      } else {
        _showError(result['error'] ?? 'Scan failed');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN CLUE'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        ],
      ),
    );
  }
}
