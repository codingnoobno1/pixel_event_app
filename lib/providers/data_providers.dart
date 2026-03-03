import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// Data providers
/// These providers fetch and manage app data

// Events Provider (with auto-dispose)
// Fetches all events
final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getEvents();
});

// Upcoming Events Provider
final upcomingEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getUpcomingEvents();
});

// Past Events Provider
final pastEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getPastEvents();
});

// Event Detail Provider (family provider for specific event)
final eventDetailProvider = FutureProvider.autoDispose.family<Event, String>((ref, eventId) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getEventById(eventId);
});

// Event Participants Provider (family provider)
final eventParticipantsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, eventId) async {
    final eventRepository = ref.watch(eventRepositoryProvider);
    return await eventRepository.getEventParticipants(eventId);
  },
);

// My Registrations Provider
// Fetches current user's registrations
final myRegistrationsProvider = FutureProvider.autoDispose<List<Registration>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return [];
      return await eventRepository.getMyRegistrations(user.email);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Event Pass Provider (family provider)
final eventPassProvider = FutureProvider.autoDispose.family<EventPass, Map<String, String>>(
  (ref, params) async {
    final eventRepository = ref.watch(eventRepositoryProvider);
    return await eventRepository.getEventPass(params['email']!, params['eventId']!);
  },
);

// Event Attendance Provider (family provider)
final eventAttendanceProvider = FutureProvider.autoDispose.family<List<AttendanceRecord>, String>(
  (ref, eventId) async {
    final attendanceRepository = ref.watch(attendanceRepositoryProvider);
    return await attendanceRepository.getEventAttendance(eventId: eventId);
  },
);

// Attendance Stats Provider (family provider)
final attendanceStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, eventId) async {
    final attendanceRepository = ref.watch(attendanceRepositoryProvider);
    return await attendanceRepository.getAttendanceStats(eventId);
  },
);

// User Attendance History Provider
final userAttendanceHistoryProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final attendanceRepository = ref.watch(attendanceRepositoryProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return [];
      return await attendanceRepository.getUserAttendanceHistory(user.uuid);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
