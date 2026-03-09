import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VotingModeScreen
//
// Fully driven by widget.activity (LiveActivity from lobby poll).
// Maps directly to what admin enters in stud_admin:
//   - voting.question   → poll question text
//   - voting.options[]  → one option per line (strings from DB)
//   - voting.showLiveResults → show bar chart after voting
//   - voting.votingDurationSeconds → countdown timer
//   - voting.allowMultiple → allow/block duplicate vote
//
// Submits to /api/flutter/events/vote (new engine API).
// On DUPLICATE_VOTE (409), shows "already voted" state gracefully.
// If showLiveResults=true, polls /api/flutter/events/vote GET
// every 5s to show live bar chart.
// ─────────────────────────────────────────────────────────────────────────────

const _cyan   = Color(0xFF00FFFF);
const _pink   = Color(0xFFFF2E88);
const _green  = Color(0xFF00FF64);
const _yellow = Color(0xFFFFD700);
const _bg     = Color(0xFF0B0B0F);

class VotingModeScreen extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity? activity;
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
  bool _hasVoted = false;
  bool _isSubmitting = false;
  int _timeLeft = 0;
  Timer? _countdownTimer;
  Timer? _resultTimer;
  Map<String, Map<String, dynamic>>? _liveResults; // option → {count, percentage}
  int _totalVotes = 0;

  VotingData? get _voting => widget.activity?.voting;
  String get _activityId => widget.activity?.id ?? '';
  String get _participantId => widget.participantId ?? widget.event.id;

  @override
  void initState() {
    super.initState();
    _timeLeft = _voting?.votingDurationSeconds ?? 60;

    // Countdown timer
    if (_timeLeft > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_timeLeft <= 1) {
          t.cancel();
          setState(() => _timeLeft = 0);
        } else {
          setState(() => _timeLeft--);
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitVote() async {
    if (_selectedOption == null || _hasVoted || _isSubmitting) return;
    if (_timeLeft == 0) return; // voting closed

    setState(() => _isSubmitting = true);

    try {
      final engine = ref.read(eventEngineServiceProvider);
      final result = await engine.submitVote(
        activityId: _activityId,
        participantId: _participantId,
        option: _selectedOption!,
      );

      if (!mounted) return;

      setState(() {
        _hasVoted = true;
        _isSubmitting = false;
      });

      // Start polling live results if server returned them or showLiveResults is on
      if (_voting?.showLiveResults == true) {
        _buildResults(result['results'] as Map<String, dynamic>?);
        _startResultPolling();
      }

    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      if (errMsg.contains('DUPLICATE_VOTE') || errMsg.contains('409') || errMsg.contains('already voted')) {
        setState(() {
          _hasVoted = true;
          _isSubmitting = false;
        });
        _startResultPolling(); // still show results
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VOTE_ERROR: ${errMsg.toUpperCase()}'),
            backgroundColor: _pink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _buildResults(Map<String, dynamic>? raw) {
    if (raw == null) return;
    final parsed = raw.map((k, v) => MapEntry(k, {
          'count': (v as Map)['count'] ?? 0,
          'percentage': (v as Map)['percentage'] ?? 0,
        }));
    setState(() => _liveResults = parsed);
  }

  void _startResultPolling() {
    _resultTimer?.cancel();
    _resultTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !(_voting?.showLiveResults ?? false)) return;
      try {
        final engine = ref.read(eventEngineServiceProvider);
        final data = await engine.getVoteResults(_activityId);
        if (!mounted) return;
        _buildResults(data['results'] as Map<String, dynamic>?);
        setState(() => _totalVotes = data['total'] as int? ?? 0);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = _voting;
    if (v == null) {
      return _NoVotingScaffold(event: widget.event);
    }

    final options = v.options;
    final elapsed = (v.votingDurationSeconds > 0) ? (_timeLeft / v.votingDurationSeconds).clamp(0.0, 1.0) : 0.0;
    final votingOpen = _timeLeft > 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('LIVE POLL', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: _pink)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (votingOpen)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _pink, size: 14),
                  const SizedBox(width: 4),
                  Text('${_timeLeft}s',
                      style: GoogleFonts.jetBrainsMono(
                          color: _timeLeft < 10 ? _pink : Colors.white60,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),

      body: Column(
        children: [
          // Countdown progress
          if (v.votingDurationSeconds > 0)
            LinearProgressIndicator(
              value: elapsed,
              backgroundColor: Colors.white12,
              color: _timeLeft < 10 ? _pink : _cyan,
              minHeight: 3,
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Poll question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pink.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.how_to_vote_rounded, color: _pink, size: 32),
                      const SizedBox(height: 16),
                      Text(
                        !votingOpen && !_hasVoted ? 'VOTING CLOSED' : 'LIVE POLL',
                        style: GoogleFonts.jetBrainsMono(color: _pink, fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        v.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.4),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Voted confirmation banner
                if (_hasVoted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: _green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'VOTE TRANSMITTED · YOU CHOSE: ${(_selectedOption ?? '').toUpperCase()}',
                            style: GoogleFonts.jetBrainsMono(color: _green, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                // Options — with live result bars if voted + showLiveResults
                ...List.generate(options.length, (i) {
                  final opt = options[i];
                  final isSelected = _selectedOption == opt;
                  final pct = (_liveResults?[opt]?['percentage'] as int?) ?? 0;
                  final cnt = (_liveResults?[opt]?['count'] as int?) ?? 0;
                  final showBar = _hasVoted && _voting!.showLiveResults && _liveResults != null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: (!_hasVoted && votingOpen) ? () => setState(() => _selectedOption = opt) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected && !_hasVoted
                              ? _pink.withOpacity(0.09)
                              : _hasVoted && _selectedOption == opt
                                  ? _green.withOpacity(0.07)
                                  : Colors.white.withOpacity(0.025),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected && !_hasVoted
                                ? _pink.withOpacity(0.5)
                                : _hasVoted && _selectedOption == opt
                                    ? _green.withOpacity(0.4)
                                    : Colors.white12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Option indicator
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? _pink.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                                    border: Border.all(color: isSelected ? _pink : Colors.white24),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: _pink, size: 13)
                                      : Center(
                                          child: Text(String.fromCharCode(65 + i),
                                              style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(opt,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      )),
                                ),
                                if (showBar)
                                  Text('$pct%',
                                      style: GoogleFonts.jetBrainsMono(
                                          color: _selectedOption == opt ? _green : Colors.white38,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12)),
                                if (showBar) ...[
                                  const SizedBox(width: 6),
                                  Text('($cnt)', style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 10)),
                                ],
                              ],
                            ),

                            // Live result bar
                            if (showBar) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100.0,
                                  backgroundColor: Colors.white.withOpacity(0.06),
                                  color: _selectedOption == opt ? _green : _pink.withOpacity(0.4),
                                  minHeight: 6,
                                ),
                              ).animate().slideX(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
                            ],
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 70).ms).slideY(begin: 0.05),
                  );
                }),

                // Total votes
                if (_hasVoted && _voting!.showLiveResults && _totalVotes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'TOTAL VOTES: $_totalVotes · AUTO-UPDATE EVERY 5S',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 9, letterSpacing: 1.5),
                    ),
                  ),

                // Voting closed banner
                if (!votingOpen && !_hasVoted)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text('Voting time has ended. You did not cast a vote.',
                        style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),

          // Submit bar
          if (!_hasVoted && votingOpen)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedOption != null && !_isSubmitting ? _submitVote : null,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _selectedOption == null ? 'SELECT AN OPTION FIRST' : 'CAST VOTE',
                    style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedOption != null ? _pink : Colors.white12,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoVotingScaffold extends StatelessWidget {
  final Event event;
  const _NoVotingScaffold({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(event.title.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text('No vote is active right now', style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
