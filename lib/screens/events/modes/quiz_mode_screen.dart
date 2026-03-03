import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';

class QuizModeScreen extends ConsumerStatefulWidget {
  final Event event;

  const QuizModeScreen({
    super.key,
    required this.event,
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
    try {
      final repo = ref.read(eventRepositoryProvider);
      final modeData = await repo.getEventMode(widget.event.id, EventModeType.quiz);
      setState(() {
        _subModes = modeData.config['subModes'] ?? [
          {'id': 'rapid-fire', 'name': 'RAPID FIRE', 'description': '10 seconds per question. Think fast!', 'icon': 'bolt'},
          {'id': 'long-thinking', 'name': 'DEEP DIVE', 'description': 'Complex scenarios. Depth matters.', 'icon': 'psychology'},
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'bolt': return Icons.bolt;
      case 'psychology': return Icons.psychology;
      case 'school': return Icons.school;
      case 'stars': return Icons.stars;
      default: return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("QUIZ ZONE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: pink))
        : Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SELECT CATEGORY",
                  style: TextStyle(color: pink, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
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
                        mode['description'] as String? ?? 'Start your challenge',
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
    const pink = Color(0xFFFF2E88);
    return CyberCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to actual quiz engine with submode
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: pink),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
