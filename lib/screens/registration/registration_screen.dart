import 'package:flutter/material.dart';
import '../../models/models.dart';

class RegistrationScreen extends StatefulWidget {
  final Event event;

  const RegistrationScreen({
    super.key,
    required this.event,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  RegistrationType _registrationType = RegistrationType.solo;
  
  // Solo registration fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _semesterController = TextEditingController();
  
  // Team registration fields
  final _teamNameController = TextEditingController();
  final List<Map<String, TextEditingController>> _teamMembers = [];
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    _semesterController.dispose();
    _teamNameController.dispose();
    for (var member in _teamMembers) {
      member.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _addTeamMember() {
    if (_teamMembers.length < 5) {
      setState(() {
        _teamMembers.add({
          'name': TextEditingController(),
          'email': TextEditingController(),
          'enrollment': TextEditingController(),
          'semester': TextEditingController(),
        });
      });
    }
  }

  void _removeTeamMember(int index) {
    setState(() {
      _teamMembers[index].values.forEach((controller) => controller.dispose());
      _teamMembers.removeAt(index);
    });
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement registration API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate to event pass screen
        Navigator.of(context).pushReplacementNamed('/event-pass');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registration'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Event Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Text(widget.event.location),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Registration Type Selector
            Text(
              'Registration Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<RegistrationType>(
              segments: const [
                ButtonSegment(
                  value: RegistrationType.solo,
                  label: Text('Solo'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment(
                  value: RegistrationType.team,
                  label: Text('Team'),
                  icon: Icon(Icons.group),
                ),
              ],
              selected: {_registrationType},
              onSelectionChanged: (Set<RegistrationType> newSelection) {
                setState(() {
                  _registrationType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Solo Registration Form
            if (_registrationType == RegistrationType.solo) ...[
              _buildSoloForm(),
            ],

            // Team Registration Form
            if (_registrationType == RegistrationType.team) ...[
              _buildTeamForm(),
            ],

            const SizedBox(height: 24),

            // Submit Button
            FilledButton(
              onPressed: _isLoading ? null : _handleRegistration,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Email is required';
            if (!value!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _enrollmentController,
          decoration: const InputDecoration(
            labelText: 'Enrollment Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Enrollment number is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _semesterController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Semester',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Semester is required' : null,
        ),
      ],
    );
  }

  Widget _buildTeamForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Name
        Text(
          'Team Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _teamNameController,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Team name is required' : null,
        ),
        const SizedBox(height: 24),

        // Team Leader (same as solo form)
        Text(
          'Team Leader',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildSoloForm(),
        const SizedBox(height: 24),

        // Team Members
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Members (${_teamMembers.length}/5)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_teamMembers.length < 5)
              TextButton.icon(
                onPressed: _addTeamMember,
                icon: const Icon(Icons.add),
                label: const Text('Add Member'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Team Member Forms
        ..._teamMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Member ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeTeamMember(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: member['name'],
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: member['email'],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Email is required';
                      if (!value!.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: member['enrollment'],
                    decoration: const InputDecoration(
                      labelText: 'Enrollment Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Enrollment number is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: member['semester'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Semester is required' : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
