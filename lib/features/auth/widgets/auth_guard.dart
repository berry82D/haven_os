import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/auth/presentation/sign_in_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.currentUser == null) {
      return const SignInScreen();
    }

    // ✅ Use 'pinVerified' (not 'isPinVerified')
    if (appState.isPinEnabled && !appState.pinVerified) {
      return const SignInScreen();
    }

    return child;
  }
}
