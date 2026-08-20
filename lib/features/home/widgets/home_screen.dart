// lib/features/home/widgets/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/features/home/widgets/morning_briefing.dart';
import 'package:haven_os/features/home/widgets/timeline_widget.dart';
import 'package:haven_os/features/home/widgets/haven_assistant.dart';
import 'package:haven_os/services/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      fontSize: 14,
                      color: HavenColors.muted,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => appState.refresh(),
                        color: HavenColors.muted,
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 20),
                        onPressed: () {},
                        color: HavenColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const MorningBriefing(),
              const SizedBox(height: 20),
              const TimelineWidget(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add Income',
                    color: Colors.green,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.remove_circle_outline,
                    label: 'Add Expense',
                    color: Colors.red,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.checklist_outlined,
                    label: 'Tasks',
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.pets,
                    label: 'Animals',
                    color: Colors.purple,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const HavenAssistant(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final day = _getDayOfWeek(now.weekday);
    return '$day, ${now.month}/${now.day}/${now.year}';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: HavenColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
