import '../services/api_client.dart';
import '../models/models.dart';

/// Repository for attendance-related API operations
/// Handles QR scanning, attendance tracking, manual overrides, and exports
class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Scan QR code and record attendance
  /// Returns attendance record with entry/exit information
  Future<AttendanceRecord> scanQRCode({
    required String qrData,
    required String eventId,
    required String scannedBy,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/attendance/scan',
        data: {
          'qrData': qrData,
          'eventId': eventId,
          'scannedBy': scannedBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected attendance record',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to scan QR code: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get attendance status for a specific user/registration
  Future<AttendanceRecord?> getAttendanceStatus({
    required String eventId,
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/attendance/status',
        queryParameters: {
          'eventId': eventId,
          'userId': userId,
        },
      );

      // Validate response
      if (response.data == null) {
        return null;
      }

      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected attendance record',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to get attendance status: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get all attendance records for an event with optional filtering
  Future<List<AttendanceRecord>> getEventAttendance({
    required String eventId,
    AttendanceStatus? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'eventId': eventId,
      };

      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        '/api/attendance',
        queryParameters: queryParams,
      );

      // Validate response
      if (response.data is! List) {
        throw ApiException(
          message: 'Invalid response format: expected list of attendance records',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final List<dynamic> data = response.data;
      return data.map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch attendance records: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Manual override - mark entry
  Future<AttendanceRecord> manualEntry({
    required String eventId,
    required String userId,
    required String reason,
    required String overrideBy,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/attendance/override',
        data: {
          'eventId': eventId,
          'userId': userId,
          'action': 'entry',
          'reason': reason,
          'overrideBy': overrideBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected attendance record',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to record manual entry: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Manual override - mark exit
  Future<AttendanceRecord> manualExit({
    required String eventId,
    required String userId,
    required String reason,
    required String overrideBy,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/attendance/override',
        data: {
          'eventId': eventId,
          'userId': userId,
          'action': 'exit',
          'reason': reason,
          'overrideBy': overrideBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected attendance record',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to record manual exit: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Manual override - mark absent
  Future<AttendanceRecord> markAbsent({
    required String eventId,
    required String userId,
    required String reason,
    required String overrideBy,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/attendance/override',
        data: {
          'eventId': eventId,
          'userId': userId,
          'action': 'absent',
          'reason': reason,
          'overrideBy': overrideBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected attendance record',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to mark absent: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Export attendance to Excel
  /// Returns file path or download URL
  Future<String> exportToExcel({
    required String eventId,
    AttendanceStatus? statusFilter,
    String? searchFilter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'eventId': eventId,
      };

      if (statusFilter != null) {
        queryParams['status'] = statusFilter.toString().split('.').last;
      }

      if (searchFilter != null && searchFilter.isNotEmpty) {
        queryParams['search'] = searchFilter;
      }

      final response = await _apiClient.get(
        '/api/attendance/export',
        queryParameters: queryParams,
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected export result',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final data = response.data as Map<String, dynamic>;
      
      // Return file URL or path
      if (data.containsKey('url')) {
        return data['url'] as String;
      } else if (data.containsKey('path')) {
        return data['path'] as String;
      } else {
        throw ApiException(
          message: 'Export response missing file URL or path',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to export attendance: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get attendance statistics for an event
  Future<Map<String, dynamic>> getAttendanceStats(String eventId) async {
    try {
      final response = await _apiClient.get(
        '/api/attendance/stats',
        queryParameters: {'eventId': eventId},
      );

      // Validate response
      if (response.data is! Map) {
        throw ApiException(
          message: 'Invalid response format: expected statistics object',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch attendance statistics: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get attendance records for a specific user across all events
  Future<List<AttendanceRecord>> getUserAttendanceHistory(String userId) async {
    try {
      final response = await _apiClient.get(
        '/api/attendance/user/$userId',
      );

      // Validate response
      if (response.data is! List) {
        throw ApiException(
          message: 'Invalid response format: expected list of attendance records',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final List<dynamic> data = response.data;
      return data.map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch user attendance history: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Revoke event pass
  Future<void> revokePass({
    required String passId,
    required String reason,
    required String revokedBy,
  }) async {
    try {
      await _apiClient.post(
        '/api/pass/revoke',
        data: {
          'passId': passId,
          'reason': reason,
          'revokedBy': revokedBy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to revoke pass: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }
}
