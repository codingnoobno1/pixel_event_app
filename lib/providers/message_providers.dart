import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'service_providers.dart';

/// Event message providers
/// Manages message polling and read status

// Event Messages Stream Provider (family provider for polling messages)
final eventMessagesProvider = StreamProvider.autoDispose.family<List<EventMessage>, String>(
  (ref, eventId) {
    final messageService = ref.watch(messageServiceProvider);
    
    // Start polling when provider is created
    messageService.startPolling(eventId);
    
    // Stop polling when provider is disposed
    ref.onDispose(() {
      messageService.stopPolling();
    });
    
    return messageService.messagesStream;
  },
);

// Unread Messages Count Provider (family provider)
final unreadMessagesCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, eventId) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.getUnreadMessageCount(eventId);
  },
);

// Unread Messages Provider (family provider)
final unreadMessagesProvider = FutureProvider.autoDispose.family<List<EventMessage>, String>(
  (ref, eventId) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.getUnreadMessages(eventId);
  },
);

// High Priority Messages Provider (family provider)
final highPriorityMessagesProvider = FutureProvider.autoDispose.family<List<EventMessage>, String>(
  (ref, eventId) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.getHighPriorityMessages(eventId);
  },
);

// Urgent Messages Provider (family provider)
final urgentMessagesProvider = FutureProvider.autoDispose.family<List<EventMessage>, String>(
  (ref, eventId) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.getUrgentMessages(eventId);
  },
);

// Message Read Status Provider (family provider for specific message)
final messageReadStatusProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, messageId) async {
    final messageService = ref.watch(messageServiceProvider);
    return await messageService.isMessageRead(messageId);
  },
);
