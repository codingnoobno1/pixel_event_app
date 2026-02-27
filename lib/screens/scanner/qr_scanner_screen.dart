import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/models.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  Event? _selectedEvent;
  bool _isProcessing = false;
  int _scanCount = 0;
  String? _lastScanResult;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (_selectedEvent == null) {
      _showError('Please select an event first');
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScanResult) return;

    setState(() {
      _isProcessing = true;
      _lastScanResult = code;
    });

    try {
      // TODO: Process QR code with AttendanceRepository
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate scan result
      final isSuccess = true; // Replace with actual validation
      
      if (isSuccess) {
        _showScanSuccess();
        setState(() {
          _scanCount++;
        });
      } else {
        _showError('Invalid QR code');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
      
      // Reset last scan after 2 seconds to allow rescanning
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastScanResult = null;
          });
        }
      });
    }
  }

  void _showScanSuccess() {
    // Haptic feedback
    // TODO: Add vibration
    
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Scan Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Attendance recorded'),
            const SizedBox(height: 16),
            // TODO: Show participant details
            const Text('Name: John Doe'),
            const Text('Enrollment: 2021001'),
            const Text('Scan Type: Entry'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Scanning'),
          ),
        ],
      ),
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showError(String message) {
    // Haptic feedback
    // TODO: Add error vibration
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Selector
          if (_selectedEvent == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select an event to start scanning',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton(
                    onPressed: _showEventSelector,
                    child: const Text('Select Event'),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green[100],
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedEvent!.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedEvent!.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showEventSelector,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),

          // Scan Count
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Scans Today', '$_scanCount'),
                _buildStatCard('Status', _isProcessing ? 'Processing...' : 'Ready'),
              ],
            ),
          ),

          // Camera Preview
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                ),
                
                // Scanning overlay
                CustomPaint(
                  painter: ScannerOverlayPainter(),
                  child: Container(),
                ),

                // Processing indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // Instructions
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Position QR code within the frame',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual Entry Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Show manual entry dialog
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manual Entry'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showEventSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Active Event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // TODO: Load actual events
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Sample Event'),
                subtitle: const Text('Main Hall'),
                onTap: () {
                  setState(() {
                    // TODO: Set actual event
                    _selectedEvent = null; // Replace with actual event
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    // Draw overlay with transparent center
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
          ..close(),
      ),
      paint,
    );

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bracketLength = 30.0;

    // Top-left
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, bracketLength),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -bracketLength),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-bracketLength, 0),
      bracketPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
