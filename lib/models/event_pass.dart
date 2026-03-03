import 'dart:convert';
import 'event.dart';
import 'user.dart';

/// Registration type enumeration
enum RegistrationType {
  solo,
  team;

  String toJson() => name;

  static RegistrationType fromJson(String json) {
    switch (json) {
      case 'solo':
        return RegistrationType.solo;
      case 'team':
        return RegistrationType.team;
      default:
        return RegistrationType.solo;
    }
  }
}

/// Team member model
class TeamMember {
  final String name;
  final String email;
  final String enrollmentNumber;
  final int semester;

  const TeamMember({
    required this.name,
    required this.email,
    required this.enrollmentNumber,
    required this.semester,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] as String,
      email: json['email'] as String,
      enrollmentNumber: json['enrollmentNumber'] as String,
      semester: json['semester'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'enrollmentNumber': enrollmentNumber,
      'semester': semester,
    };
  }
}

/// Event pass model with QR code payload
class EventPass {
  final String passId;
  final String eventId;
  final String registrationId;
  final String userId;
  final DateTime timestamp;
  final String qrSignature;
  final RegistrationType registrationType;
  final String? teamId;
  final String? teamName;
  final List<TeamMember>? teamMembers;
  final Event event;
  final User user;
  final String status;
  final int entryCount;
  final int exitCount;

  const EventPass({
    required this.passId,
    required this.eventId,
    required this.registrationId,
    required this.userId,
    required this.timestamp,
    required this.qrSignature,
    required this.registrationType,
    this.teamId,
    this.teamName,
    this.teamMembers,
    required this.event,
    required this.user,
    this.status = 'pending',
    this.entryCount = 0,
    this.exitCount = 0,
  });

  /// Generate QR code payload as JSON string
  String get qrPayload => jsonEncode({
        'passId': passId,
        'eventId': eventId,
        'registrationId': registrationId,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'teamId': teamId,
        'signature': qrSignature,
      });

  /// Create EventPass from JSON
  factory EventPass.fromJson(Map<String, dynamic> json) {
    return EventPass(
      passId: json['passId'] as String,
      eventId: json['eventId'] as String,
      registrationId: json['registrationId'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      qrSignature: json['qrSignature'] as String,
      registrationType: RegistrationType.fromJson(
        json['registrationType'] as String? ?? 'solo',
      ),
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      teamMembers: (json['teamMembers'] as List<dynamic>?)
          ?.map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      status: json['status'] as String? ?? 'pending',
      entryCount: json['entryCount'] as int? ?? 0,
      exitCount: json['exitCount'] as int? ?? 0,
    );
  }

  /// Convert EventPass to JSON
  Map<String, dynamic> toJson() {
    return {
      'passId': passId,
      'eventId': eventId,
      'registrationId': registrationId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'qrSignature': qrSignature,
      'registrationType': registrationType.toJson(),
      'teamId': teamId,
      'teamName': teamName,
      'teamMembers': teamMembers?.map((e) => e.toJson()).toList(),
      'event': event.toJson(),
      'user': user.toJson(),
    };
  }

  /// Create a copy with updated fields
  EventPass copyWith({
    List<TeamMember>? teamMembers,
    Event? event,
    User? user,
    String? status,
    int? entryCount,
    int? exitCount,
  }) {
    return EventPass(
      passId: passId ?? this.passId,
      eventId: eventId ?? this.eventId,
      registrationId: registrationId ?? this.registrationId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      qrSignature: qrSignature ?? this.qrSignature,
      registrationType: registrationType ?? this.registrationType,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamMembers: teamMembers ?? this.teamMembers,
      event: event ?? this.event,
      user: user ?? this.user,
      status: status ?? this.status,
      entryCount: entryCount ?? this.entryCount,
      exitCount: exitCount ?? this.exitCount,
    );
  }

  @override
  String toString() {
    return 'EventPass(passId: $passId, eventId: $eventId, registrationType: ${registrationType.name})';
  }
}
