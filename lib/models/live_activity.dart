import 'package:flutter/material.dart';

/// Represents a single live activity returned from the backend engine.
class LiveActivity {
  final String id;
  final String type; // quiz | voting | hunt | external | announcement
  final String title;
  final String? description;
  final String status;
  final bool hasSubmitted;
  final DateTime? activatedAt;

  // Type-specific data
  final QuizData? quiz;
  final VotingData? voting;
  final HuntData? hunt;
  final ExternalData? external;
  final AnnouncementData? announcement;

  const LiveActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.status,
    this.hasSubmitted = false,
    this.activatedAt,
    this.quiz,
    this.voting,
    this.hunt,
    this.external,
    this.announcement,
  });

  factory LiveActivity.fromJson(Map<String, dynamic> json) {
    return LiveActivity(
      id: json['_id']?.toString() ?? '',
      type: json['type'] ?? 'announcement',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'inactive',
      hasSubmitted: json['hasSubmitted'] ?? false,
      activatedAt: json['activatedAt'] != null
          ? DateTime.tryParse(json['activatedAt'])
          : null,
      quiz: json['quiz'] != null ? QuizData.fromJson(json['quiz']) : null,
      voting: json['voting'] != null ? VotingData.fromJson(json['voting']) : null,
      hunt: json['hunt'] != null ? HuntData.fromJson(json['hunt']) : null,
      external: json['external'] != null ? ExternalData.fromJson(json['external']) : null,
      announcement: json['announcement'] != null
          ? AnnouncementData.fromJson(json['announcement'])
          : null,
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int points;
  final String? imageUrl;
  final String? correctAnswer; // included in status payload for local grading

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.points,
    this.imageUrl,
    this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['_id']?.toString() ?? '',
        text: json['text'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        points: json['points'] ?? 10,
        imageUrl: json['imageUrl'],
        correctAnswer: json['correctAnswer'],
      );
}

class QuizData {
  final String quizType; // rapid_fire | custom_live | preloaded
  final int timePerQuestion;
  final int totalQuestions;
  final int currentQuestion;
  final bool autoAdvance;
  final bool shuffle;
  final List<QuizQuestion> questions;
  final QuizQuestion? activeQuestion; // for custom_live

  const QuizData({
    required this.quizType,
    required this.timePerQuestion,
    required this.totalQuestions,
    required this.currentQuestion,
    required this.autoAdvance,
    required this.shuffle,
    required this.questions,
    this.activeQuestion,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final activeQ = json['activeQuestion'];
    return QuizData(
      quizType: json['quizType'] ?? 'rapid_fire',
      timePerQuestion: json['timePerQuestion'] ?? 10,
      totalQuestions: json['totalQuestions'] ?? 0,
      currentQuestion: json['currentQuestion'] ?? 0,
      autoAdvance: json['autoAdvance'] ?? true,
      shuffle: json['shuffle'] ?? true,
      questions: rawQuestions.map((q) => QuizQuestion.fromJson(q)).toList(),
      activeQuestion: activeQ != null ? QuizQuestion.fromJson(activeQ) : null,
    );
  }
}

class VotingData {
  final String question;
  final List<String> options;
  final bool allowMultiple;
  final bool showLiveResults;
  final int votingDurationSeconds;

  const VotingData({
    required this.question,
    required this.options,
    required this.allowMultiple,
    required this.showLiveResults,
    required this.votingDurationSeconds,
  });

  factory VotingData.fromJson(Map<String, dynamic> json) => VotingData(
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        allowMultiple: json['allowMultiple'] ?? false,
        showLiveResults: json['showLiveResults'] ?? true,
        votingDurationSeconds: json['votingDurationSeconds'] ?? 60,
      );
}

class HuntCheckpointMeta {
  final String checkpointId;
  final int order;
  final String hint;
  final String challengeType;

  const HuntCheckpointMeta({
    required this.checkpointId,
    required this.order,
    required this.hint,
    required this.challengeType,
  });

  factory HuntCheckpointMeta.fromJson(Map<String, dynamic> json) =>
      HuntCheckpointMeta(
        checkpointId: json['checkpointId'] ?? '',
        order: json['order'] ?? 0,
        hint: json['hint'] ?? '',
        challengeType: json['challengeType'] ?? 'hint-only',
      );
}

class HuntData {
  final int totalCheckpoints;
  final bool ordered;
  final List<HuntCheckpointMeta> checkpoints;

  const HuntData({
    required this.totalCheckpoints,
    required this.ordered,
    required this.checkpoints,
  });

  factory HuntData.fromJson(Map<String, dynamic> json) {
    final raw = json['checkpoints'] as List<dynamic>? ?? [];
    return HuntData(
      totalCheckpoints: json['totalCheckpoints'] ?? 0,
      ordered: json['ordered'] ?? true,
      checkpoints: raw.map((c) => HuntCheckpointMeta.fromJson(c)).toList(),
    );
  }
}

class ExternalData {
  final String url;
  final int points;
  final int durationMinutes;

  const ExternalData({
    required this.url,
    required this.points,
    required this.durationMinutes,
  });

  factory ExternalData.fromJson(Map<String, dynamic> json) => ExternalData(
        url: json['url'] ?? '',
        points: json['points'] ?? 200,
        durationMinutes: json['durationMinutes'] ?? 20,
      );
}

class AnnouncementData {
  final String message;
  final int displaySeconds;

  const AnnouncementData({required this.message, required this.displaySeconds});

  factory AnnouncementData.fromJson(Map<String, dynamic> json) =>
      AnnouncementData(
        message: json['message'] ?? '',
        displaySeconds: json['displaySeconds'] ?? 15,
      );
}

/// Status response from the polling endpoint
class EventStatusResponse {
  final String eventId;
  final bool onDuty;
  final LiveActivity? activeActivity;
  final DateTime serverTime;

  const EventStatusResponse({
    required this.eventId,
    required this.onDuty,
    this.activeActivity,
    required this.serverTime,
  });

  factory EventStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return EventStatusResponse(
      eventId: data['eventId']?.toString() ?? '',
      onDuty: data['onDuty'] ?? false,
      activeActivity: data['activeActivity'] != null
          ? LiveActivity.fromJson(data['activeActivity'])
          : null,
      serverTime: DateTime.tryParse(data['serverTime'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Scan result from QR checkpoint
class ScanResult {
  final bool success;
  final String checkpointId;
  final int order;
  final int totalCheckpoints;
  final int completedCheckpoints;
  final int totalScore;
  final String challengeType;
  final Map<String, dynamic> challenge;
  final bool huntCompleted;
  final String? message;
  final String? error;

  const ScanResult({
    required this.success,
    required this.checkpointId,
    required this.order,
    required this.totalCheckpoints,
    required this.completedCheckpoints,
    required this.totalScore,
    required this.challengeType,
    required this.challenge,
    this.huntCompleted = false,
    this.message,
    this.error,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        success: json['success'] ?? false,
        checkpointId: json['checkpointId'] ?? '',
        order: json['order'] ?? 0,
        totalCheckpoints: json['totalCheckpoints'] ?? 0,
        completedCheckpoints: json['completedCheckpoints'] ?? 0,
        totalScore: json['totalScore'] ?? 0,
        challengeType: json['challengeType'] ?? 'hint-only',
        challenge: Map<String, dynamic>.from(json['challenge'] ?? {}),
        huntCompleted: json['huntCompleted'] ?? false,
        message: json['message'],
        error: json['error'],
      );
}
