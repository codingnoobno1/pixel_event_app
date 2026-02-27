import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';

class MyPassesScreen extends StatefulWidget {
  const MyPassesScreen({super.key});

  @override
  State<MyPassesScreen> createState() => _MyPassesScreenState();
}

class _MyPassesScreenState extends State<MyPassesScreen> {
  bool _isLoading = false;
  List<EventPass> _passes = [];

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _loadPasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from repository/cache
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _passes = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Event Passes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _passes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No event passes yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register for events to get passes',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/events');
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Browse Events'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _passes.length,
                    itemBuilder: (context, index) {
                      final pass = _passes[index];
                      return PassCard(
                        pass: pass,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/event-pass',
                            arguments: pass,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class PassCard extends StatelessWidget {
  final EventPass pass;
  final VoidCallback onTap;

  const PassCard({
    super.key,
    required this.pass,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = pass.event.isUpcoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (pass.event.imageUrl != null)
              Image.network(
                pass.event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.event, size: 48),
                  );
                },
              )
            else
              Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.event, size: 48),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    pass.event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Date and Time
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(pass.event.date),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        pass.event.time,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pass.event.location,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pass Info
                  Row(
                    children: [
                      // Registration Type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pass.registrationType == RegistrationType.team
                              ? Colors.blue[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pass.registrationType == RegistrationType.team
                                  ? Icons.group
                                  : Icons.person,
                              size: 14,
                              color: pass.registrationType == RegistrationType.team
                                  ? Colors.blue[900]
                                  : Colors.green[900],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pass.registrationType.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: pass.registrationType == RegistrationType.team
                                    ? Colors.blue[900]
                                    : Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? Colors.orange[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isUpcoming ? 'UPCOMING' : 'PAST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUpcoming
                                ? Colors.orange[900]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      const Spacer(),

                      // QR Icon
                      Icon(
                        Icons.qr_code,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),

                  // Team Name (if team registration)
                  if (pass.teamName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.group, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Team: ${pass.teamName}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
