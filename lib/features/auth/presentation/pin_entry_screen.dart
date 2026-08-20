// lib/features/auth/presentation/pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';

class PinEntryScreen extends StatelessWidget {
  const PinEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.isPinVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: HavenColors.muted),
            const SizedBox(height: 24),
            const Text(
              'Enter PIN to unlock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                appState.unlockApp();
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Unlock (demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
