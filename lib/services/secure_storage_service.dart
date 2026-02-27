import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage of sensitive data like tokens
/// Wraps flutter_secure_storage with custom interface and error handling
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';

  /// Write a value to secure storage
  /// Throws [SecureStorageException] if write fails
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to write to secure storage: $e');
    }
  }

  /// Read a value from secure storage
  /// Returns null if key doesn't exist
  /// Throws [SecureStorageException] if read fails
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read from secure storage: $e');
    }
  }

  /// Delete a value from secure storage
  /// Throws [SecureStorageException] if delete fails
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete from secure storage: $e');
    }
  }

  /// Delete all values from secure storage
  /// Throws [SecureStorageException] if deleteAll fails
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
          'Failed to delete all from secure storage: $e');
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      throw SecureStorageException('Failed to check key in secure storage: $e');
    }
  }

  // Convenience methods for auth tokens

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await write(_keyAuthToken, token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await read(_keyAuthToken);
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await delete(_keyAuthToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(_keyRefreshToken, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await read(_keyRefreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await delete(_keyRefreshToken);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await write(_keyUserId, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await read(_keyUserId);
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    await write(_keyUserRole, role);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    return await read(_keyUserRole);
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await deleteAuthToken();
    await deleteRefreshToken();
    await delete(_keyUserId);
    await delete(_keyUserRole);
  }
}

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
