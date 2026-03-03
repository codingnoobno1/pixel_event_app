import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'service_providers.dart';

/// Auth state providers
/// These providers manage authentication state reactively

// Current User Stream Provider
// Listens to auth state changes and emits current user
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  
  // 1. Check if we already have a user (initialization might have finished)
  yield authService.currentUser;
  
  // 2. Stream all future changes
  yield* authService.authStateChanges;
});

// Is Authenticated Provider
// Checks if user is currently authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isAuthenticated();
});

// User Role Provider
// Gets the current user's role
final userRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.role,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Is Admin Provider
// Checks if current user is an admin (admin or studentAdmin)
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == UserRole.admin || role == UserRole.studentAdmin;
});

// Is Student Admin Provider
// Checks if current user is a student admin
final isStudentAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == UserRole.studentAdmin;
});

// Is Regular Student Provider
// Checks if current user is a regular student
final isStudentProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == UserRole.student;
});
