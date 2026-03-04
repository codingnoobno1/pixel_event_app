import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/live_activity.dart';

/// Auto-dismissing announcement screen.
/// Shown when admin broadcasts an announcement.
/// Automatically pops after [AnnouncementData.displaySeconds] seconds.
class LiveAnnouncementScreen extends StatefulWidget {
  final LiveActivity activity;

  const LiveAnnouncementScreen({super.key, required this.activity});

  @override
  State<LiveAnnouncementScreen> createState() => _LiveAnnouncementScreenState();
}

class _LiveAnnouncementScreenState extends State<LiveAnnouncementScreen> {
  late int _remaining;
  Timer? _timer;

  static const _cyan = Color(0xFF00FFFF);
  static const _bg = Color(0xFF0B0B0F);

  @override
  void initState() {
    super.initState();
    _remaining = widget.activity.announcement?.displaySeconds ?? 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.activity.announcement?.message ?? '';
    final total = widget.activity.announcement?.displaySeconds ?? 15;
    final progress = _remaining / total;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _cyan.withOpacity(0.12), blurRadius: 120, spreadRadius: 40)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Timer countdown ring
                  Align(
                    alignment: Alignment.topRight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            color: _cyan,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        Text(
                          '$_remaining',
                          style: const TextStyle(color: _cyan, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _cyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _cyan.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.campaign_outlined, color: _cyan, size: 40),
                  ).animate().scale(duration: 400.ms).then().shake(hz: 2, duration: 300.ms),

                  const SizedBox(height: 24),

                  // Label
                  const Text(
                    'ANNOUNCEMENT',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message
                  Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const Spacer(),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
