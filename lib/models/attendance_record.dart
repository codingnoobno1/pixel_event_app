import 'dart:convert';

/// Attendance status enumeration
enum AttendanceStatus {
  pending,
  attended,
  absent,
  cancelled;

  String toJson() => name;

  static AttendanceStatus fromJson(String json) {
    switch (json) {
      case 'pending':
        return AttendanceStatus.pending;
      case 'attended':
        return AttendanceStatus.attended;
      case 'absent':
        return AttendanceStatus.absent;
      case 'cancelled':
        return AttendanceStatus.cancelled;
      default:
        return AttendanceStatus.pending;
    }
  }
}

/// Attendance record model
class AttendanceRecord {
  final String id;
  final String registrationId;
  final String eventId;
  final String userId;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final AttendanceStatus status;
  final String? scannedBy;
  final int scanCount;
  final bool isLateEntry;
  final bool isManualOverride;
  final String? overrideReason;

  const AttendanceRecord({
    required this.id,
    required this.registrationId,
    required this.eventId,
    required this.userId,
    this.entryTime,
    this.exitTime,
    required this.status,
    this.scannedBy,
    required this.scanCount,
    this.isLateEntry = false,
    this.isManualOverride = false,
    this.overrideReason,
  });

  /// Calculate dwell duration (time between entry and exit)
  Duration? get dwellDuration {
    if (entryTime != null && exitTime != null) {
      return exitTime!.difference(entryTime!);
    }
    return null;
  }

  /// Create AttendanceRecord from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] as String? ?? json['id'] as String,
      registrationId: json['registrationId'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      entryTime: json['entryTime'] != null
          ? DateTime.parse(json['entryTime'] as String)
          : null,
      exitTime: json['exitTime'] != null
          ? DateTime.parse(json['exitTime'] as String)
          : null,
      status: AttendanceStatus.fromJson(json['status'] as String? ?? 'pending'),
      scannedBy: json['scannedBy'] as String?,
      scanCount: json['scanCount'] as int? ?? 0,
      isLateEntry: json['isLateEntry'] as bool? ?? false,
      isManualOverride: json['isManualOverride'] as bool? ?? false,
      overrideReason: json['overrideReason'] as String?,
    );
  }

  /// Convert AttendanceRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationId': registrationId,
      'eventId': eventId,
      'userId': userId,
      'entryTime': entryTime?.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'status': status.toJson(),
      'scannedBy': scannedBy,
      'scanCount': scanCount,
      'isLateEntry': isLateEntry,
      'isManualOverride': isManualOverride,
      'overrideReason': overrideReason,
    };
  }

  /// Create a copy with updated fields
  AttendanceRecord copyWith({
    String? id,
    String? registrationId,
    String? eventId,
    String? userId,
    DateTime? entryTime,
    DateTime? exitTime,
    AttendanceStatus? status,
    String? scannedBy,
    int? scanCount,
    bool? isLateEntry,
    bool? isManualOverride,
    String? overrideReason,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      registrationId: registrationId ?? this.registrationId,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
      scannedBy: scannedBy ?? this.scannedBy,
      scanCount: scanCount ?? this.scanCount,
      isLateEntry: isLateEntry ?? this.isLateEntry,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, status: ${status.name}, scanCount: $scanCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceRecord &&
        other.id == id &&
        other.registrationId == registrationId &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.status == status &&
        other.scanCount == scanCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        registrationId.hashCode ^
        eventId.hashCode ^
        userId.hashCode ^
        status.hashCode ^
        scanCount.hashCode;
  }
}
