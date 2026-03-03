import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

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
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CyberGlassCard(
              child: Column(
                children: [
                  const Icon(Icons.map_outlined, color: gold, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    "CLUE #1",
                    style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Where the data flows and the servers hum, look for the flashing red light.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
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
              children: List.generate(5, (index) => _buildProgressTile(index, index == 0)),
            ),

            const Spacer(),
            CyberButton(
              onPressed: () {
                // Navigate to scanner
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
