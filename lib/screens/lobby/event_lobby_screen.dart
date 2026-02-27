import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';

class EventLobbyScreen extends StatefulWidget {
  final Event event;

  const EventLobbyScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventLobbyScreen> createState() => _EventLobbyScreenState();
}

class _EventLobbyScreenState extends State<EventLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Registration> _participants = [];
  List<EventMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load participants and messages
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _participants = [];
        _messages = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    // TODO: Implement polling every 5-10 seconds
    // Poll messages from GET /api/event/messages?eventId={id}
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _participants.length;
    final attendedCount =
        _participants.where((p) => p.status == AttendanceStatus.attended).length;
    final pendingCount =
        _participants.where((p) => p.status == AttendanceStatus.pending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Participants', icon: Icon(Icons.people)),
            Tab(text: 'Messages', icon: Icon(Icons.message)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Event Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, y').format(widget.event.date)} • ${widget.event.time}',
                ),
                const SizedBox(height: 4),
                Text(widget.event.location),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total', '$totalCount', Colors.blue),
                _buildStatCard('Attended', '$attendedCount', Colors.green),
                _buildStatCard('Pending', '$pendingCount', Colors.orange),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParticipantsTab(),
                _buildMessagesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showSendMessageDialog,
              icon: const Icon(Icons.send),
              label: const Text('Send Message'),
            )
          : null,
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No participants yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: participant.status == AttendanceStatus.attended
                    ? Colors.green
                    : Colors.orange,
                child: Text(
                  participant.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                participant.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(participant.enrollmentNumber),
                  if (participant.teamName != null)
                    Text(
                      'Team: ${participant.teamName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    participant.status == AttendanceStatus.attended
                        ? Icons.check_circle
                        : Icons.pending,
                    color: participant.status == AttendanceStatus.attended
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participant.status.name,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No messages yet'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showSendMessageDialog,
              child: const Text('Send First Message'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return MessageCard(message: message);
        },
      ),
    );
  }

  void _showSendMessageDialog() {
    final messageController = TextEditingController();
    MessagePriority selectedPriority = MessagePriority.normal;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority:'),
                  const SizedBox(height: 8),
                  SegmentedButton<MessagePriority>(
                    segments: const [
                      ButtonSegment(
                        value: MessagePriority.normal,
                        label: Text('Normal'),
                      ),
                      ButtonSegment(
                        value: MessagePriority.high,
                        label: Text('High'),
                      ),
                      ButtonSegment(
                        value: MessagePriority.urgent,
                        label: Text('Urgent'),
                      ),
                    ],
                    selected: {selectedPriority},
                    onSelectionChanged: (Set<MessagePriority> newSelection) {
                      setState(() {
                        selectedPriority = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // TODO: Send message
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent')),
                    );
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class MessageCard extends StatelessWidget {
  final EventMessage message;

  const MessageCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPriorityIcon(message.priority),
                  size: 20,
                  color: _getPriorityColor(message.priority),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.message),
            if (message.priority != MessagePriority.normal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(message.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  message.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(message.priority),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPriorityIcon(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.urgent:
        return Icons.priority_high;
      case MessagePriority.high:
        return Icons.warning;
      case MessagePriority.normal:
        return Icons.info;
    }
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.urgent:
        return Colors.red;
      case MessagePriority.high:
        return Colors.orange;
      case MessagePriority.normal:
        return Colors.blue;
    }
  }
}
