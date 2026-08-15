// lib/features/haven/widgets/haven_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class HavenScreen extends StatefulWidget {
  const HavenScreen({super.key});

  @override
  State<HavenScreen> createState() => _HavenScreenState();
}

class _HavenScreenState extends State<HavenScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isChild = appState.isChildAccount;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                isChild ? '🎓 School Help Mode' : '🤖 Haven Assistant',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your smart learning companion is here!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Placeholder for learning content
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Learning content will appear here.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
