import 'dart:convert';
import 'event_pass.dart';
import 'attendance_record.dart';

/// Registration model
class Registration {
  final String id;
  final String eventId;
  final String? userId;
  final RegistrationType registrationType;
  final String? teamName;
  final String? teamId;
  final String name;
  final String email;
  final String? enrollmentNumber;
  final String? semester;
  final List<TeamMember>? members;
  final AttendanceStatus status;
  final DateTime createdAt;
  final EventPass? eventPass;

  const Registration({
    required this.id,
    required this.eventId,
    this.userId,
    required this.registrationType,
    this.teamName,
    this.teamId,
    required this.name,
    required this.email,
    this.enrollmentNumber,
    this.semester,
    this.members,
    required this.status,
    required this.createdAt,
    this.eventPass,
  });

  /// Create Registration from JSON
  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      eventId: (json['eventId'] is Map)
          ? (json['eventId'] as Map<String, dynamic>)['_id'] as String? ?? ''
          : json['eventId'] as String? ?? '',
      userId: json['userId'] as String?,
      registrationType: RegistrationType.fromJson(
        json['registrationType'] as String? ?? 'solo',
      ),
      teamName: json['teamName'] as String?,
      teamId: json['teamId'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      enrollmentNumber: json['enrollmentNumber'] as String?,
      semester: json['semester']?.toString(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: AttendanceStatus.fromJson(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      eventPass: json['eventPass'] != null
          ? EventPass.fromJson(json['eventPass'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert Registration to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'registrationType': registrationType.toJson(),
      'teamName': teamName,
      'teamId': teamId,
      'name': name,
      'email': email,
      'enrollmentNumber': enrollmentNumber,
      'semester': semester,
      'members': members?.map((e) => e.toJson()).toList(),
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'eventPass': eventPass?.toJson(),
    };
  }

  /// Create a copy with updated fields
  Registration copyWith({
    String? id,
    String? eventId,
    String? userId,
    RegistrationType? registrationType,
    String? teamName,
    String? teamId,
    String? name,
    String? email,
    String? enrollmentNumber,
    String? semester,
    List<TeamMember>? members,
    AttendanceStatus? status,
    DateTime? createdAt,
    EventPass? eventPass,
  }) {
    return Registration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      registrationType: registrationType ?? this.registrationType,
      teamName: teamName ?? this.teamName,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      email: email ?? this.email,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      semester: semester ?? this.semester,
      members: members ?? this.members,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      eventPass: eventPass ?? this.eventPass,
    );
  }

  @override
  String toString() {
    return 'Registration(id: $id, name: $name, type: ${registrationType.name}, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Registration &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        email.hashCode;
  }
}
