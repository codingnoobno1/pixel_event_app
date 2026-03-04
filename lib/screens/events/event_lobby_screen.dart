import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../providers/providers.dart';

class EventLobbyScreen extends ConsumerStatefulWidget {
  final Event event;
  final EventPass pass;

  const EventLobbyScreen({
    super.key,
    required this.event,
    required this.pass,
  });

  @override
  ConsumerState<EventLobbyScreen> createState() => _EventLobbyScreenState();
}

class _EventLobbyScreenState extends ConsumerState<EventLobbyScreen> {
  late Event _currentEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _refreshEvent();
  }

  Future<void> _refreshEvent() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final updatedEvent = await repo.getEventById(widget.event.id);
      setState(() {
        _currentEvent = updatedEvent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Fallback to widget event if refresh fails
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);
    const cyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentEvent.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.sync : Icons.refresh, color: Colors.white70),
            onPressed: _refreshEvent,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B0F), Color(0xFF15151F)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshEvent,
          color: pink,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Banner Status
                CyberGlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.hub_outlined, color: cyan, size: 30),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MINI-EVENT STATUS",
                              style: TextStyle(color: cyan, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                            ),
                            Text(
                              _currentEvent.activeModeType != null ? "MODE: ${_currentEvent.activeModeType!.toUpperCase()}" : "JOIN THE FUN!",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      CyberBadge(label: "LIVE", color: pink, type: CyberBadgeType.glow),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 40),

                const Text(
                  "CHOOSE A FUN ACTIVITY",
                  style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Dynamic Modes Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _modeCard(
                      Icons.quiz_outlined, 
                      "QUIZ ZONE", 
                      "Rapid fire & more", 
                      pink,
                      () => Navigator.pushNamed(context, '/quiz-mode', arguments: _currentEvent),
                      active: _currentEvent.activeModeType == 'quiz'
                    ),
                    _modeCard(
                      Icons.how_to_vote_outlined, 
                      "VOTING", 
                      "Make your voice count", 
                      cyan,
                      () => Navigator.pushNamed(context, '/voting-mode', arguments: _currentEvent),
                      active: _currentEvent.activeModeType == 'voting'
                    ),
                    _modeCard(
                      Icons.explore_outlined, 
                      "TREASURE HUNT", 
                      "Find the hidden codes", 
                      Colors.amber,
                      () => Navigator.pushNamed(context, '/treasure-hunt', arguments: _currentEvent),
                      active: _currentEvent.activeModeType == 'treasure-hunt'
                    ),
                    _modeCard(
                      Icons.more_horiz_outlined, 
                      "MORE", 
                      "Explore activities", 
                      Colors.grey,
                      () {},
                      active: false
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // Current Activity Callout
                if (_currentEvent.activeModeType != null)
                  CyberCard(
                    color: pink.withOpacity(0.2),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: pink),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "The ${_currentEvent.activeModeType} mode is currently live! Join now for participation points.",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? color : Colors.white10, width: 2),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)] : [],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            ),
            if (active) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                child: Text("ACTIVE", style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
