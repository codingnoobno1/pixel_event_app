/// Application-wide constants and configuration
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://pixelquizraiderx.netlify.app';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Session Configuration
  static const Duration sessionDuration = Duration(minutes: 15);
  static const Duration sessionRefreshInterval = Duration(minutes: 5);
  
  // Scan Configuration
  static const int maxScansPerPass = 2;
  static const int maxScansPerMinute = 60;
  static const Duration duplicateScanWindow = Duration(seconds: 5);
  static const Duration qrCodeValidityDuration = Duration(hours: 24);
  
  // Scan Window Configuration
  static const Duration scanWindowBeforeEvent = Duration(minutes: 30);
  
  // Event Lobby Configuration
  static const Duration lobbyRefreshInterval = Duration(seconds: 30);
  static const Duration messagePollingInterval = Duration(seconds: 7);
  
  // Team Configuration
  static const int maxTeamMembers = 6;
  
  // QR Code Configuration
  // WARNING: In production, this should be securely stored or fetched from backend
  static const String qrSecretKey = 'your-secret-key-here-change-in-production';
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyLastSync = 'last_sync';
  
  // Database
  static const String dbName = 'pixel_events.db';
  static const int dbVersion = 1;
  
  // App Info
  static const String appName = 'Pixel Events';
  static const String appVersion = '1.0.0';
}
