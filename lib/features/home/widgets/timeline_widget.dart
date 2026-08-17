// lib/features/home/widgets/timeline_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.timelineEvents.take(5).toList();

    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent events'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '📅 Recent Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...events.map((event) => ListTile(
                leading: Icon(Icons.circle, size: 12, color: Colors.teal),
                title: Text(event.title ?? 'Event'),
                subtitle: Text(event.date?.toString() ?? ''),
                dense: true,
              )),
          if (events.length < appState.timelineEvents.length)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () {
                  // Navigate to full timeline
                },
                child: const Text('View all'),
              ),
            ),
        ],
      ),
    );
  }
}
