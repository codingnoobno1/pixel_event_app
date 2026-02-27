import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/scanner_service.dart';
import '../repositories/attendance_repository.dart';
import 'service_providers.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// Scanner state and providers
/// Manages active scanner state and scan processing

// Scanner State
class ScannerState {
  final Event? activeEvent;
  final bool isScanning;
  final AttendanceRecord? lastScanResult;
  final int scanCount;
  final String? error;

  ScannerState({
    this.activeEvent,
    this.isScanning = false,
    this.lastScanResult,
    this.scanCount = 0,
    this.error,
  });

  ScannerState copyWith({
    Event? activeEvent,
    bool? isScanning,
    AttendanceRecord? lastScanResult,
    int? scanCount,
    String? error,
  }) {
    return ScannerState(
      activeEvent: activeEvent ?? this.activeEvent,
      isScanning: isScanning ?? this.isScanning,
      lastScanResult: lastScanResult ?? this.lastScanResult,
      scanCount: scanCount ?? this.scanCount,
      error: error,
    );
  }

  ScannerState clearError() {
    return ScannerState(
      activeEvent: activeEvent,
      isScanning: isScanning,
      lastScanResult: lastScanResult,
      scanCount: scanCount,
      error: null,
    );
  }
}

// Scanner State Notifier
class ScannerNotifier extends StateNotifier<ScannerState> {
  final ScannerService _scannerService;
  final AttendanceRepository _attendanceRepository;
  final String _scannedBy; // User ID of the scanner

  ScannerNotifier({
    required ScannerService scannerService,
    required AttendanceRepository attendanceRepository,
    required String scannedBy,
  })  : _scannerService = scannerService,
        _attendanceRepository = attendanceRepository,
        _scannedBy = scannedBy,
        super(ScannerState());

  /// Set active event for scanning
  void setActiveEvent(Event event) {
    state = ScannerState(
      activeEvent: event,
      isScanning: false,
      scanCount: 0,
    );
  }

  /// Clear active event
  void clearActiveEvent() {
    stopScanning();
    state = ScannerState();
  }

  /// Start scanning
  Future<void> startScanning() async {
    if (state.activeEvent == null) {
      state = state.copyWith(error: 'No active event selected');
      return;
    }

    try {
      final started = await _scannerService.startScanning();
      if (started) {
        state = state.copyWith(isScanning: true, error: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stop scanning
  void stopScanning() {
    _scannerService.stopScanning();
    state = state.copyWith(isScanning: false);
  }

  /// Process scanned QR code
  Future<void> processScan(String qrData) async {
    if (state.activeEvent == null) {
      state = state.copyWith(error: 'No active event selected');
      return;
    }

    if (!state.isScanning) {
      return; // Ignore scans when not actively scanning
    }

    try {
      // Call attendance repository to process scan
      final attendanceRecord = await _attendanceRepository.scanQRCode(
        qrData: qrData,
        eventId: state.activeEvent!.id,
        scannedBy: _scannedBy,
      );

      // Update state with scan result
      state = state.copyWith(
        lastScanResult: attendanceRecord,
        scanCount: state.scanCount + 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear last scan result
  void clearLastScanResult() {
    state = state.copyWith(lastScanResult: null, error: null);
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Reset scanner state
  void reset() {
    stopScanning();
    state = ScannerState();
  }
}

// Scanner State Provider
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final scannerService = ref.watch(scannerServiceProvider);
  final attendanceRepository = ref.watch(attendanceRepositoryProvider);
  
  // Get current user ID for scannedBy field
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.when(
    data: (user) => user?.uuid ?? 'unknown',
    loading: () => 'unknown',
    error: (_, __) => 'unknown',
  );

  return ScannerNotifier(
    scannerService: scannerService,
    attendanceRepository: attendanceRepository,
    scannedBy: userId,
  );
});

// Active Event Provider
final activeScannerEventProvider = Provider<Event?>((ref) {
  return ref.watch(scannerProvider).activeEvent;
});

// Is Scanning Provider
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(scannerProvider).isScanning;
});

// Last Scan Result Provider
final lastScanResultProvider = Provider<AttendanceRecord?>((ref) {
  return ref.watch(scannerProvider).lastScanResult;
});

// Scan Count Provider
final scanCountProvider = Provider<int>((ref) {
  return ref.watch(scannerProvider).scanCount;
});

// Scanner Error Provider
final scannerErrorProvider = Provider<String?>((ref) {
  return ref.watch(scannerProvider).error;
});
