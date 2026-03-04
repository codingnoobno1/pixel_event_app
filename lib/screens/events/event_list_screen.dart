import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/widgets.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  bool _isLoading = false;
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  String _searchQuery = '';
  final Set<String> _selectedTags = {};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(eventRepositoryProvider);
      final events = await repository.getEvents();
      
      if (mounted) {
        setState(() {
          _events = events;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadEvents,
            ),
          ),
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

  void _applyFilters() {
    setState(() {
      _filteredEvents = _events.where((event) {
        if (_searchQuery.isNotEmpty &&
            !event.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !event.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }

        if (_selectedTags.isNotEmpty &&
            !event.tags.any((tag) => _selectedTags.contains(tag))) {
          return false;
        }

        if (_dateRange != null) {
          if (event.date.isBefore(_dateRange!.start) ||
              event.date.isAfter(_dateRange!.end)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0F);
    const cyan = Color(0xFF00FFFF);
    const pink = Color(0xFFFF2E88);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: CyberTextField(
                    hintText: 'Search events...',
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cyan.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: cyan),
                    onPressed: _showFilterDialog,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          if (_selectedTags.isNotEmpty || _dateRange != null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._selectedTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CyberChip(
                          label: tag,
                          isSelected: true,
                          onTap: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                            _applyFilters();
                          },
                        ),
                      )),
                  if (_dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CyberChip(
                        label: '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        isSelected: true,
                        onTap: () {
                          setState(() {
                            _dateRange = null;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Event List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: pink))
                : _filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No events found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: cyan,
                        backgroundColor: bg,
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return EventCard(
                              event: event,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  '/event-detail',
                                  arguments: event,
                                );
                              },
                            )
                                .animate()
                                .fadeIn(
                                  duration: 400.ms,
                                  delay: (index * 100).ms,
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 400.ms,
                                  delay: (index * 100).ms,
                                  curve: Curves.easeOutCubic,
                                );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    const cyan = Color(0xFF00FFFF);
    const bg = Color(0xFF0B0B0F);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CyberGlassCard(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'FILTERS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CyberCard(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: cyan,
                            onPrimary: Colors.black,
                            surface: bg,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    setState(() {
                      _dateRange = range;
                    });
                    _applyFilters();
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: cyan),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date Range',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _dateRange != null
                                ? '${DateFormat('MMM d, y').format(_dateRange!.start)} - ${DateFormat('MMM d, y').format(_dateRange!.end)}'
                                : 'Select dates',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CyberButton(
                onPressed: () {
                  setState(() {
                    _selectedTags.clear();
                    _dateRange = null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
                text: 'Clear All Filters',
                color: Colors.grey[800],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00FFFF);
    const gold = Color(0xFFFFD700);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: CyberCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: event.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.white.withOpacity(0.02),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: cyan)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 160,
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.white12),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.event, size: 48, color: Colors.white12),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CyberBadge(
                    label: event.isUpcoming ? 'UPCOMING' : 'PAST',
                    color: event.isUpcoming ? const Color(0xFF00FF9F) : Colors.grey,
                    type: CyberBadgeType.glow,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    event.title.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: cyan),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, MMM d, y').format(event.date),
                        style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded, size: 14, color: cyan),
                      const SizedBox(width: 8),
                      Text(
                        event.time,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: GoogleFonts.jetBrainsMono(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.take(3).map((tag) {
                        return CyberBadge(
                          label: tag,
                          type: CyberBadgeType.outline,
                          color: cyan.withOpacity(0.5),
                        );
                      }).toList(),
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
