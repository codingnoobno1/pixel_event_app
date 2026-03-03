import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/widgets.dart';
import '../registration/registration_screen.dart';
import '../registration/event_pass_screen.dart';

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

  Future<void> _handleViewPass() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoadingPass = true);

    try {
      final repository = ref.read(eventRepositoryProvider);
      
      // 1. Get registrations for the user
      final registrations = await repository.getMyRegistrations(user.email);
      
      // 2. Find the one for this event
      final registration = registrations.firstWhere(
        (r) => r.eventId == widget.event.id,
        orElse: () => throw Exception("Registration not found"),
      );

      // 3. Fetch the full Event Pass object
      final pass = await repository.getEventPass(registration.id);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventPassScreen(eventPass: pass),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: "Could not load pass: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoadingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);
    const cyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.event.imageUrl != null)
                    Image.network(widget.event.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: Colors.white.withOpacity(0.05)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          bg.withOpacity(0.8),
                          bg,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.event.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
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
                    _buildQuickInfo(Icons.calendar_month, DateFormat('MMM d, y').format(widget.event.date), "Date"),
                    _buildQuickInfo(Icons.access_time, widget.event.time, "Time"),
                    _buildQuickInfo(Icons.people_outline, "${widget.event.participantCount}", "Capacity"),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                CyberCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on, color: pink),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("VENUE", style: TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            Text(widget.event.location, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                const Text("ABOUT THE EVENT", style: TextStyle(color: cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(
                  widget.event.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 32),
                if (widget.event.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.event.tags.map((tag) => CyberBadge(
                      label: tag,
                      type: CyberBadgeType.outline,
                      color: pink.withOpacity(0.5),
                    )).toList(),
                  ),
                ],
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
          border: Border(top: Border.all(color: Colors.white10).top),
        ),
        child: (_isCheckingStatus || _isLoadingPass)
            ? const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator(color: pink)),
              )
            : CyberButton(
                onPressed: () {
                  if (_isRegistered) {
                    _handleViewPass();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(event: widget.event),
                      ),
                    ).then((_) => _checkRegistrationStatus());
                  }
                },
                text: _isRegistered ? "VIEW YOUR PASS" : "REGISTER NOW",
                icon: _isRegistered ? Icons.qr_code : Icons.bolt,
                color: _isRegistered ? const Color(0xFF00FF9F) : pink,
              ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D2FF), size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }
}
