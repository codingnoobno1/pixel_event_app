import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/live_activity.dart';
import '../../services/event_engine_service.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'modes/quiz_mode_screen.dart';
import 'modes/voting_mode_screen.dart';
import 'modes/treasure_hunt_screen.dart';
import 'modes/live_external_screen.dart';
import 'modes/live_announcement_screen.dart';

/// Polling interval in seconds
const _kPollSeconds = 7;

/// Colors
const _bg = Color(0xFF0B0B0F);
const _cyan = Color(0xFF00FFFF);
const _pink = Color(0xFFFF2E88);
const _green = Color(0xFF00FF64);
const _yellow = Color(0xFFFFD700);
const _purple = Color(0xFFA855F7);

/// Maps activity type → (icon, color, screen label)
final _typeMeta = {
  'quiz':         (_TypeMeta(Icons.quiz_outlined,        _cyan,   'QUIZ'         )),
  'voting':       (_TypeMeta(Icons.how_to_vote_outlined, _pink,   'VOTING'       )),
  'hunt':         (_TypeMeta(Icons.explore_outlined,     _yellow, 'TREASURE HUNT')),
  'external':     (_TypeMeta(Icons.open_in_new,          _purple, 'EXTERNAL GAME')),
  'announcement': (_TypeMeta(Icons.campaign_outlined,    _cyan,   'ANNOUNCEMENT' )),
};

class _TypeMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeMeta(this.icon, this.color, this.label);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// LiveEventLobbyScreen
///
/// Polls /api/flutter/events/status every [_kPollSeconds] seconds.
/// When an activity goes live, shows an ANIMATE-IN banner and optionally
/// navigates to the correct activity screen.
/// ─────────────────────────────────────────────────────────────────────────────
class LiveEventLobbyScreen extends ConsumerStatefulWidget {
  final Event event;
  final String participantId;

  const LiveEventLobbyScreen({
    super.key,
    required this.event,
    required this.participantId,
  });

  @override
  ConsumerState<LiveEventLobbyScreen> createState() => _LiveEventLobbyScreenState();
}

class _LiveEventLobbyScreenState extends ConsumerState<LiveEventLobbyScreen>
    with TickerProviderStateMixin {
  late final EventEngineService _engine;
  late final Timer _pollTimer;

  EventStatusResponse? _status;
  String? _previousActivityId;
  bool _loading = true;
  bool _navigating = false;
  String? _error;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Use the Riverpod-managed service (properly configured ApiClient)
    _engine = ref.read(eventEngineServiceProvider);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _poll();
    _pollTimer = Timer.periodic(
      const Duration(seconds: _kPollSeconds),
      (_) => _poll(),
    );
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await _engine.getEventStatus(widget.event.id);
      if (!mounted) return;

      final newActivity = status.activeActivity;
      final newId = newActivity?.id;

      setState(() {
        _status = status;
        _loading = false;
        _error = null;
      });

      // New activity just went live → show alert
      if (newId != null && newId != _previousActivityId && !_navigating) {
        _previousActivityId = newId;
        _showActivityAlert(newActivity!);
      }

      // Activity ended
      if (newId == null && _previousActivityId != null) {
        _previousActivityId = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showActivityAlert(LiveActivity activity) {
    final meta = _typeMeta[activity.type] ?? _typeMeta['announcement']!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ActivityAlertDialog(
        activity: activity,
        meta: meta,
        onJoin: () {
          Navigator.of(ctx).pop();
          _navigateToActivity(activity);
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _navigateToActivity(LiveActivity activity) {
    if (_navigating) return;
    setState(() => _navigating = true);

    Widget? screen;
    switch (activity.type) {
      case 'quiz':
        screen = QuizModeScreen(
          event: widget.event,
          participantId: widget.participantId,
          activity: activity,
        );
        break;
      case 'voting':
        screen = VotingModeScreen(
          event: widget.event,
          participantId: widget.participantId,
          activity: activity,
        );
        break;
      case 'hunt':
        screen = TreasureHuntScreen(
          event: widget.event,
          participantId: widget.participantId,
          activity: activity,
        );
        break;
      case 'external':
        screen = LiveExternalScreen(
          event: widget.event,
          participantId: widget.participantId,
          activity: activity,
        );
        break;
      case 'announcement':
        screen = LiveAnnouncementScreen(activity: activity);
        break;
    }

    if (screen != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen!))
          .then((_) => setState(() => _navigating = false));
    } else {
      setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _status?.activeActivity;
    final meta = live != null ? _typeMeta[live.type] : null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.event.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _poll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : Column(
              children: [
                // ── Live Activity Banner ──────────────────────────────────
                // Safe conditional — AnimatedCrossFade builds both children
                // simultaneously, causing live!/meta! null crash when no activity.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: live != null
                      ? _LiveBanner(
                          key: ValueKey(live.id),
                          activity: live,
                          meta: meta ?? _typeMeta['announcement']!,
                          onJoin: () => _navigateToActivity(live),
                          pulseController: _pulseController,
                        )
                      : _WaitingBanner(key: const ValueKey('waiting')),
                ),

                // ── Error ────────────────────────────────────────────────
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Connection issue — retrying every ${_kPollSeconds}s',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                // ── Available Activities ─────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'AVAILABLE THIS EVENT',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildActivityCards(live),
                    ],
                  ),
                ),

                // ── Polling indicator ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'AUTO-SYNC EVERY ${_kPollSeconds}S',
                    style: const TextStyle(
                      color: Colors.white12,
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildActivityCards(LiveActivity? live) {
    final types = [
      ('quiz',     Icons.quiz_outlined,        _cyan,   'Quiz'),
      ('voting',   Icons.how_to_vote_outlined, _pink,   'Voting'),
      ('hunt',     Icons.explore_outlined,     _yellow, 'Treasure Hunt'),
      ('external', Icons.open_in_new,          _purple, 'External Game'),
    ];

    return types.map((t) {
      final (type, icon, color, label) = t;
      final isLive = live?.type == type;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ActivityCard(
          icon: icon,
          label: label,
          color: color,
          isLive: isLive,
          onTap: isLive && live != null
              ? () => _navigateToActivity(live)
              : null,
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: types.indexOf(t) * 80));
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LiveBanner extends StatelessWidget {
  final LiveActivity activity;
  final _TypeMeta meta;
  final VoidCallback onJoin;
  final AnimationController pulseController;

  const _LiveBanner({
    super.key,
    required this.activity,
    required this.meta,
    required this.onJoin,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final glow = pulseController.value;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: meta.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: meta.color.withOpacity(0.4 + glow * 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: meta.color.withOpacity(0.15 + glow * 0.15), blurRadius: 20, spreadRadius: 2)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: _green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE NOW · ${meta.label}',
                          style: TextStyle(color: meta.color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.title,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onJoin,
                style: TextButton.styleFrom(
                  backgroundColor: meta.color,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('JOIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97));
      },
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.hourglass_empty, color: Colors.white30, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WAITING FOR ADMIN', style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('No activity is live right now', style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLive;
  final VoidCallback? onTap;

  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isLive ? color.withOpacity(0.08) : Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLive ? color.withOpacity(0.5) : Colors.white10, width: isLive ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isLive ? color : Colors.white30, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isLive ? Colors.white : Colors.white38,
                  fontWeight: isLive ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              )
            else
              Icon(Icons.lock_outline, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ActivityAlertDialog extends StatelessWidget {
  final LiveActivity activity;
  final _TypeMeta meta;
  final VoidCallback onJoin;
  final VoidCallback onDismiss;

  const _ActivityAlertDialog({
    required this.activity,
    required this.meta,
    required this.onJoin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: meta.color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: meta.color, size: 32),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5))
                .fade(),
            const SizedBox(height: 20),
            Text(
              'NEW ACTIVITY LIVE!',
              style: TextStyle(color: meta.color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              activity.title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              meta.label,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('LATER', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: meta.color,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('JOIN NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
