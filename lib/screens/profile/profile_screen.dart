import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cyan = Color(0xFF00FFFF);
    const bg = Color(0xFF0B0B0F);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: CyberLoading(message: "LOGGING_IN..."));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'IDENTITY_MODULE', 
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cyan.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(color: cyan.withOpacity(0.1), blurRadius: 20),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(fontSize: 40, color: cyan, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.name.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.toLowerCase(),
                      style: GoogleFonts.jetBrainsMono(color: cyan.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              _buildInfoSection(context, "ACADEMIC_ENCRYPTED_METADATA", [
                _buildInfoTile(Icons.badge_rounded, "ENROLLMENT_ID", user.enrollmentNumber),
                _buildInfoTile(Icons.school_rounded, "COURSE_TRACK", user.course.toUpperCase()),
                _buildInfoTile(Icons.layers_rounded, "SEMESTER_LEVEL", "LEVEL_0${user.semester}"),
              ], cyan),

              const SizedBox(height: 24),

              _buildInfoSection(context, "SECURITY_CLEARANCE", [
                _buildInfoTile(Icons.verified_user_rounded, "ACCESS_ROLE", user.role.name.toUpperCase(), 
                  trailing: CyberBadge(
                    label: user.role.name.toUpperCase(),
                    color: cyan,
                  )),
              ], cyan),

              const SizedBox(height: 48),
              
              CyberButton(
                onPressed: () => _showLogoutDialog(context, ref),
                text: "TERMINATE_SESSION",
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const Center(child: CyberLoading(message: "RETRIEVING_IDENTITY")),
      error: (e, _) => Center(child: Text("UPLINK_ERROR: $e", style: GoogleFonts.jetBrainsMono(color: Colors.redAccent))),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children, Color cyan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.jetBrainsMono(color: cyan.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        CyberGlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFF00FFFF).withOpacity(0.4), size: 20),
      title: Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      trailing: trailing,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CyberDialog(
        title: "CONFIRM_TERMINATION",
        message: "ARE YOU SURE YOU WANT TO TERMINATE YOUR CURRENT SECURE SESSION?",
        onConfirm: () async {
          await ref.read(authServiceProvider).logout();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
      ),
    );
  }
}
