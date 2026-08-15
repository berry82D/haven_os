import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/core/enums/learning_mode.dart';
import 'package:haven_os/services/app_state.dart';

class HavenScreen extends StatefulWidget {
  const HavenScreen({super.key});

  @override
  State<HavenScreen> createState() => _HavenScreenState();
}

class _HavenScreenState extends State<HavenScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _response = '';
  String _responseType = 'general';
  bool _isGuiding = false;
  List<String> _hints = [];
  String _subject = 'general';

  final List<String> _schoolChips = [
    'Help with math',
    'What is the main idea?',
    'Is this right?',
    'Help me write this',
    'Science question',
  ];

  final List<String> _standardChips = [
    'How much can I spend?',
    'What needs attention today?',
    'Show me my animals',
    'Show bills due this week',
  ];

  void _askQuestion(String query) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isChild = appState.isChildAccount;

    // ---- FORCE SCHOOL HELP FOR CHILD ACCOUNTS ----
    if (isChild || appState.learningMode == LearningMode.schoolHelp) {
      final result = appState.learningService.processQuery(query);
      setState(() {
        _response = result['message'];
        _responseType = result['type'] ?? 'learning';
        _isGuiding = result['isGuiding'] ?? true;
        _hints = result['hints'] ?? [];
        _subject = result['subject'] ?? 'general';
      });
      return;
    }

    // ---- PARENT: Standard query service ----
    final result = appState.query.answer(
      query,
      transactions: appState.myTransactions,
      animals: appState.myAnimals,
      bills: appState.myBills,
      tasks: appState.myTasks,
    );
    setState(() {
      _response = result['message'] ??
          'I can help with money, farm, bills, or tasks. Ask me something specific.';
      _responseType = result['type'] ?? 'general';
      _isGuiding = false;
      _hints = [];
      _subject = 'general';
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isChild = appState.isChildAccount;

    // Force School Help for child accounts
    final isSchoolMode =
        isChild || appState.learningMode == LearningMode.schoolHelp;
    final chips = isSchoolMode ? _schoolChips : _standardChips;

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    isSchoolMode ? '🎓 Haven - School Help' : '🤖 Haven',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: HavenColors.dark,
                    ),
                  ),
                  const Spacer(),
                  // ---- Mode toggle: LOCKED for child accounts ----
                  if (!isChild)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeChip(
                            label: 'Daily Help',
                            isActive: !isSchoolMode,
                            onTap: () =>
                                appState.setLearningMode(LearningMode.standard),
                          ),
                          _buildModeChip(
                            label: 'School Help',
                            isActive: isSchoolMode,
                            onTap: () => appState
                                .setLearningMode(LearningMode.schoolHelp),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // ---- Child: Show locked mode indicator ----
              if (isChild)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.blue.shade800),
                      const SizedBox(width: 6),
                      Text(
                        '🔒 School Help mode is locked for child accounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  isSchoolMode
                      ? 'I help you learn by asking guiding questions. Let\'s figure it out together!'
                      : 'Your household assistant – ask anything about your home and farm.',
                  style: TextStyle(
                    color: HavenColors.muted,
                    fontSize: 14,
                  ),
                ),

              const SizedBox(height: 16),

              // ---- Query input ----
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: isSchoolMode
                            ? 'What do you need help with?'
                            : 'Ask a question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _askQuestion(value);
                          _queryController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: HavenColors.green),
                    onPressed: () {
                      if (_queryController.text.isNotEmpty) {
                        _askQuestion(_queryController.text);
                        _queryController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Quick chips ----
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips.map((chip) {
                  return ActionChip(
                    label: Text(chip),
                    backgroundColor: Colors.white,
                    onPressed: () => _askQuestion(chip),
                    side: BorderSide(
                      color: isSchoolMode
                          ? Colors.blue.shade300
                          : HavenColors.green.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ---- Response card ----
              Expanded(
                child: _response.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSchoolMode
                                  ? Icons.school
                                  : Icons.chat_bubble_outline,
                              size: 64,
                              color: HavenColors.lightMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSchoolMode
                                  ? 'Ask me a school question – I\'ll help you learn!'
                                  : 'Ask me something about your household',
                              style: TextStyle(
                                color: HavenColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildResponseIcon(
                                      _responseType, isSchoolMode),
                                  const SizedBox(width: 8),
                                  Text(
                                    _subject.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getResponseColor(
                                          _responseType, isSchoolMode),
                                    ),
                                  ),
                                  if (_isGuiding)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '💡 Guiding',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _response,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: HavenColors.dark,
                                ),
                              ),
                              if (_hints.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                Text(
                                  '💡 Try this:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ..._hints.map((hint) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, top: 4),
                                      child: Text(
                                        '• $hint',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: HavenColors.muted,
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? HavenColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : HavenColors.muted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResponseIcon(String type, bool isSchoolMode) {
    IconData icon;
    if (isSchoolMode) {
      switch (type) {
        case 'math':
          icon = Icons.calculate;
          break;
        case 'reading':
          icon = Icons.menu_book;
          break;
        case 'writing':
          icon = Icons.edit;
          break;
        case 'science':
          icon = Icons.science;
          break;
        default:
          icon = Icons.school;
      }
    } else {
      switch (type) {
        case 'balance':
          icon = Icons.money;
          break;
        case 'today':
          icon = Icons.today;
          break;
        case 'farm':
          icon = Icons.pets;
          break;
        case 'bills':
          icon = Icons.receipt_long;
          break;
        default:
          icon = Icons.info;
      }
    }
    return Icon(icon, color: _getResponseColor(type, isSchoolMode), size: 20);
  }

  Color _getResponseColor(String type, bool isSchoolMode) {
    if (isSchoolMode) {
      return Colors.blue;
    }
    switch (type) {
      case 'balance':
        return Colors.green;
      case 'today':
        return Colors.blue;
      case 'farm':
        return Colors.purple;
      case 'bills':
        return Colors.orange;
      default:
        return HavenColors.muted;
    }
  }
}
