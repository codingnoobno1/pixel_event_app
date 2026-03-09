import '../models/live_activity.dart';
import '../services/api_client.dart';

/// Service for the Live Event Activity Engine.
/// Call [getEventStatus] every 5-10 seconds to get the currently active activity.
/// The Flutter app uses the returned [LiveActivity.type] to navigate to the correct screen.
class EventEngineService {
  final ApiClient _apiClient;

  EventEngineService(this._apiClient);

  // ── Status poll ──────────────────────────────────────────────────────────
  /// GET /api/flutter/events/status?eventId=[id]
  /// Call every 5-10s. Returns the currently active [LiveActivity] or null.
  Future<EventStatusResponse> getEventStatus(String eventId) async {
    final response = await _apiClient.get(
      '/api/flutter/events/status',
      queryParameters: {'eventId': eventId},
    );
    return EventStatusResponse.fromJson(response.data);
  }

  // ── Quiz Submission ───────────────────────────────────────────────────────
  /// POST /api/flutter/events/quiz/submit
  /// Grade and store a quiz attempt server-side.
  /// [answers] = list of {questionId, selectedOption}
  Future<Map<String, dynamic>> submitQuiz({
    required String activityId,
    required String participantId,
    required List<Map<String, String>> answers,
    int? timeTakenSeconds,
  }) async {
    final response = await _apiClient.post(
      '/api/flutter/events/quiz/submit',
      data: {
        'activityId': activityId,
        'participantId': participantId,
        'answers': answers,
        if (timeTakenSeconds != null) 'timeTakenSeconds': timeTakenSeconds,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/flutter/events/quiz/submit?activityId=[id]&participantId=[id]
  /// Check if participant already submitted (restore result on re-open).
  Future<Map<String, dynamic>> getQuizSubmission({
    required String activityId,
    required String participantId,
  }) async {
    final response = await _apiClient.get(
      '/api/flutter/events/quiz/submit',
      queryParameters: {'activityId': activityId, 'participantId': participantId},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Timeline (one-time cache) ────────────────────────────────────────────
  /// GET /api/flutter/events/timeline?eventId=[id]
  /// Fetch once on event entry. Cache quiz packs locally.
  Future<Map<String, dynamic>> getEventTimeline(String eventId) async {
    final response = await _apiClient.get(
      '/api/flutter/events/timeline',
      queryParameters: {'eventId': eventId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Voting ────────────────────────────────────────────────────────────────
  /// POST /api/flutter/events/vote
  /// Submit a vote. Returns live results if enabled.
  Future<Map<String, dynamic>> submitVote({
    required String activityId,
    required String participantId,
    required String option,
  }) async {
    final response = await _apiClient.post(
      '/api/flutter/events/vote',
      data: {
        'activityId': activityId,
        'participantId': participantId,
        'option': option,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/flutter/events/vote?activityId=[id]
  /// Fetch live vote tally.
  Future<Map<String, dynamic>> getVoteResults(String activityId) async {
    final response = await _apiClient.get(
      '/api/flutter/events/vote',
      queryParameters: {'activityId': activityId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── QR Scan ───────────────────────────────────────────────────────────────
  /// POST /api/flutter/events/scan
  /// Submits a scanned QR checkpoint. Returns the challenge.
  /// QR format: pixel://hunt/[eventId]/[checkpointId]
  Future<ScanResult> scanCheckpoint({
    required String eventId,
    required String checkpointId,
    required String participantId,
  }) async {
    final response = await _apiClient.post(
      '/api/flutter/events/scan',
      data: {
        'eventId': eventId,
        'checkpointId': checkpointId,
        'participantId': participantId,
      },
    );
    return ScanResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Legacy compat (existing screens still work) ──────────────────────────
  /// Submit progress for any event mode (legacy eventmode API).
  Future<void> submitModeProgress({
    required String eventId,
    required String email,
    required String mode,
    required int score,
    String status = 'completed',
    Map<String, dynamic>? data,
  }) async {
    await _apiClient.post(
      '/api/flutter/eventmode/$mode',
      data: {
        'eventId': eventId,
        'email': email,
        'score': score,
        'status': status,
        'data': data ?? {},
      },
    );
  }
}
