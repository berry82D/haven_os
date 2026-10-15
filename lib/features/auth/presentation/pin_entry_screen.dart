// lib/features/auth/presentation/pin_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/haven_central/haven_central_screen.dart';
import 'sign_in_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final String? username;
  const PinEntryScreen({super.key, this.username});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      final username = widget.username ?? context.read<AppState>().currentUser?.name ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HavenCentralScreen(username: username),
        ),
      );
    }
  }
  Future<void> _submitPin() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Enter your PIN');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final ok = await context.read<AppState>().verifyPinAndUnlock(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _goHome();
    } else {
      setState(() => _error = 'Wrong PIN - try again');
    }
  }

  Future<void> _useBiometrics() async {
    setState(() { _busy = true; _error = null; });
    final ok = await context.read<AppState>().unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _goHome();
    } else {
      final bioErr = context.read<AppState>().lastBiometricError;
      setState(() => _error = bioErr != null ? 'Biometric failed: ' + bioErr : 'Biometric unlock failed - enter your PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submitPin(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submitPin,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Unlock'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _busy ? null : _useBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use fingerprint / face'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                child: const Text('Forgot PIN? Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
