import 'dart:convert';

/// Available event modes
enum EventModeType {
  quiz,
  voting,
  treasureHunt,
  custom;

  String get slug {
    if (this == EventModeType.treasureHunt) return 'treasure-hunt';
    return name;
  }

  String toJson() => name;

  static EventModeType fromJson(String json) {
    return EventModeType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EventModeType.custom,
    );
  }
}

/// Dynamic event mode model
class EventMode {
  final String type;
  final Map<String, dynamic> config;

  const EventMode({
    required this.type,
    required this.config,
  });

  factory EventMode.fromJson(Map<String, dynamic> json) {
    return EventMode(
      type: (json['mode'] ?? json['type']) as String? ?? 'custom',
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'config': config,
    };
  }
}

/// Specific configuration for Quiz Mode (optional/extended)
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
