import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

/// Core service providers
/// These providers create and manage service instances

// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: secureStorage);
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  
  final authService = AuthService(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    authService.dispose();
  });
  
  return authService;
});

// QR Service Provider
final qrServiceProvider = Provider<QRService>((ref) {
  return QRService();
});

// Scanner Service Provider
final scannerServiceProvider = Provider<ScannerService>((ref) {
  final scannerService = ScannerService();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    scannerService.dispose();
  });
  
  return scannerService;
});

// Message Service Provider
final messageServiceProvider = Provider<MessageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  
  final messageService = MessageService(
    apiClient: apiClient,
    cacheService: cacheService,
  );
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    messageService.dispose();
  });
  
  return messageService;
});
