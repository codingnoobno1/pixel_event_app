import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';

class QuizModeScreen extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity? activity;  // Set by LiveEventLobbyScreen
  final String? participantId;

  const QuizModeScreen({
    super.key,
    required this.event,
    this.activity,
    this.participantId,
  });

  @override
  ConsumerState<QuizModeScreen> createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends ConsumerState<QuizModeScreen> {
  List<dynamic> _subModes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizConfig();
  }

  Future<void> _loadQuizConfig() async {
    final String? quizId = widget.event.activeModeQuizId;
    final modeConfig = widget.event.modes?.firstWhere((m) => m.type == 'quiz', orElse: () => const EventMode(type: 'quiz', config: {})).config;
    final int? timeLimit = modeConfig?['timeLimit'];

    setState(() {
      if (quizId != null && widget.event.activeModeType == 'quiz') {
        _subModes = [
          {
            'id': 'live-quiz', 
            'name': 'OFFICIAL EVENT QUIZ', 
            'description': 'SYNCED CHALLENGE: ${timeLimit ?? 30}S PER MODULE.', 
            'icon': 'stars',
            'quizId': quizId
          },
        ];
      } else {
        _subModes = [
          {'id': 'rapid-fire', 'name': 'RAPID_FIRE_PROTOCOL', 'description': '10S LIMIT. MAX COGNITIVE LOAD.', 'icon': 'bolt'},
          {'id': 'long-thinking', 'name': 'ANALYTICAL_DEEP_DIVE', 'description': 'COMPLEX SCENARIOS. DEPTH VERIFICATION.', 'icon': 'psychology'},
        ];
      }
      _isLoading = false;
    });
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'bolt': return Icons.bolt_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'school': return Icons.school_rounded;
      case 'stars': return Icons.stars_rounded;
      default: return Icons.quiz_rounded;
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
          "ARENA_QUIZ_SYSTEM",
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CyberLoading(message: "SYNCING_ARENA_PROTOCOLS"))
        : Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT_CONTEST_MODULE",
                  style: GoogleFonts.jetBrainsMono(color: cyan, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: _subModes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final mode = _subModes[index];
                      return _buildSubModeCard(
                        _getIcon(mode['icon'] as String?),
                        (mode['name'] as String? ?? 'QUIZ').toUpperCase(),
                        mode['description'] as String? ?? 'Iniate challenge sequence',
                        index
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSubModeCard(IconData icon, String title, String desc, int index) {
    const cyan = Color(0xFF00FFFF);
    return CyberCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to actual quiz engine
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyan.withOpacity(0.2)),
                ),
                child: Icon(icon, color: cyan, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 9, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
