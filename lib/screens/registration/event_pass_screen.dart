import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class EventPassScreen extends StatelessWidget {
  final EventPass eventPass;

  const EventPassScreen({
    super.key,
    required this.eventPass,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const cyan = Color(0xFF00FFFF);
    const gold = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "DIGITAL_PASS_VAULT",
          style: GoogleFonts.jetBrainsMono(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: bg,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // 🔥 PREMIUM QR PASS CARD
              CyberQRPass(
                data: eventPass.qrPayload,
                title: eventPass.event.title,
                subtitle: DateFormat('EEEE, MMM d, y').format(eventPass.event.date),
              ).animate().fadeIn().scale(duration: 600.ms, curve: Curves.elasticOut)
               .shimmer(delay: 2.seconds, duration: 1500.ms),

              const SizedBox(height: 48),

              // INFO GRID
              Row(
                children: [
                  _buildPassInfo(Icons.access_time_rounded, eventPass.event.time, "START_TIME"),
                  _buildPassInfo(Icons.location_on_rounded, eventPass.event.location, "ACCESS_POINT"),
                ],
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Entry/Exit Status
              CyberGlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusItem(
                      "ENTRY", 
                      eventPass.entryCount > 0 ? "CONFIRMED" : "PENDING", 
                      eventPass.entryCount > 0 ? const Color(0xFF00FF9F) : Colors.orange
                    ),
                    const VerticalDivider(color: Colors.white10, width: 1),
                    _buildStatusItem(
                      "EXIT", 
                      eventPass.exitCount > 0 ? "CONFIRMED" : "PENDING", 
                      eventPass.exitCount > 0 ? const Color(0xFFFF2E88) : Colors.white10
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // ATTENDEE DETAILS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "IDENTITY_METADATA",
                  style: GoogleFonts.jetBrainsMono(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              CyberGlassCard(
                opacity: 0.02,
                child: Column(
                  children: [
                    _buildDetailRow("NAME", eventPass.user.name),
                    _buildDetailRow("UID", eventPass.user.enrollmentNumber),
                    _buildDetailRow("SECTOR", "SEM ${eventPass.user.semester} | ${eventPass.user.course}"),
                    if (eventPass.registrationType == RegistrationType.team) ...[
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow("TACTICAL_UNIT", eventPass.teamName ?? "N/A"),
                      _buildDetailRow("UNIT_ID", eventPass.teamId ?? "N/A"),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // INSTRUCTIONS
              CyberCard(
                color: cyan.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.terminal_rounded, color: cyan, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "SYSTEM_PROTOCOLS",
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep("1", "Keep this QR code ready at the entrance."),
                    _buildStep("2", "Security will scan this pass for validation."),
                    _buildStep("3", "Do not share this QR code with others."),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 40),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: CyberButton(
                      onPressed: () {},
                      text: "SAVE PASS",
                      icon: Icons.download_rounded,
                      color: Colors.grey[800],
                      height: 50,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (eventPass.entryCount > 0 && eventPass.event.activeMode != null)
                    Expanded(
                      child: CyberButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/event-lobby', 
                            arguments: {'event': eventPass.event, 'pass': eventPass}
                          );
                        },
                        text: "ENTER LOBBY",
                        icon: Icons.meeting_room_outlined,
                        color: cyan,
                        height: 50,
                      ),
                    )
                  else
                    Expanded(
                      child: CyberButton(
                        onPressed: () {},
                        text: "SHARE",
                        icon: Icons.share_rounded,
                        height: 50,
                      ),
                    ),
                ],
              ).animate().fadeIn(delay: 900.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassInfo(IconData icon, String value, String label) {
    const cyan = Color(0xFF00FFFF);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: cyan, size: 24),
          const SizedBox(height: 12),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 9, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    const cyan = Color(0xFF00FFFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.5), fontSize: 10, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(color: color, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
