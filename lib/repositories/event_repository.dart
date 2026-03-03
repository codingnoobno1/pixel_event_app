import '../services/api_client.dart';
import '../models/models.dart';

/// Repository for event-related API operations
/// Handles fetching events, event details, registration, and participants
class EventRepository {
  final ApiClient _apiClient;

  EventRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get list of events with optional filters
  /// Supports search, date range, and tag filtering
  Future<List<Event>> getEvents({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      print('🌐 API REQUEST: GET /api/events with params: $queryParams');
      final response = await _apiClient.get(
        '/api/events',
        queryParameters: queryParams,
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}, Data length: ${response.data is List ? (response.data as List).length : "Not a list"}');

      // Validate response
      if (response.data is! List) {
        throw ApiException(
          message: 'Invalid response format: expected list of events',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final List<dynamic> data = response.data;
      return data.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch events: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get event by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await _apiClient.get('/api/events/$eventId');

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected event object',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return Event.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch event: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get participants for an event
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    try {
      final response = await _apiClient.get(
        '/api/participants',
        queryParameters: {'eventId': eventId},
      );

      // Validate response
      if (response.data is! List) {
        throw ApiException(
          message: 'Invalid response format: expected list of participants',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch participants: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Register for an event (solo or team)
  Future<Registration> registerForEvent({
    required String eventId,
    required RegistrationType type,
    required String name,
    required String email,
    String? enrollmentNumber,
    String? semester,
    String? teamName,
    List<TeamMember>? teamMembers,
  }) async {
    try {
      // Validate team registration data
      if (type == RegistrationType.team) {
        if (teamName == null || teamName.isEmpty) {
          throw ApiException(
            message: 'Team name is required for team registration',
            statusCode: null,
            type: ApiExceptionType.badRequest,
          );
        }
        if (teamMembers == null || teamMembers.isEmpty) {
          throw ApiException(
            message: 'Team members are required for team registration',
            statusCode: null,
            type: ApiExceptionType.badRequest,
          );
        }
        if (teamMembers.length > 5) {
          throw ApiException(
            message: 'Maximum 5 additional team members allowed (6 total including leader)',
            statusCode: null,
            type: ApiExceptionType.badRequest,
          );
        }
      }

      final Map<String, dynamic> requestData = {
        'eventId': eventId,
        'registrationType': type == RegistrationType.team ? 'team' : 'solo',
        'name': name,
        'email': email,
        'enrollmentNumber': enrollmentNumber ?? '',
        'semester': semester ?? '',
      };

      if (type == RegistrationType.team) {
        requestData['teamName'] = teamName;
        requestData['members'] = teamMembers!.map((m) => m.toJson()).toList();
      }

      print('🌐 API REQUEST: POST /api/events/register with data: $requestData');
      final response = await _apiClient.post(
        '/api/events/register',
        data: requestData,
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}');

      // Backend returns { message, teamId, data }
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected registration object',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final responseData = response.data as Map<String, dynamic>;
      final regData = responseData['data'] as Map<String, dynamic>;
      return Registration.fromJson(regData);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to register for event: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get user's registrations by email
  Future<List<Registration>> getMyRegistrations(String email) async {
    try {
      print('🌐 API REQUEST: GET /api/events/register?email=$email');
      final response = await _apiClient.get(
        '/api/events/register',
        queryParameters: {'email': email},
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}');

      // Backend returns { data: [...] }
      if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        final List<dynamic> data = mapData['data'] as List<dynamic>? ?? [];
        return data.map((json) => Registration.fromJson(json as Map<String, dynamic>)).toList();
      }

      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Registration.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch registrations: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Check if user is registered for an event
  Future<bool> isRegistered(String email, String eventId) async {
    try {
      print('🌐 API REQUEST: GET /api/events/register?email=$email&eventId=$eventId');
      final response = await _apiClient.get(
        '/api/events/register',
        queryParameters: {'email': email, 'eventId': eventId},
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}');

      if (response.data is Map) {
        return (response.data as Map<String, dynamic>)['registered'] == true;
      }
      return false;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to check registration: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get event pass for a user and event using the NEW flutter pass endpoint
  Future<EventPass> getEventPass(String email, String eventId) async {
    try {
      print('🌐 API REQUEST: GET /api/flutter/pass?email=$email&eventId=$eventId');
      final response = await _apiClient.get(
        '/api/flutter/pass',
        queryParameters: {
          'email': email,
          'eventId': eventId,
        },
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}');

      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected event pass object',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return EventPass.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch event pass: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get event mode configuration using the NEW flutter eventmode endpoint
  Future<EventMode> getEventMode(String eventId, EventModeType type) async {
    try {
      final modeSlug = type.name.toLowerCase();
      print('🌐 API REQUEST: GET /api/flutter/eventmode/$modeSlug?eventId=$eventId');
      final response = await _apiClient.get(
        '/api/flutter/eventmode/$modeSlug',
        queryParameters: {'eventId': eventId},
      );
      print('🌐 API RESPONSE: Status ${response.statusCode}');

      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return EventMode.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch event mode: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Cancel registration
  Future<void> cancelRegistration(String registrationId) async {
    try {
      await _apiClient.delete('/api/registration/$registrationId');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to cancel registration: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
    final now = DateTime.now();
    return getEvents(startDate: now);
  }

  /// Get past events
  Future<List<Event>> getPastEvents() async {
    final now = DateTime.now();
    return getEvents(endDate: now);
  }
}
