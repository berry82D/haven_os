import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Routines'),
        backgroundColor: AppTheme.paper,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.paper,
        child: const Center(
          child: Text('Routines screen (coming soon)',
              style: TextStyle(color: AppTheme.ink, fontFamily: 'serif')),
        ),
      ),
    );
  }
}
