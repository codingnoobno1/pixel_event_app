import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pink = Color(0xFFFF2E88);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text("Not logged in", style: TextStyle(color: Colors.white70)));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('MY PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
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
                        border: Border.all(color: pink.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: pink.withOpacity(0.1),
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40, color: pink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              _buildInfoSection(context, "ACADEMIC INFO", [
                _buildInfoTile(Icons.badge_outlined, "Enrollment", user.enrollmentNumber),
                _buildInfoTile(Icons.school_outlined, "Course", user.course),
                _buildInfoTile(Icons.calendar_month_outlined, "Semester", "Semester ${user.semester}"),
              ]),

              const SizedBox(height: 24),

              _buildInfoSection(context, "ACCOUNT STATUS", [
                _buildInfoTile(Icons.security_outlined, "Role", user.role.name.toUpperCase(), 
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: pink.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(user.role.name.toUpperCase(), style: const TextStyle(color: pink, fontSize: 10, fontWeight: FontWeight.bold)),
                  )),
              ]),

              const SizedBox(height: 40),
              
              OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text("SIGN OUT"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: pink)),
      error: (e, _) => Center(child: Text("Error fetching profile: $e")),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white38, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: trailing,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2F),
        title: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to terminate your session?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}
