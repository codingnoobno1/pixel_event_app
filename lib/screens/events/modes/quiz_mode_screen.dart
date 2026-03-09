import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuizModeScreen — Routes to the correct sub-engine based on quizType:
//
//  rapid_fire   → Timed auto-advance quiz. 1 question at a time, countdown.
//  custom_live  → Admin-controlled. Polls every 5s for currentQuestion changes.
//  preloaded    → All questions at once. User self-paces and submits together.
//
// All 3 modes read from widget.activity (LiveActivity from the lobby poll).
// ─────────────────────────────────────────────────────────────────────────────

const _cyan   = Color(0xFF00FFFF);
const _pink   = Color(0xFFFF2E88);
const _green  = Color(0xFF00FF64);
const _yellow = Color(0xFFFFD700);
const _bg     = Color(0xFF0B0B0F);

class QuizModeScreen extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity? activity;
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
  @override
  Widget build(BuildContext context) {
    final quiz = widget.activity?.quiz;

    if (quiz == null) {
      return _NoActivityScaffold(event: widget.event);
    }

    final type = quiz.quizType ?? 'rapid_fire';

    switch (type) {
      case 'rapid_fire':
        return _RapidFireQuiz(
          event: widget.event,
          activity: widget.activity!,
          participantId: widget.participantId ?? '',
        );
      case 'custom_live':
        return _CustomLiveQuiz(
          event: widget.event,
          activity: widget.activity!,
          participantId: widget.participantId ?? '',
          engine: ref.read(eventEngineServiceProvider),
        );
      case 'preloaded':
        return _PreloadedQuiz(
          event: widget.event,
          activity: widget.activity!,
          participantId: widget.participantId ?? '',
        );
      default:
        return _RapidFireQuiz(
          event: widget.event,
          activity: widget.activity!,
          participantId: widget.participantId ?? '',
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RAPID_FIRE — Timed, auto-advance
// ─────────────────────────────────────────────────────────────────────────────

class _RapidFireQuiz extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity activity;
  final String participantId;

  const _RapidFireQuiz({required this.event, required this.activity, required this.participantId});

  @override
  ConsumerState<_RapidFireQuiz> createState() => _RapidFireQuizState();
}

class _RapidFireQuizState extends ConsumerState<_RapidFireQuiz> with SingleTickerProviderStateMixin {
  int _current = 0;
  String? _selected;
  int _score = 0;
  bool _answered = false;
  late int _timeLeft;
  Timer? _timer;
  bool _done = false;
  List<Map<String, dynamic>> _results = [];
  // For server submission
  final List<Map<String, String>> _submittedAnswers = [];
  late final DateTime _startedAt;

  List<QuizQuestion> get _questions => widget.activity.quiz?.questions ?? [];
  int get _timePerQ => widget.activity.quiz?.timePerQuestion ?? 10;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timeLeft = _timePerQ;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        t.cancel();
        _autoAdvance();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _autoAdvance() {
    if (_answered) return;
    _recordAnswer(null); // timed out
  }

  void _selectAnswer(String option) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selected = option;
      _answered = true;
    });
    final q = _questions[_current];
    final correct = q.correctAnswer ?? '';
    final isCorrect = option == correct;
    if (isCorrect) _score += q.points;
    _results.add({'q': q.text, 'picked': option, 'correct': correct, 'isCorrect': isCorrect});
    _submittedAnswers.add({'questionId': q.id, 'selectedOption': option});
    Future.delayed(const Duration(milliseconds: 1200), _next);
  }

  void _recordAnswer(String? option) {
    final q = _questions[_current];
    _results.add({'q': q.text, 'picked': option, 'correct': q.correctAnswer ?? '', 'isCorrect': false});
    _submittedAnswers.add({'questionId': q.id, 'selectedOption': option ?? ''});
    _next();
  }

  void _next() {
    if (!mounted) return;
    if (_current + 1 >= _questions.length) {
      _finishQuiz();
      return;
    }
    setState(() {
      _current++;
      _selected = null;
      _answered = false;
    });
    _startTimer();
  }

  Future<void> _finishQuiz() async {
    final secs = DateTime.now().difference(_startedAt).inSeconds;
    setState(() => _done = true);
    // Submit to server in the background — UI already shows result
    try {
      final engine = ref.read(eventEngineServiceProvider);
      await engine.submitQuiz(
        activityId: widget.activity.id,
        participantId: widget.participantId,
        answers: _submittedAnswers,
        timeTakenSeconds: secs,
      );
    } catch (_) {
      // Silent — local results still shown; server may accept retry later
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _ResultScreen(score: _score, results: _results, activityTitle: widget.activity.title);
    if (_questions.isEmpty) return _NoActivityScaffold(event: widget.event);

    final q = _questions[_current];
    final progress = _timeLeft / _timePerQ;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.activity.title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('${_current + 1}/${_questions.length}',
                  style: const TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.w900)),
              backgroundColor: _cyan.withOpacity(0.08),
              side: BorderSide(color: _cyan.withOpacity(0.3)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer bar
          Container(
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              color: progress < 0.25 ? _pink : _cyan,
            ),
          ),
          // Timer digits
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RAPID_FIRE', style: GoogleFonts.jetBrainsMono(color: Colors.white30, fontSize: 9, letterSpacing: 2)),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: _cyan, size: 14),
                    const SizedBox(width: 4),
                    Text('$_timeLeft', style: GoogleFonts.jetBrainsMono(color: _cyan, fontWeight: FontWeight.w900, fontSize: 14)),
                    Text('s', style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                Text('SCORE: $_score', style: GoogleFonts.jetBrainsMono(color: _green, fontSize: 9, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cyan.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cyan.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${_current + 1}',
                            style: GoogleFonts.jetBrainsMono(color: _cyan, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(q.text,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
                        if (q.points > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text('+${q.points} PTS',
                                style: GoogleFonts.jetBrainsMono(color: _yellow, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),

                  const SizedBox(height: 24),
                  ...List.generate(q.options.length, (i) {
                    final opt = q.options[i];
                    return _OptionTile(
                      label: opt,
                      index: i,
                      isSelected: _selected == opt,
                      isCorrect: _answered ? (opt == (q.correctAnswer ?? '')) : null,
                      onTap: _answered ? null : () => _selectAnswer(opt),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM_LIVE — Admin controls which question is shown. Polls every 5s.
// ─────────────────────────────────────────────────────────────────────────────

class _CustomLiveQuiz extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity activity;
  final String participantId;
  final EventEngineService engine;

  const _CustomLiveQuiz({required this.event, required this.activity, required this.participantId, required this.engine});

  @override
  ConsumerState<_CustomLiveQuiz> createState() => _CustomLiveQuizState();
}

class _CustomLiveQuizState extends ConsumerState<_CustomLiveQuiz> {
  late LiveActivity _liveActivity;
  Timer? _pollTimer;
  String? _selected;
  final Map<int, String> _answers = {}; // questionIndex → chosen option
  int _score = 0;
  String? _feedback;

  int get _currentQ => _liveActivity.quiz?.currentQuestion ?? 0;
  List<QuizQuestion> get _questions => _liveActivity.quiz?.questions ?? [];
  QuizQuestion? get _question => _questions.isNotEmpty && _currentQ < _questions.length ? _questions[_currentQ] : null;

  @override
  void initState() {
    super.initState();
    _liveActivity = widget.activity;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final status = await widget.engine.getEventStatus(widget.event.id);
      final updated = status.activeActivity;
      if (updated == null || !mounted) return;
      final newQ = updated.quiz?.currentQuestion ?? 0;
      if (newQ != _currentQ) {
        setState(() {
          _liveActivity = updated;
          _selected = _answers[newQ]; // restore if already answered
          _feedback = null;
        });
      }
    } catch (_) {}
  }

  void _select(String opt) {
    if (_answers.containsKey(_currentQ)) return; // already answered this Q
    final q = _question;
    if (q == null) return;
    final isCorrect = opt == (q.correctAnswer ?? '');
    if (isCorrect) _score += q.points;
    setState(() {
      _selected = opt;
      _answers[_currentQ] = opt;
      _feedback = isCorrect ? '✓ CORRECT' : '✗ WRONG — ${q.correctAnswer}';
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.activity.title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.sensors, color: _pink, size: 14),
                const SizedBox(width: 6),
                Text('ADMIN_CONTROLLED',
                    style: GoogleFonts.jetBrainsMono(color: _pink, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
      body: q == null
          ? Center(child: Text('Waiting for admin to set a question...', style: TextStyle(color: Colors.white38)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Q header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _pink.withOpacity(0.3)),
                        ),
                        child: Text('Q${_currentQ + 1} of ${_questions.length}',
                            style: GoogleFonts.jetBrainsMono(color: _pink, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Text('SCORE: $_score', style: GoogleFonts.jetBrainsMono(color: _green, fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Question text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _pink.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
                        if (q.points > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('+${q.points} PTS', style: GoogleFonts.jetBrainsMono(color: _yellow, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ).animate(key: ValueKey(_currentQ)).fadeIn().slideY(begin: 0.05),

                  const SizedBox(height: 24),

                  // Options
                  Expanded(
                    child: ListView(
                      children: [
                        ...List.generate(q.options.length, (i) {
                          final opt = q.options[i];
                          return _OptionTile(
                            label: opt,
                            index: i,
                            isSelected: _selected == opt,
                            isCorrect: _answers.containsKey(_currentQ) ? (opt == (q.correctAnswer ?? '')) : null,
                            onTap: _answers.containsKey(_currentQ) ? null : () => _select(opt),
                          );
                        }),
                        if (_feedback != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _feedback!.startsWith('✓') ? _green.withOpacity(0.1) : _pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _feedback!.startsWith('✓') ? _green.withOpacity(0.3) : _pink.withOpacity(0.3)),
                              ),
                              child: Text(_feedback!,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: _feedback!.startsWith('✓') ? _green : _pink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  )),
                            ).animate().fadeIn(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRELOADED — All questions at once. Self-paced. Submit together.
// ─────────────────────────────────────────────────────────────────────────────

class _PreloadedQuiz extends ConsumerStatefulWidget {
  final Event event;
  final LiveActivity activity;
  final String participantId;

  const _PreloadedQuiz({required this.event, required this.activity, required this.participantId});

  @override
  ConsumerState<_PreloadedQuiz> createState() => _PreloadedQuizState();
}

class _PreloadedQuizState extends ConsumerState<_PreloadedQuiz> {
  final Map<int, String> _answers = {};
  bool _submitted = false;
  bool _isSubmitting = false;
  int _score = 0;
  late final DateTime _startedAt;

  List<QuizQuestion> get _questions => widget.activity.quiz?.questions ?? [];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    int sc = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (_answers[i] == (q.correctAnswer ?? '')) sc += q.points;
    }
    // Build answer list for server
    final serverAnswers = List.generate(_questions.length, (i) => {
      'questionId': _questions[i].id,
      'selectedOption': _answers[i] ?? '',
    });
    // Submit to server (server grades authoritatively)
    try {
      final engine = ref.read(eventEngineServiceProvider);
      await engine.submitQuiz(
        activityId: widget.activity.id,
        participantId: widget.participantId,
        answers: serverAnswers,
        timeTakenSeconds: DateTime.now().difference(_startedAt).inSeconds,
      );
    } catch (_) { /* Silent — still show local result */ }
    setState(() {
      _score = sc;
      _submitted = true;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ResultScreen(
        score: _score,
        activityTitle: widget.activity.title,
        results: List.generate(_questions.length, (i) {
          final q = _questions[i];
          final picked = _answers[i] ?? '—';
          return {
            'q': q.text,
            'picked': picked,
            'correct': q.correctAnswer ?? '',
            'isCorrect': picked == (q.correctAnswer ?? ''),
          };
        }),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.activity.title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('${_answers.length}/${_questions.length} answered',
                  style: const TextStyle(color: _yellow, fontSize: 10, fontWeight: FontWeight.w900)),
              backgroundColor: _yellow.withOpacity(0.08),
              side: BorderSide(color: _yellow.withOpacity(0.25)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _questions.length,
              itemBuilder: (ctx, i) {
                final q = _questions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.03),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          border: Border.all(color: _cyan.withOpacity(0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q${i + 1} · +${q.points} pts',
                                style: GoogleFonts.jetBrainsMono(color: _yellow, fontSize: 9, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(q.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _cyan.withOpacity(0.12)),
                            right: BorderSide(color: _cyan.withOpacity(0.12)),
                            bottom: BorderSide(color: _cyan.withOpacity(0.12)),
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: Column(
                          children: List.generate(q.options.length, (oi) {
                            final opt = q.options[oi];
                            final chosen = _answers[i] == opt;
                            return InkWell(
                              onTap: () => setState(() => _answers[i] = opt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: chosen ? _cyan.withOpacity(0.1) : Colors.transparent,
                                  border: oi < q.options.length - 1
                                      ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: chosen ? _cyan : Colors.transparent,
                                        border: Border.all(color: chosen ? _cyan : Colors.white24),
                                      ),
                                      child: chosen
                                          ? const Icon(Icons.check, color: Colors.black, size: 13)
                                          : Center(
                                              child: Text(String.fromCharCode(65 + oi),
                                                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Text(opt, style: TextStyle(color: chosen ? Colors.white : Colors.white60, fontSize: 14))),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.05),
                );
              },
            ),
          ),

          // Submit bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _answers.length == _questions.length ? _submit : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _answers.length == _questions.length
                      ? 'SUBMIT ALL ANSWERS'
                      : 'ANSWER ALL QUESTIONS (${_questions.length - _answers.length} left)',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _answers.length == _questions.length ? _cyan : Colors.white12,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Single option tile used by rapid_fire and custom_live
class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final bool? isCorrect; // null = not answered yet, true = correct, false = wrong
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index); // A, B, C, D

    Color borderColor = Colors.white12;
    Color bgColor = Colors.white.withOpacity(0.02);
    Color textColor = Colors.white60;
    Widget? trail;

    if (isCorrect == true) {
      borderColor = _green.withOpacity(0.5);
      bgColor = _green.withOpacity(0.08);
      textColor = Colors.white;
      trail = const Icon(Icons.check_circle_rounded, color: _green, size: 18);
    } else if (isCorrect == false && isSelected) {
      borderColor = _pink.withOpacity(0.5);
      bgColor = _pink.withOpacity(0.08);
      textColor = Colors.white;
      trail = const Icon(Icons.cancel_rounded, color: _pink, size: 18);
    } else if (isSelected) {
      borderColor = _cyan.withOpacity(0.5);
      bgColor = _cyan.withOpacity(0.07);
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? borderColor.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                ),
                child: Center(
                  child: Text(letter, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
              ),
              if (trail != null) trail,
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05),
    );
  }
}

/// Results screen shown after rapid_fire or preloaded
class _ResultScreen extends StatelessWidget {
  final int score;
  final String activityTitle;
  final List<Map<String, dynamic>> results;

  const _ResultScreen({required this.score, required this.activityTitle, required this.results});

  @override
  Widget build(BuildContext context) {
    final correct = results.where((r) => r['isCorrect'] == true).length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('RESULTS', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Score card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _cyan.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                Text('FINAL SCORE', style: GoogleFonts.jetBrainsMono(color: _cyan, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('$score', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
                Text('$correct / ${results.length} correct',
                    style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ).animate().scale(duration: 400.ms),

          const SizedBox(height: 28),
          Text('BREAKDOWN', style: GoogleFonts.jetBrainsMono(color: Colors.white30, fontSize: 9, letterSpacing: 2)),
          const SizedBox(height: 12),

          ...results.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            final ok = r['isCorrect'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ok ? _green.withOpacity(0.06) : _pink.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ok ? _green.withOpacity(0.2) : _pink.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? _green : _pink, size: 16),
                      const SizedBox(width: 8),
                      Text('Q${i + 1}', style: GoogleFonts.jetBrainsMono(color: ok ? _green : _pink, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r['q'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Your answer: ${r['picked'] ?? 'No answer'}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  if (!ok)
                    Text('Correct: ${r['correct']}', style: const TextStyle(color: _green, fontSize: 11)),
                ],
              ),
            ).animate().fadeIn(delay: (i * 50).ms);
          }),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('BACK TO LOBBY', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _NoActivityScaffold extends StatelessWidget {
  final Event event;
  const _NoActivityScaffold({required this.event});

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
            const Icon(Icons.quiz_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text('No quiz is active right now', style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Admin will activate a quiz soon', style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
