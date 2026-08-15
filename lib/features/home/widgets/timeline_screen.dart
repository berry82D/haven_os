import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/services/app_state.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.timelineEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Activity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
      body: events.isEmpty
          ? const Center(child: Text('No events yet'))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              _getEventColor(event.type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getEventIcon(event.type),
                          color: _getEventColor(event.type),
                          size: 20,
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
                                fontWeight: FontWeight.w500,
                                color: HavenColors.dark,
                              ),
                            ),
                            Text(
                              event.description,
                              style: TextStyle(
                                color: HavenColors.muted,
                              ),
                            ),
                            Text(
                              '${event.formattedDate} at ${event.formattedTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: HavenColors.lightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
}
