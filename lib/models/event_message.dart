import 'dart:convert';

/// Message priority enumeration
enum MessagePriority {
  normal,
  high,
  urgent;

  String toJson() => name;

  static MessagePriority fromJson(String json) {
    switch (json) {
      case 'normal':
        return MessagePriority.normal;
      case 'high':
        return MessagePriority.high;
      case 'urgent':
        return MessagePriority.urgent;
      default:
        return MessagePriority.normal;
    }
  }
}

/// Event message model for admin-to-participant communication
class EventMessage {
  final String id;
  final String eventId;
  final String message;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final MessagePriority priority;
  final bool isRead;

  const EventMessage({
    required this.id,
    required this.eventId,
    required this.message,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    required this.priority,
    this.isRead = false,
  });

  /// Create EventMessage from JSON
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return EventMessage(
      id: json['_id'] as String? ?? json['id'] as String,
      eventId: json['eventId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      priority: MessagePriority.fromJson(json['priority'] as String? ?? 'normal'),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Convert EventMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'senderName': senderName,
      'priority': priority.toJson(),
      'isRead': isRead,
    };
  }

  /// Create a copy with updated fields
  EventMessage copyWith({
    String? id,
    String? eventId,
    String? message,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    MessagePriority? priority,
    bool? isRead,
  }) {
    return EventMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'EventMessage(id: $id, priority: ${priority.name}, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventMessage &&
        other.id == id &&
        other.eventId == eventId &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.senderId == senderId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        message.hashCode ^
        timestamp.hashCode ^
        senderId.hashCode;
  }
}
