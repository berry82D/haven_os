// lib/features/auth/presentation/pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';

  Future<void> _unlock() async {
    final appState = context.read<AppState>();
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Enter password');
      return;
    }
    try {
      await appState.unlockApp(password);
      if (appState.isPinVerified) {
        if (context.mounted) Navigator.of(context).pop(); // close overlay
      } else {
        setState(() => _error = 'Wrong password');
      }
    } catch (e) {
      setState(() => _error = 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔐 Enter Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _error.isNotEmpty ? _error : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _unlock,
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
