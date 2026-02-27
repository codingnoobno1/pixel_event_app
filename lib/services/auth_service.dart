import 'dart:async';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

/// Authentication service for login, logout, and token management
/// Manages JWT tokens and user session state
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  // Stream controller for auth state changes
  final _authStateController = StreamController<User?>.broadcast();

  // Current user cache
  User? _currentUser;

  AuthService({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage {
    _initializeAuthState();
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Get current user (cached)
  User? get currentUser => _currentUser;

  /// Initialize auth state from stored token
  Future<void> _initializeAuthState() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token != null && !isTokenExpired(token)) {
        _currentUser = await _getUserFromToken(token);
        _authStateController.add(_currentUser);
      } else {
        // Token expired or doesn't exist
        await logout();
      }
    } catch (e) {
      // Error loading auth state
      await logout();
    }
  }

  /// Login with email and password
  /// Returns User on success, throws ApiException on failure
  Future<User> login(String email, String password) async {
    try {
      // Call dedicated Flutter auth endpoint
      final response = await _apiClient.post(
        '/api/flutter/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Check if login was successful
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Invalid email or password',
          statusCode: response.statusCode,
          type: ApiExceptionType.unauthorized,
        );
      }

      // Extract token from response
      // NextAuth might return token in different formats, adjust as needed
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token == null) {
        throw ApiException(
          message: 'No token received from server',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      // Store token
      await _secureStorage.saveAuthToken(token);

      // Get user from token
      final user = await _getUserFromToken(token);

      // Store user info
      await _secureStorage.saveUserId(user.uuid);
      await _secureStorage.saveUserRole(user.role.toString().split('.').last);

      // Update current user and emit state change
      _currentUser = user;
      _authStateController.add(_currentUser);

      return user;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Login failed: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Logout - clear all auth data
  Future<void> logout() async {
    try {
      // Clear stored auth data
      await _secureStorage.clearAuthData();

      // Update current user and emit state change
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      // Even if clearing fails, still emit null state
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  /// Get current user from stored token
  /// Returns null if no valid token exists
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null || isTokenExpired(token)) {
        return null;
      }

      _currentUser = await _getUserFromToken(token);
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is valid (not expired)
  bool isTokenValid(String token) {
    try {
      return !isTokenExpired(token);
    } catch (e) {
      return false;
    }
  }

  /// Check if token is expired
  /// JWT tokens expire after 15 minutes according to requirements
  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      // If we can't decode the token, consider it expired
      return true;
    }
  }

  /// Get remaining time until token expires
  Duration? getTokenRemainingTime(String token) {
    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      if (expirationDate.isBefore(now)) {
        return Duration.zero;
      }
      return expirationDate.difference(now);
    } catch (e) {
      return null;
    }
  }

  /// Extract user information from JWT token
  Future<User> _getUserFromToken(String token) async {
    try {
      final decodedToken = JwtDecoder.decode(token);

      // Extract user data from token payload
      // Adjust field names based on actual JWT structure
      final userId = decodedToken['sub'] ?? decodedToken['userId'] ?? decodedToken['id'];
      final email = decodedToken['email'];
      final name = decodedToken['name'];
      final role = decodedToken['role'];
      final enrollmentNumber = decodedToken['enrollmentNumber'];
      final course = decodedToken['course'];
      final semester = decodedToken['semester'];

      if (userId == null || email == null) {
        throw Exception('Invalid token: missing required fields');
      }

      // Parse role
      UserRole userRole;
      if (role == 'admin') {
        userRole = UserRole.admin;
      } else if (role == 'studentAdmin' || role == 'student_admin') {
        userRole = UserRole.studentAdmin;
      } else {
        userRole = UserRole.student;
      }

      return User(
        uuid: userId.toString(),
        name: name ?? 'Unknown',
        email: email,
        enrollmentNumber: enrollmentNumber,
        course: course,
        semester: int.tryParse(semester?.toString() ?? '0') ?? 0,
        role: userRole,
      );
    } catch (e) {
      throw Exception('Failed to parse user from token: $e');
    }
  }

  /// Refresh authentication state (check if token is still valid)
  Future<bool> refreshAuthState() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null || isTokenExpired(token)) {
        await logout();
        return false;
      }

      // Token is still valid
      if (_currentUser == null) {
        _currentUser = await _getUserFromToken(token);
        _authStateController.add(_currentUser);
      }
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAuthToken();
    return token != null && !isTokenExpired(token);
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
