import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/home/widgets/timeline_screen.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.myTimelineEvents;

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.timeline, size: 48, color: HavenColors.lightMuted),
            const SizedBox(height: 12),
            Text(
              'No events yet',
              style: TextStyle(
                fontSize: 16,
                color: HavenColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your household activity will appear here',
              style: TextStyle(
                fontSize: 13,
                color: HavenColors.lightMuted,
              ),
            ),
          ],
        ),
      );
    }

    final todayEvents = events.where((e) => e.isToday).toList();
    final displayEvents =
        todayEvents.isNotEmpty ? todayEvents : events.take(5).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline,
                        size: 20, color: HavenColors.green),
                    const SizedBox(width: 8),
                    Text(
                      todayEvents.isNotEmpty
                          ? 'Today\'s Activity'
                          : 'Recent Activity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HavenColors.dark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () =>
                          _showClearConfirmation(context, appState),
                      tooltip: 'Clear all events',
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimelineScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          color: HavenColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...displayEvents.map((event) => _buildTimelineItem(event, context)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getEventColor(event.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(event.type),
              color: _getEventColor(event.type),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: HavenColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: HavenColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: HavenColors.lightMuted,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.finance:
        return Icons.payments;
      case TimelineEventType.bill:
        return Icons.receipt_long;
      case TimelineEventType.task:
        return Icons.assignment;
      case TimelineEventType.animal:
        return Icons.pets;
      case TimelineEventType.system:
        return Icons.info_outline;
    }
  }

  Color _getEventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.finance:
        return const Color(0xFF4CAF50);
      case TimelineEventType.bill:
        return const Color(0xFFFF9800);
      case TimelineEventType.task:
        return const Color(0xFF2196F3);
      case TimelineEventType.animal:
        return const Color(0xFF9C27B0);
      case TimelineEventType.system:
        return const Color(0xFF607D8B);
    }
  }

  void _showClearConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Timeline?'),
        content: const Text(
          'This will remove all timeline events. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.clearTimelineEvents();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timeline cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
