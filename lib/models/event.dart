import 'dart:convert';

/// Event model representing an event
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String? imageUrl;
  final List<String> tags;
  final bool onDuty;
  final DateTime createdAt;
  final int participantCount;
  final DateTime? scanWindowStart;
  final DateTime? scanWindowEnd;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.imageUrl,
    required this.tags,
    required this.onDuty,
    required this.createdAt,
    this.participantCount = 0,
    this.scanWindowStart,
    this.scanWindowEnd,
  });

  /// Check if event is upcoming (date is in the future)
  bool get isUpcoming => date.isAfter(DateTime.now());

  /// Check if event is past (date is in the past)
  bool get isPast => date.isBefore(DateTime.now());

  /// Check if scan window is currently active
  bool get isScanWindowActive {
    final now = DateTime.now();
    return scanWindowStart != null &&
        scanWindowEnd != null &&
        now.isAfter(scanWindowStart!) &&
        now.isBefore(scanWindowEnd!);
  }

  /// Create Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      location: json['location'] as String,
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      onDuty: json['onDuty'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      participantCount: json['participantCount'] as int? ?? 0,
      scanWindowStart: json['scanWindowStart'] != null
          ? DateTime.parse(json['scanWindowStart'] as String)
          : null,
      scanWindowEnd: json['scanWindowEnd'] != null
          ? DateTime.parse(json['scanWindowEnd'] as String)
          : null,
    );
  }

  /// Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'imageUrl': imageUrl,
      'tags': tags,
      'onDuty': onDuty,
      'createdAt': createdAt.toIso8601String(),
      'participantCount': participantCount,
      'scanWindowStart': scanWindowStart?.toIso8601String(),
      'scanWindowEnd': scanWindowEnd?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? imageUrl,
    List<String>? tags,
    bool? onDuty,
    DateTime? createdAt,
    int? participantCount,
    DateTime? scanWindowStart,
    DateTime? scanWindowEnd,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      onDuty: onDuty ?? this.onDuty,
      createdAt: createdAt ?? this.createdAt,
      participantCount: participantCount ?? this.participantCount,
      scanWindowStart: scanWindowStart ?? this.scanWindowStart,
      scanWindowEnd: scanWindowEnd ?? this.scanWindowEnd,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $date, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.date == date &&
        other.time == time &&
        other.location == location &&
        other.imageUrl == imageUrl &&
        other.onDuty == onDuty;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        date.hashCode ^
        time.hashCode ^
        location.hashCode ^
        imageUrl.hashCode ^
        onDuty.hashCode;
  }
}
