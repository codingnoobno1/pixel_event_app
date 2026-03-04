import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';
import '../../../widgets/events/hunt_qr_scanner.dart';

class TreasureHuntScreen extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity? activity;  // Set by LiveEventLobbyScreen
  final String? participantId;

  const TreasureHuntScreen({
    super.key,
    required this.event,
    this.activity,
    this.participantId,
  });

  @override
  ConsumerState<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends ConsumerState<TreasureHuntScreen> {
  int _clueCount = 5;
  int _currentClueIndex = 0;
  String _currentClue = "INITIALIZING_SYSTEM...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTreasureHuntConfig();
  }

  Future<void> _loadTreasureHuntConfig() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final modeData = await repo.getEventMode(widget.event.id, EventModeType.treasureHunt);
      
      // Get progress from registration
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      final registrations = await repo.getMyRegistrations(user?.email ?? "test@example.com");
      final myReg = registrations.firstWhere((r) => r.eventId == widget.event.id);
      final progress = myReg.modeProgress?.firstWhere((p) => p.mode == 'treasure-hunt', orElse: () => const ModeProgress(mode: 'treasure-hunt', status: 'start', score: 0));

      setState(() {
        _clueCount = modeData.config['clueCount'] ?? 5;
        final clues = modeData.config['clues'] as List<dynamic>? ?? [
          "Where the data flows and the servers hum, look for the flashing red light.",
          "Check the central atrium near the spiral staircase.",
          "Look behind the main stage entrance.",
        ];
        _currentClueIndex = (progress?.score.toInt() ?? 0).clamp(0, clues.length - 1);
        _currentClue = clues[_currentClueIndex];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentClue = "LOCATING_PRIMARY_OBJECTIVE...";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const cyan = Color(0xFF00FFFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "TREASURE_HUNT_VAULT",
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CyberLoading(message: "DECRYPTING_HUNT_DATA"))
        : Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CyberGlassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.radar_rounded, color: cyan, size: 50),
                      const SizedBox(height: 20),
                      Text(
                        "OBJECTIVE_MARKER_${_currentClueIndex + 1}",
                        style: GoogleFonts.jetBrainsMono(color: cyan, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentClue.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 48),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "CHECKPOINT_PROGRESS",
                    style: GoogleFonts.jetBrainsMono(color: cyan.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 20),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(_clueCount, (index) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildProgressTile(index, index <= _currentClueIndex),
                    )),
                  ),
                ),

                const Spacer(),
                CyberButton(
                  onPressed: () async {
                    // Navigate to real scanner
                    final checkpoint = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HuntQrScanner(
                          event: widget.event,
                          participantId: "test@example.com", // TODO: Get from ref.read(authServiceProvider).currentUser
                        ),
                      ),
                    );

                    if (checkpoint != null && mounted) {
                      _loadTreasureHuntConfig(); // Refresh progress
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("SYSTEM: LINK_ESTABLISHED. CHECKPOINT_${checkpoint['id'] ?? ''}_SAVED"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  text: "INITIATE_SCAN",
                  icon: Icons.qr_code_scanner_rounded,
                  color: cyan,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildProgressTile(int index, bool discovered) {
    const cyan = Color(0xFF00FFFF);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: discovered ? cyan.withOpacity(0.1) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: discovered ? cyan.withOpacity(0.5) : Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Center(
        child: Icon(
          discovered ? Icons.verified_rounded : Icons.lock_rounded,
          color: discovered ? cyan : Colors.white10,
          size: 20,
        ),
      ),
    );
  }
}
