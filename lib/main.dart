// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/core/theme/haven_theme.dart';
import 'package:haven_os/features/auth/presentation/sign_in_screen.dart';
import 'package:haven_os/features/auth/widgets/auth_guard.dart';
import 'package:haven_os/features/cfo/widgets/cfo_screen.dart'; // ✅ only one import
import 'package:haven_os/features/haven/widgets/haven_screen.dart';
import 'package:haven_os/features/home/widgets/home_screen.dart';
import 'package:haven_os/features/homestead/widgets/homestead_screen.dart';
import 'package:haven_os/features/settings/widgets/settings_screen.dart';
import 'package:haven_os/services/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HavenOSApp());
}

class HavenOSApp extends StatefulWidget {
  const HavenOSApp({super.key});

  @override
  State<HavenOSApp> createState() => _HavenOSAppState();
}

class _HavenOSAppState extends State<HavenOSApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      appState.lockApp();
    }
    if (state == AppLifecycleState.resumed) {
      if (appState.needsPinReentry()) {
        appState.setPinVerified(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..initialize()),
        ChangeNotifierProvider(
          create: (_) => FinancialData(
            income: 5000,
            expenses: 3200,
            debt: 12000,
            savings: 8000,
            categories: {
              'Food': 800,
              'Housing': 1200,
              'Transport': 400,
              'Utilities': 300,
              'Entertainment': 200,
              'Other': 300,
            },
            monthlyHistory: [
              MonthData(DateTime(2026, 1), 4200, 3100),
              MonthData(DateTime(2026, 2), 4800, 3300),
              MonthData(DateTime(2026, 3), 5100, 3500),
              MonthData(DateTime(2026, 4), 4900, 3700),
              MonthData(DateTime(2026, 5), 5300, 3400),
              MonthData(DateTime(2026, 6), 5000, 3200),
            ],
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Haven_OS',
        theme: HavenTheme.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const SignInScreen(),
          '/home': (context) => AuthGuard(child: const HavenTabs()),
        },
      ),
    );
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
          foregroundColor: HavenColors.dark,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                appState.logout();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              tooltip: 'Logout',
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
          foregroundColor: HavenColors.dark,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                appState.logout();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: const Center(
          child: Text('Teen dashboard coming soon...'),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: TabBarView(
          children: [
            HomeScreen(),
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
              labelColor: HavenColors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: HavenColors.green,
              labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
