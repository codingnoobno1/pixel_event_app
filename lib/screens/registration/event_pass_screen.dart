import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    const pink = Color(0xFFFF2E88);
    const cyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "DIGITAL PASS",
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B0F), Color(0xFF15151F)],
          ),
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
              ).animate().fadeIn().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              // INFO GRID
              Row(
                children: [
                  _buildPassInfo(Icons.access_time, eventPass.event.time, "START TIME"),
                  _buildPassInfo(Icons.location_on_outlined, eventPass.event.location, "VENUE"),
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
                      eventPass.entryCount > 0 ? "RECORDED" : "PENDING", 
                      eventPass.entryCount > 0 ? const Color(0xFF00FF9F) : Colors.orange
                    ),
                    const VerticalDivider(color: Colors.white10, width: 1),
                    _buildStatusItem(
                      "EXIT", 
                      eventPass.exitCount > 0 ? "RECORDED" : "PENDING", 
                      eventPass.exitCount > 0 ? pink : Colors.grey
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // ATTENDEE DETAILS
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ATTENDEE DETAILS",
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              CyberGlassCard(
                child: Column(
                  children: [
                    _buildDetailRow("NAME", eventPass.user.name),
                    _buildDetailRow("EMAIL", eventPass.user.email),
                    _buildDetailRow("ENROLLMENT", eventPass.user.enrollmentNumber),
                    _buildDetailRow("SEMESTER", "SEM ${eventPass.user.semester}"),
                    if (eventPass.registrationType == RegistrationType.team) ...[
                      const Divider(color: Colors.white10, height: 24),
                      _buildDetailRow("TEAM", eventPass.teamName ?? "N/A"),
                      _buildDetailRow("TEAM ID", eventPass.teamId ?? "N/A"),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // INSTRUCTIONS
              CyberCard(
                color: cyan.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: cyan, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "ENTRY INSTRUCTIONS",
                          style: TextStyle(
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
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D2FF), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            value.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    const cyan = Color(0xFF00D2FF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
