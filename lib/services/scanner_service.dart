import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

/// Service for QR code scanning using device camera
/// Handles camera permissions and scan stream
class ScannerService {
  // Stream controller for scan results
  final _scanController = StreamController<String>.broadcast();

  // Current scanning state
  bool _isScanning = false;

  /// Stream of scanned QR code data
  Stream<String> get scanStream => _scanController.stream;

  /// Check if currently scanning
  bool get isScanning => _isScanning;

  /// Check camera permission status
  Future<PermissionStatus> checkCameraPermission() async {
    return await Permission.camera.status;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await checkCameraPermission();
    return status.isGranted;
  }

  /// Start scanning
  /// Returns true if scanning started successfully
  Future<bool> startScanning() async {
    if (_isScanning) {
      return true; // Already scanning
    }

    // Check permission
    final hasPermission = await hasCameraPermission();
    if (!hasPermission) {
      final granted = await requestCameraPermission();
      if (!granted) {
        throw ScannerException('Camera permission denied');
      }
    }

    _isScanning = true;
    return true;
  }

  /// Stop scanning
  void stopScanning() {
    _isScanning = false;
  }

  /// Process scanned barcode data
  /// This method should be called from the mobile_scanner widget
  void onBarcodeDetected(String data) {
    if (_isScanning && !_scanController.isClosed) {
      _scanController.add(data);
    }
  }

  /// Handle camera error
  void onCameraError(Object error) {
    if (!_scanController.isClosed) {
      _scanController.addError(ScannerException('Camera error: $error'));
    }
  }

  /// Dispose resources
  void dispose() {
    _isScanning = false;
    _scanController.close();
  }

  /// Open app settings (for permission management)
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check if camera is available on device
  Future<bool> isCameraAvailable() async {
    try {
      // This is a simple check - actual availability is determined by mobile_scanner
      final status = await checkCameraPermission();
      return status != PermissionStatus.permanentlyDenied;
    } catch (e) {
      return false;
    }
  }
}

/// Exception thrown when scanner operations fail
class ScannerException implements Exception {
  final String message;

  ScannerException(this.message);

  @override
  String toString() => 'ScannerException: $message';
}
