import 'dart:convert';

/// Enumeration for different event modes
enum EventModeType {
  quiz,
  voting,
  treasureHunt,
  standard;

  static EventModeType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return EventModeType.quiz;
      case 'voting':
        return EventModeType.voting;
      case 'treasurehunt':
      case 'treasure_hunt':
        return EventModeType.treasureHunt;
      default:
        return EventModeType.standard;
    }
  }
}

/// Base model for event modes
class EventMode {
  final EventModeType type;
  final String eventId;
  final Map<String, dynamic> config;

  const EventMode({
    required this.type,
    required this.eventId,
    required this.config,
  });

  factory EventMode.fromJson(Map<String, dynamic> json) {
    return EventMode(
      type: EventModeType.fromString(json['type'] as String? ?? 'standard'),
      eventId: json['eventId'] as String,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Specific configuration for Quiz Mode
class QuizConfig {
  final String quizType; // rapid_fire, long_thinking
  final int totalQuestions;
  final int timeLimitSeconds;

  QuizConfig({
    required this.quizType,
    required this.totalQuestions,
    required this.timeLimitSeconds,
  });

  factory QuizConfig.fromMap(Map<String, dynamic> map) {
    return QuizConfig(
      quizType: map['quizType'] as String? ?? 'rapid_fire',
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      timeLimitSeconds: map['timeLimitSeconds'] as int? ?? 0,
    );
  }
}
