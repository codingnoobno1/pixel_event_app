import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/widgets.dart';
import '../registration/registration_screen.dart';
import '../registration/event_pass_screen.dart';
import 'live_event_lobby_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isRegistered = false;
  bool _isCheckingStatus = true;
  bool _isLoadingPass = false;
  EventPass? _cachedPass;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final repository = ref.read(eventRepositoryProvider);
      final registered = await repository.isRegistered(user.email, widget.event.id);
      if (mounted) {
        setState(() {
          _isRegistered = registered;
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<EventPass?> _fetchPass() async {
    if (_cachedPass != null) return _cachedPass;
    
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return null;

    setState(() => _isLoadingPass = true);
    try {
      final repository = ref.read(eventRepositoryProvider);
      final pass = await repository.getEventPass(user.email, widget.event.id);
      _cachedPass = pass;
      return pass;
    } catch (e) {
      if (mounted) ErrorDialog.show(context, message: "Could not load pass: ${e.toString()}");
      return null;
    } finally {
      if (mounted) setState(() => _isLoadingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const cyan = Color(0xFF00FFFF);
    const gold = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.event.imageUrl != null)
                    Image.network(widget.event.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: Colors.white.withOpacity(0.01)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, bg.withOpacity(0.8), bg],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.event.title.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CyberBadge(
                      label: widget.event.isUpcoming ? "UPCOMING" : "PAST",
                      color: widget.event.isUpcoming ? const Color(0xFF00FF9F) : Colors.grey,
                      type: CyberBadgeType.glow,
                    ),
                  ],
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildQuickInfo(Icons.calendar_month_rounded, DateFormat('MMM d, y').format(widget.event.date), "DATE"),
                    _buildQuickInfo(Icons.access_time_rounded, widget.event.time, "TIME_UTC"),
                    _buildQuickInfo(Icons.people_rounded, "${widget.event.participantCount}", "SLOTS"),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                CyberCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cyan.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cyan.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: cyan, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ACCESS_POINT", style: GoogleFonts.jetBrainsMono(color: cyan, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(widget.event.location.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                Text("MISSION_OVERVIEW", style: GoogleFonts.jetBrainsMono(color: cyan.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
                const SizedBox(height: 12),
                Text(
                  widget.event.description.toUpperCase(), 
                  style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.6)
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: (_isCheckingStatus || _isLoadingPass)
            ? const SizedBox(height: 56, child: Center(child: CyberLoading(message: "VERIFYING_ACCESS")))
            : Row(
                children: [
                  if (_isRegistered) ...[
                    Expanded(
                      child: CyberButton(
                        onPressed: () {
                          final user = ref.read(authServiceProvider).currentUser;
                          final participantId = user?.enrollmentNumber ?? user?.email ?? 'guest';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveEventLobbyScreen(
                                event: widget.event,
                                participantId: participantId,
                              ),
                            ),
                          );
                        },
                        text: "ENTER_LOBBY",
                        icon: Icons.hub_rounded,
                        color: cyan,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: CyberButton(
                      onPressed: () async {
                        if (_isRegistered) {
                          final pass = await _fetchPass();
                          if (pass != null && mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventPassScreen(eventPass: pass)));
                          }
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen(event: widget.event))).then((_) => _checkRegistrationStatus());
                        }
                      },
                      text: _isRegistered ? "ACCESS_PASS" : "JOIN_MISSION",
                      icon: _isRegistered ? Icons.qr_code_2_rounded : Icons.bolt_rounded,
                      color: _isRegistered ? Colors.white10 : gold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String value, String label) {
    const cyan = Color(0xFF00FFFF);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: cyan, size: 24),
          const SizedBox(height: 10),
          Text(value.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 8, letterSpacing: 1)),
        ],
      ),
    );
  }
}
