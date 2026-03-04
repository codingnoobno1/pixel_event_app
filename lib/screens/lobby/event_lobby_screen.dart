import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../providers/service_providers.dart';
import '../../widgets/widgets.dart';

class EventLobbyScreen extends ConsumerStatefulWidget {
  final Event event;
  final EventPass pass;

  const EventLobbyScreen({
    super.key,
    required this.event,
    required this.pass,
  });

  @override
  ConsumerState<EventLobbyScreen> createState() => _EventLobbyScreenState();
}

class _EventLobbyScreenState extends ConsumerState<EventLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Registration> _participants = [];
  Map<String, dynamic>? _depthData;

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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final engineService = ref.read(eventEngineServiceProvider);
      final depth = await engineService.getEventDepth(widget.event.id);
      
      if (!mounted) return;
      setState(() {
        _depthData = depth;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading depth: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    // TODO: Implement polling every 5-10 seconds
    // Poll messages from GET /api/event/messages?eventId={id}
  }

  @override
  Widget build(BuildContext context) {
    final pink = Color(0xFFFF2E88);
    final cyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('LIVE LOBBY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: cyan),
            onPressed: _loadData,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Event Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: pink, size: 16),
                      const SizedBox(width: 4),
                      Text(widget.event.location, style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Depth / Engagement Cards
          if (_depthData != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "ACTIVE CHALLENGES",
                  style: TextStyle(color: pink, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ...(_depthData!['quizzes'] as List).map((q) => _buildDepthCard(
                    title: q['title'],
                    subtitle: "${q['questionCount']} Questions • ${q['type']}",
                    count: "${q['participantCount']}",
                    countLabel: "SOLVED",
                    color: cyan,
                    recentUsers: (q['recentParticipants'] as List?)?.cast<String>(),
                  )),
                  ...(_depthData!['hunts'] as List).map((h) => _buildDepthCard(
                    title: h['name'],
                    subtitle: "${h['clueCount']} Clues found in the wild",
                    count: "${h['activeCount']}",
                    countLabel: "HUNTERS",
                    color: Colors.orangeAccent,
                    recentUsers: (h['recentParticipants'] as List?)?.cast<String>(),
                  )),
                ]),
              ),
            ),
          ],

          // Tabs for Participants
          SliverToBoxAdapter(
            child: Container(
              height: 400, // Fixed height for tab content in scroll view or use nested
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: pink,
                    labelColor: pink,
                    unselectedLabelColor: Colors.white38,
                    tabs: const [
                      Tab(text: "PARTICIPANTS"),
                      Tab(text: "RECENT UPDATES"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildParticipantsTab(),
                        Center(child: Text("Real-time updates appearing here...", style: TextStyle(color: Colors.white30))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthCard({
    required String title,
    required String subtitle,
    required String count,
    required String countLabel,
    required Color color,
    List<String>? recentUsers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(count, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
                  Text(countLabel, style: TextStyle(color: color.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (recentUsers != null && recentUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text("RECENT: ", style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    recentUsers.join(", "),
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
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
