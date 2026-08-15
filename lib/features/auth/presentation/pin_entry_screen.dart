import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ← ADD THIS
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/app_state.dart';

class PinEntryScreen extends StatefulWidget {
  final UserAccount account;
  final bool isSwitching;
  final VoidCallback? onSuccess;

  const PinEntryScreen({
    super.key,
    required this.account,
    this.isSwitching = false,
    this.onSuccess,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _error = '';
  bool _isLoading = false;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();

    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = 'Please enter a valid 4-digit PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final isValid = await AuthService.verifyPin(widget.account.id, pin);

    setState(() => _isLoading = false);

    if (isValid) {
      await AuthService.setCurrentUser(widget.account.id);
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setCurrentUser(widget.account);
      _pinController.clear();

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _attempts++;
        _error =
            'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
        _pinController.clear();
        if (_attempts >= _maxAttempts) {
          _error =
              'Too many failed attempts. Please go back and try again later.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _attempts >= _maxAttempts;

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    widget.account.name[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isSwitching
                      ? 'Switch to ${widget.account.name}'
                      : 'Welcome back, ${widget.account.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HavenColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: HavenColors.muted,
                  ),
                ),
                const SizedBox(height: 32),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text(
                          'Too many failed attempts',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please go back and try again later.',
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _attempts = 0;
                              _error = '';
                              _pinController.clear();
                            });
                          },
                          child: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HavenColors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            counterText: '',
                            errorText: _error.isNotEmpty ? _error : null,
                            errorStyle: const TextStyle(color: Colors.red),
                          ),
                          onChanged: (value) {
                            if (value.length == 4) {
                              _verifyPin();
                            }
                            if (_error.isNotEmpty) {
                              setState(() => _error = '');
                            }
                          },
                          enabled: !isLocked,
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading) const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to accounts'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
