import 'dart:async';
import 'api_client.dart';
import 'cache_service.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Service for event messages with polling functionality
/// Polls backend for new messages and tracks read status locally
class MessageService {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  // Polling timer
  Timer? _pollingTimer;

  // Current polling state
  bool _isPolling = false;
  String? _currentEventId;

  // Stream controller for messages
  final _messagesController = StreamController<List<EventMessage>>.broadcast();

  MessageService({
    required ApiClient apiClient,
    required CacheService cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService;

  /// Stream of event messages
  Stream<List<EventMessage>> get messagesStream => _messagesController.stream;

  /// Check if currently polling
  bool get isPolling => _isPolling;

  /// Get current event ID being polled
  String? get currentEventId => _currentEventId;

  /// Get event messages (single fetch)
  Future<List<EventMessage>> getEventMessages(String eventId) async {
    try {
      final response = await _apiClient.get(
        '/api/event/messages',
        queryParameters: {'eventId': eventId},
      );

      // Validate response
      if (response.data is! List) {
        throw ApiException(
          message: 'Invalid response format: expected list of messages',
          statusCode: response.statusCode,
          type: ApiExceptionType.badRequest,
        );
      }

      final List<dynamic> data = response.data;
      final messages = data.map((json) => EventMessage.fromJson(json as Map<String, dynamic>)).toList();

      // Load read status from local storage
      await _loadReadStatus(messages);

      return messages;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to fetch messages: ${e.toString()}',
        statusCode: null,
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Start polling for event messages
  /// Polls every [interval] seconds (default 7 seconds)
  void startPolling(String eventId, {Duration? interval}) {
    // Stop existing polling if any
    stopPolling();

    _currentEventId = eventId;
    _isPolling = true;

    final pollingInterval = interval ?? AppConstants.messagePollingInterval;

    // Initial fetch
    _fetchAndEmitMessages();

    // Start periodic polling
    _pollingTimer = Timer.periodic(pollingInterval, (_) {
      if (_isPolling) {
        _fetchAndEmitMessages();
      }
    });
  }

  /// Stop polling for messages
  void stopPolling() {
    _isPolling = false;
    _currentEventId = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch messages and emit to stream
  Future<void> _fetchAndEmitMessages() async {
    if (_currentEventId == null) return;

    try {
      final messages = await getEventMessages(_currentEventId!);
      if (!_messagesController.isClosed) {
        _messagesController.add(messages);
      }
    } catch (e) {
      // Don't emit error to stream, just log it
      // This prevents UI from breaking on temporary network issues
      print('Error fetching messages: $e');
    }
  }

  /// Mark message as read (local storage)
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final key = 'message_read_$messageId';
      await _cacheService.saveSetting(key, 'true');
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Check if message is read
  Future<bool> isMessageRead(String messageId) async {
    try {
      final key = 'message_read_$messageId';
      final value = await _cacheService.getSetting(key);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Load read status for messages from local storage
  Future<void> _loadReadStatus(List<EventMessage> messages) async {
    for (var i = 0; i < messages.length; i++) {
      final isRead = await isMessageRead(messages[i].id);
      messages[i] = messages[i].copyWith(isRead: isRead);
    }
  }

  /// Get unread messages for an event
  Future<List<EventMessage>> getUnreadMessages(String eventId) async {
    final messages = await getEventMessages(eventId);
    return messages.where((m) => !m.isRead).toList();
  }

  /// Get unread message count for an event
  Future<int> getUnreadMessageCount(String eventId) async {
    final unreadMessages = await getUnreadMessages(eventId);
    return unreadMessages.length;
  }

  /// Mark all messages as read for an event
  Future<void> markAllAsRead(String eventId) async {
    try {
      final messages = await getEventMessages(eventId);
      for (var message in messages) {
        await markMessageAsRead(message.id);
      }
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  /// Clear read status for all messages (for testing)
  Future<void> clearAllReadStatus() async {
    try {
      // This would require iterating through all message IDs
      // For now, we can clear all settings
      // await _cacheService.clearSettings();
    } catch (e) {
      print('Error clearing read status: $e');
    }
  }

  /// Get messages by priority
  Future<List<EventMessage>> getMessagesByPriority(
    String eventId,
    MessagePriority priority,
  ) async {
    final messages = await getEventMessages(eventId);
    return messages.where((m) => m.priority == priority).toList();
  }

  /// Get high priority messages
  Future<List<EventMessage>> getHighPriorityMessages(String eventId) async {
    return getMessagesByPriority(eventId, MessagePriority.high);
  }

  /// Get urgent messages
  Future<List<EventMessage>> getUrgentMessages(String eventId) async {
    return getMessagesByPriority(eventId, MessagePriority.urgent);
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
    _messagesController.close();
  }
}
