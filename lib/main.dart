// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/haven_central/haven_central_screen.dart';
import 'features/haven_central/haven_central_viewmodel.dart'; // ← added
import 'features/cfo/widgets/cfo_screen.dart';
import 'features/homestead/widgets/homestead_screen.dart';
import 'features/haven/widgets/haven_screen.dart';
import 'features/settings/widgets/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..initialize()),
        ChangeNotifierProvider(
            create: (_) => HavenCentralViewModel()), // ← added
      ],
      child: const HavenOSApp(),
    ),
  );
}

class HavenOSApp extends StatelessWidget {
  const HavenOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven OS',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.currentUser == null) {
      return const SignInScreen();
    }
    return const HavenTabs();
  }
}

class HavenTabs extends StatelessWidget {
  const HavenTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isChild = appState.isChildAccount;
    final isTeen = appState.isTeenAccount;

    if (isChild) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🎓 Haven - School Help'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                appState.logout();
              },
            ),
          ],
        ),
        body: const HavenScreen(),
      );
    }

    if (isTeen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('👋 My Haven'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                appState.logout();
              },
            ),
          ],
        ),
        body: const Center(child: Text('Teen dashboard coming soon...')),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: const TabBarView(
          children: [
            HavenCentralScreen(),
            CfoScreen(),
            HomesteadScreen(),
            HavenScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
                Tab(icon: Icon(Icons.payments_outlined), text: 'CFO'),
                Tab(icon: Icon(Icons.agriculture_outlined), text: 'Homestead'),
                Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Haven'),
                Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
              ],
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
