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
  final DateTime? createdAt;
  final EventPass? eventPass;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final int entryCount;
  final int exitCount;
  final List<ModeProgress>? modeProgress;

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
    this.createdAt,
    this.eventPass,
    this.entryTime,
    this.exitTime,
    this.entryCount = 0,
    this.exitCount = 0,
    this.modeProgress,
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
          : null,
      eventPass: json['eventPass'] != null
          ? EventPass.fromJson(json['eventPass'] as Map<String, dynamic>)
          : null,
      entryTime: json['entryTime'] != null ? DateTime.parse(json['entryTime'] as String) : null,
      exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime'] as String) : null,
      entryCount: json['entryCount'] as int? ?? 0,
      exitCount: json['exitCount'] as int? ?? 0,
      modeProgress: (json['modeProgress'] as List<dynamic>?)
          ?.map((e) => ModeProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'createdAt': createdAt?.toIso8601String(),
      'eventPass': eventPass?.toJson(),
    };
  }

  /// Create a copy with updated fields
  Registration copyWith({
    DateTime? createdAt,
    EventPass? eventPass,
    DateTime? entryTime,
    DateTime? exitTime,
    int? entryCount,
    int? exitCount,
    List<ModeProgress>? modeProgress,
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
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      entryCount: entryCount ?? this.entryCount,
      exitCount: exitCount ?? this.exitCount,
      modeProgress: modeProgress ?? this.modeProgress,
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
    return id.hashCode ^ eventId.hashCode ^ registrationType.hashCode ^ email.hashCode ^ status.hashCode;
  }
}

/// Progress in a specific event mode
class ModeProgress {
  final String mode;
  final String status;
  final double score;
  final Map<String, dynamic>? data;

  const ModeProgress({
    required this.mode,
    required this.status,
    required this.score,
    this.data,
  });

  factory ModeProgress.fromJson(Map<String, dynamic> json) {
    return ModeProgress(
      mode: json['mode'] as String,
      status: json['status'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'status': status,
      'score': score,
      'data': data,
    };
  }
}
