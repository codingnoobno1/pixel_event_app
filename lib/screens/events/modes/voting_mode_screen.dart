import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

class VotingModeScreen extends ConsumerStatefulWidget {
  final Event event;

  const VotingModeScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<VotingModeScreen> createState() => _VotingModeScreenState();
}

class _VotingModeScreenState extends ConsumerState<VotingModeScreen> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const cyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("LIVE VOTING", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote, color: cyan, size: 80).animate().scale().shimmer(),
            const SizedBox(height: 40),
            const Text(
              "IS ARTIFICIAL INTELLIGENCE THE FUTURE OF CREATIVITY?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              "Cast your vote now. One vote per participant.",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 60),

            _votingOption("IN FAVOUR", "Yes, it enhances humans", Icons.thumb_up_alt_outlined, cyan),
            const SizedBox(height: 20),
            _votingOption("AGAINST", "No, it replaces humans", Icons.thumb_down_alt_outlined, Colors.redAccent),
            
            const Spacer(),
            if (_selectedOption != null)
              CyberButton(
                onPressed: () {
                  // Submit vote
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vote Submitted successfully!"))
                  );
                },
                text: "SUBMIT VOTE",
                color: cyan,
              ).animate().fadeIn().scale(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _votingOption(String title, String desc, IconData icon, Color color) {
    final isSelected = _selectedOption == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white10, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
