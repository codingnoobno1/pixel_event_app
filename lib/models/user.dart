import 'dart:convert';

/// User role enumeration
enum UserRole {
  admin,
  studentAdmin,
  student;

  String toJson() => name;

  static UserRole fromJson(String json) {
    switch (json) {
      case 'admin':
        return UserRole.admin;
      case 'studentAdmin':
      case 'student_admin':
        return UserRole.studentAdmin;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }
}

/// User model representing authenticated user
class User {
  final String uuid;
  final String name;
  final String email;
  final String enrollmentNumber;
  final String course;
  final int semester;
  final UserRole role;

  const User({
    required this.uuid,
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.course,
    required this.semester,
    required this.role,
  });

  /// Check if user has admin privileges
  bool get isAdmin => role == UserRole.admin || role == UserRole.studentAdmin;

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      enrollmentNumber: json['enrollmentNumber'] as String? ?? '',
      course: json['course'] as String? ?? '',
      semester: json['semester'] as int? ?? 0,
      role: UserRole.fromJson(json['role'] as String? ?? 'student'),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'enrollmentNumber': enrollmentNumber,
      'course': course,
      'semester': semester,
      'role': role.toJson(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? uuid,
    String? name,
    String? email,
    String? enrollmentNumber,
    String? course,
    int? semester,
    UserRole? role,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'User(uuid: $uuid, name: $name, email: $email, role: ${role.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.uuid == uuid &&
        other.name == name &&
        other.email == email &&
        other.enrollmentNumber == enrollmentNumber &&
        other.course == course &&
        other.semester == semester &&
        other.role == role;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        enrollmentNumber.hashCode ^
        course.hashCode ^
        semester.hashCode ^
        role.hashCode;
  }
}
