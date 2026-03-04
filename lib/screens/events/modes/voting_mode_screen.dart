import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';

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
  String _topic = "IS ARTIFICIAL INTELLIGENCE THE FUTURE?";
  List<dynamic> _options = [
    {'id': 'in-favour', 'label': 'IN FAVOUR', 'desc': 'Yes, it enhances humans', 'icon': 'thumb_up'},
    {'id': 'against', 'label': 'AGAINST', 'desc': 'No, it replaces humans', 'icon': 'thumb_down'},
  ];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVotingConfig();
  }

  Future<void> _loadVotingConfig() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final modeData = await repo.getEventMode(widget.event.id, EventModeType.voting);
      
      final List<dynamic>? topics = modeData.config['topics'];
      
      setState(() {
        if (topics != null && topics.isNotEmpty) {
          _topic = "LIVE POLL: ${widget.event.title}";
          _options = topics.map((t) => {
            'id': t.toString().toLowerCase().replaceAll(' ', '_'),
            'label': t.toString().toUpperCase(),
            'desc': 'Cast your vote for this option',
            'icon': 'how_to_vote'
          }).toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitVote() async {
    if (_selectedOption == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      // In a real app, you'd get the user's email from a provider
      const userEmail = "test@example.com"; 
      
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/api/flutter/eventmode/voting',
        data: {
          'eventId': widget.event.id,
          'email': userEmail,
          'status': 'voted',
          'data': {'option': _selectedOption}
        }
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vote Submitted successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit vote: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _getIcon(String? iconName) {
    if (iconName == 'thumb_up') return Icons.thumb_up_alt_outlined;
    if (iconName == 'thumb_down') return Icons.thumb_down_alt_outlined;
    return Icons.how_to_vote_outlined;
  }

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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: cyan))
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: cyan, size: 80).animate().scale().shimmer(),
                const SizedBox(height: 40),
                Text(
                  _topic.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  "Cast your vote now. One vote per participant.",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 60),

                ..._options.map((opt) => Column(
                  children: [
                    _votingOption(
                      opt['label'] as String, 
                      opt['desc'] as String, 
                      _getIcon(opt['icon'] as String?), 
                      opt['id'] == 'against' ? Colors.redAccent : cyan,
                      opt['id'] as String
                    ),
                    const SizedBox(height: 20),
                  ],
                )),
                
                const Spacer(),
                if (_selectedOption != null)
                  _isSubmitting 
                    ? const CircularProgressIndicator(color: cyan)
                    : CyberButton(
                        onPressed: _submitVote,
                        text: "SUBMIT VOTE",
                        color: cyan,
                      ).animate().fadeIn().scale(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _votingOption(String title, String desc, IconData icon, Color color, String id) {
    final isSelected = _selectedOption == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = id),
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
