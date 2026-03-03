import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';

class TreasureHuntScreen extends ConsumerStatefulWidget {
  final Event event;

  const TreasureHuntScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends ConsumerState<TreasureHuntScreen> {
  int _clueCount = 5;
  int _currentClueIndex = 0;
  String _currentClue = "Loading clues...";
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
      
      // Get progress from registration if available
      final registrations = await repo.getMyRegistrations("test@example.com"); // Get from provider in real app
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
        _currentClue = "Find the first clue near the entrance!";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const gold = Colors.amber;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("TREASURE HUNT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: gold))
        : Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CyberGlassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.map_outlined, color: gold, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        "CLUE #${_currentClueIndex + 1}",
                        style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentClue,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
                
                const SizedBox(height: 40),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "YOUR PROGRESS",
                    style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_clueCount, (index) => _buildProgressTile(index, index <= _currentClueIndex)),
                ),

                const Spacer(),
                CyberButton(
                  onPressed: () {
                    // Navigate to scanner (stub)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("QR Scanner opening... (Scan the clue to proceed)"))
                    );
                  },
                  text: "SCAN CLUE CODE",
                  icon: Icons.qr_code_scanner,
                  color: gold,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildProgressTile(int index, bool discovered) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: discovered ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: discovered ? Colors.amber : Colors.white10),
      ),
      child: Center(
        child: Icon(
          discovered ? Icons.check : Icons.lock_outline,
          color: discovered ? Colors.amber : Colors.white24,
          size: 20,
        ),
      ),
    );
  }
}
