import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/repositories.dart';
import 'service_providers.dart';

/// Repository providers
/// These providers create and manage repository instances

// Event Repository Provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventRepository(apiClient: apiClient);
});

// Attendance Repository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceRepository(apiClient: apiClient);
});
