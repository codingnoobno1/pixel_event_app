import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../widgets/widgets.dart';
import '../../events/event_lobby_screen.dart';

class EventModeTab extends ConsumerStatefulWidget {
  const EventModeTab({super.key});

  @override
  ConsumerState<EventModeTab> createState() => _EventModeTabState();
}

class _EventModeTabState extends ConsumerState<EventModeTab> {
  Event? _activeEvent;
  EventPass? _activePass;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check authentication and find event whenever dependencies change
    _findActiveEvent();
  }

  Future<void> _findActiveEvent() async {
    // Prevent multiple simultaneous scans
    if (_isLoading && _activeEvent != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(eventRepositoryProvider);
      
      // 1. Wait for valid user (avoiding the initialization race)
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      
      if (user == null) {
        if (userAsync.isLoading) {
           // Still loading user, don't set error yet
           return;
        }
        setState(() {
          _error = "User not authenticated";
          _isLoading = false;
        });
        return;
      }
      
      final email = user.email;

      // 2. Get registrations
      final registrations = await repo.getMyRegistrations(email);
      print('🔍 DEBUG: Found ${registrations.length} registrations for $email');
      
      if (registrations.isEmpty) {
        setState(() {
          _activeEvent = null;
          _isLoading = false;
        });
        return;
      }

      // 3. Find event with activeMode
      for (var reg in registrations) {
        print('🔍 DEBUG: Checking Event ID: ${reg.eventId}');
        try {
          final event = await repo.getEventById(reg.eventId);
          print('🔍 DEBUG: Event "${event.title}" mode: ${event.activeMode}');
          
          if (event.activeMode != null) {
            final pass = await repo.getEventPass(email, event.id);
            setState(() {
              _activeEvent = event;
              _activePass = pass;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print('⚠️ DEBUG: Failed to fetch event ${reg.eventId}: $e');
          // Skip missing/broken events instead of crashing the whole scan
          continue;
        }
      }

      setState(() {
        _activeEvent = null;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Scan failed globally: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2E88);
    const cyan = Color(0xFF00D2FF);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: pink),
            SizedBox(height: 16),
            Text("Scanning for active event modes...", style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text("Error: $_error", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            CyberButton(
              onPressed: _findActiveEvent, 
              text: "RETRY SCAN",
              color: pink,
            ),
          ],
        ),
      );
    }

    if (_activeEvent == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: pink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sensors_off_outlined, color: pink, size: 64),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              const Text(
                "NO ACTIVE EVENT MODE",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                "Register for an event or wait for the host to enable a live mode (Quiz, Vote, etc.)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 40),
              CyberButton(
                onPressed: _findActiveEvent,
                text: "REFRESH STATUS",
                icon: Icons.refresh,
                color: cyan,
              ),
            ],
          ),
        ),
      );
    }

    // If we have an active event, we show a "mini-lobby" or redirect to the full lobby
    // For now, let's embed a simplified version of the lobby logic
    return EventLobbyScreen(
      event: _activeEvent!, 
      pass: _activePass!,
    );
  }
}
