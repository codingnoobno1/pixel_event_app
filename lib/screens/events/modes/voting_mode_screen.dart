import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';

class VotingModeScreen extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity? activity;  // Set by LiveEventLobbyScreen
  final String? participantId;

  const VotingModeScreen({
    super.key,
    required this.event,
    this.activity,
    this.participantId,
  });

  @override
  ConsumerState<VotingModeScreen> createState() => _VotingModeScreenState();
}

class _VotingModeScreenState extends ConsumerState<VotingModeScreen> {
  String? _selectedOption;
  String _topic = "INITIALIZING_POLL_DATA...";
  List<dynamic> _options = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _loadVotingConfig();
  }

  Future<void> _loadVotingConfig() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final modeData = await repo.getEventMode(widget.event.id, EventModeType.voting);
      
      // Get progress for this user
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      final registration = (await repo.getMyRegistrations(user?.email ?? "test@example.com")).firstWhere((r) => r.eventId == widget.event.id);
      final progress = registration.modeProgress?.firstWhere((p) => p.mode == 'voting', orElse: () => const ModeProgress(mode: 'voting', status: 'not-voted', score: 0));

      final List<dynamic>? topics = modeData.config['topics'];
      
      setState(() {
        _hasVoted = progress?.status == 'voted';
        if (topics != null && topics.isNotEmpty) {
          _topic = widget.event.title.toUpperCase();
          _options = topics.map((t) => {
            'id': t.toString().toLowerCase().replaceAll(' ', '_'),
            'label': t.toString().toUpperCase(),
            'desc': 'Cast your tactical vote for this option',
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
    if (_selectedOption == null || _hasVoted) return;
    
    setState(() => _isSubmitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      final userEmail = user?.email ?? "test@example.com"; 
      
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
        setState(() {
           _hasVoted = true;
           _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SYSTEM: VOTE_TRANSMITTED_SUCCESSFULLY"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SYSTEM_ERROR: LINK_FAILURE - ${e.toString().toUpperCase()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _getIcon(String? iconName) {
    return Icons.how_to_vote_rounded;
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
          "TACTICAL_VOTING_INITIATED",
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CyberLoading(message: "ESTABLISHING_VOTING_UPLINK"))
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CyberGlassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.how_to_vote_rounded, color: cyan, size: 50),
                      const SizedBox(height: 20),
                      Text(
                        "LIVE_POLL_TOPIC",
                        style: GoogleFonts.jetBrainsMono(color: cyan, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _topic,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 32),

                Expanded(
                  child: ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final opt = _options[index];
                      return _votingOption(
                        opt['label'] as String, 
                        opt['desc'] as String, 
                        _getIcon(opt['icon'] as String?), 
                        cyan,
                        opt['id'] as String
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                if (_hasVoted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "TRANSMISSION_VERIFIED",
                          style: GoogleFonts.jetBrainsMono(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ).animate().fadeIn()
                else if (_selectedOption != null)
                  _isSubmitting 
                    ? const Center(child: CircularProgressIndicator(color: cyan))
                    : CyberButton(
                        onPressed: _submitVote,
                        text: "TRANSMIT_SELECTION",
                        icon: Icons.send_rounded,
                        color: cyan,
                      ).animate().fadeIn().scale(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _votingOption(String title, String desc, IconData icon, Color color, String id) {
    if (_hasVoted) {
       // Disable interaction if already voted
       return Container(
         margin: const EdgeInsets.only(bottom: 16),
         child: CyberCard(
           color: Colors.white.withOpacity(0.02),
           child: Row(
             children: [
               Icon(icon, color: Colors.white10),
               const SizedBox(width: 16),
               Expanded(
                 child: Text(title, style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
               ),
             ],
           ),
         ),
       );
    }
    final isSelected = _selectedOption == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CyberCard(
        onTap: () => setState(() => _selectedOption = id),
        color: isSelected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.02),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.jetBrainsMono(color: isSelected ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(desc, style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 9)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.radio_button_checked_rounded, color: color)
            else Icon(Icons.radio_button_off_rounded, color: Colors.white10),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * _options.indexWhere((opt) => opt['id'] == id)).ms);
  }
}
