// lib/main.dart
import 'package:flutter/material.dart';
import 'features/auth/presentation/sign_in_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven OS',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const SignInScreen(), // Always show Sign In (no auto-login)
      debugShowCheckedModeBanner: false,
    );
  }
}
