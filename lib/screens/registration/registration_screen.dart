import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/widgets.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final Event event;

  const RegistrationScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  RegistrationType _registrationType = RegistrationType.solo;
  
  // Basic info fields (pre-filled from user profile if available)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _semesterController = TextEditingController();
  
  // Team registration fields
  final _teamNameController = TextEditingController();
  final List<Map<String, TextEditingController>> _teamMembers = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _preFillUserData();
  }

  void _preFillUserData() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _enrollmentController.text = user.enrollmentNumber ?? '';
      _semesterController.text = user.semester.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    _semesterController.dispose();
    _teamNameController.dispose();
    for (var member in _teamMembers) {
      for (var controller in member.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _addTeamMember() {
    if (_teamMembers.length < 5) {
      setState(() {
        _teamMembers.add({
          'name': TextEditingController(),
          'email': TextEditingController(),
          'enrollmentNumber': TextEditingController(),
          'semester': TextEditingController(),
        });
      });
    }
  }

  void _removeTeamMember(int index) {
    setState(() {
      for (var controller in _teamMembers[index].values) {
        controller.dispose();
      }
      _teamMembers.removeAt(index);
    });
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(eventRepositoryProvider);
      
      final registration = await repository.registerForEvent(
        eventId: widget.event.id,
        type: _registrationType,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        enrollmentNumber: _enrollmentController.text.trim(),
        semester: _semesterController.text.trim(),
        teamName: _registrationType == RegistrationType.team ? _teamNameController.text.trim() : null,
        teamMembers: _registrationType == RegistrationType.team 
          ? _teamMembers.map((m) => TeamMember(
              name: m['name']!.text.trim(),
              email: m['email']!.text.trim(),
              enrollmentNumber: m['enrollmentNumber']!.text.trim(),
              semester: int.tryParse(m['semester']!.text.trim()) ?? 0,
            )).toList()
          : null,
      );
      
      if (mounted) {
        SuccessDialog.show(
          context,
          title: "REGISTRATION SUCCESS",
          message: "You have successfully registered for ${widget.event.title}. Your team ID is ${registration.teamId ?? 'N/A'}.",
          onOk: () {
            // Navigate to event list or details
            Navigator.of(context).pop();
            // Optionally navigate to 'My Passes'
            Navigator.of(context).pushReplacementNamed('/home');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const pink = Color(0xFFFF2E88);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("EVENT REGISTRATION", style: TextStyle(letterSpacing: 1.5, fontSize: 18)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B0F), Color(0xFF15151F)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Event Summary
              CyberCard(
                child: Row(
                  children: [
                    if (widget.event.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.event.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.event, color: pink),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.event.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(widget.event.location, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Type Selector
              const Text("REGISTRATION TYPE", style: TextStyle(color: pink, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CyberChip(
                      label: "SOLO",
                      isSelected: _registrationType == RegistrationType.solo,
                      onTap: () => setState(() => _registrationType = RegistrationType.solo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberChip(
                      label: "TEAM",
                      isSelected: _registrationType == RegistrationType.team,
                      onTap: () => setState(() => _registrationType = RegistrationType.team),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Leader Info
              const Text("LEADER INFORMATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              CyberGlassCard(
                child: Column(
                  children: [
                    CyberTextField(
                      controller: _nameController,
                      labelText: "Full Name",
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    CyberTextField(
                      controller: _emailController,
                      labelText: "Email Address",
                      prefixIcon: Icons.email_outlined,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CyberTextField(
                            controller: _enrollmentController,
                            labelText: "Enrollment #",
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CyberTextField(
                            controller: _semesterController,
                            labelText: "Semester",
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_registrationType == RegistrationType.team) ...[
                const SizedBox(height: 32),
                const Text("TEAM INFORMATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                CyberGlassCard(
                  child: CyberTextField(
                    controller: _teamNameController,
                    labelText: "Team Name",
                    prefixIcon: Icons.group_outlined,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("MEMBERS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    if (_teamMembers.length < 5)
                      TextButton.icon(
                        onPressed: _addTeamMember,
                        icon: const Icon(Icons.add_circle_outline, color: pink),
                        label: const Text("ADD MEMBER", style: TextStyle(color: pink)),
                      ),
                  ],
                ),
                ..._teamMembers.asMap().entries.map((entry) => _buildMemberCard(entry.key, entry.value)),
              ],

              const SizedBox(height: 48),
              CyberButton(
                onPressed: _handleRegistration,
                text: "CONFIRM REGISTRATION",
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(int index, Map<String, TextEditingController> member) {
    const pink = Color(0xFFFF2E88);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: CyberCard(
        color: pink.withOpacity(0.3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("MEMBER #${index + 1}", style: const TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeTeamMember(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CyberTextField(
              controller: member['name'],
              labelText: "Name",
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            CyberTextField(
              controller: member['email'],
              labelText: "Email",
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CyberTextField(
                    controller: member['enrollmentNumber'],
                    labelText: "Enrollment #",
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CyberTextField(
                    controller: member['semester'],
                    labelText: "Sem",
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
