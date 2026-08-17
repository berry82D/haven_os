// lib/features/home/widgets/timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.timelineEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Timeline'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: events.isEmpty
          ? const Center(
              child: Text('No events yet.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.event, color: Colors.teal.shade700),
                    title: Text(event.title ?? 'Event'),
                    subtitle: Text(event.date?.toString() ?? ''),
                    trailing:
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ),
                );
              },
            ),
    );
  }
}
