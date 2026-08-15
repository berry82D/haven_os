import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatefulWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  static ({
    PasswordStrength strength,
    String feedback,
    int entropy,
    int rulesMet,
    List<String> ruleLabels
  }) evaluatePassword(String password) {
    if (password.isEmpty) {
      return (
        strength: PasswordStrength.empty,
        feedback: '',
        entropy: 0,
        rulesMet: 0,
        ruleLabels: []
      );
    }

    int rulesMet = 0;
    final List<String> ruleLabels = [];

    if (password.length >= 8) {
      rulesMet++;
      ruleLabels.add('✅ 8+ characters');
    } else {
      ruleLabels.add('❌ 8+ characters');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      rulesMet++;
      ruleLabels.add('✅ Uppercase');
    } else {
      ruleLabels.add('❌ Uppercase');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      rulesMet++;
      ruleLabels.add('✅ Number');
    } else {
      ruleLabels.add('❌ Number');
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      rulesMet++;
      ruleLabels.add('✅ Special');
    } else {
      ruleLabels.add('❌ Special');
    }

    PasswordStrength strength;
    String feedback;
    int entropy = 0;

    if (rulesMet == 0) {
      strength = PasswordStrength.empty;
      feedback = '';
    } else if (rulesMet <= 1) {
      strength = PasswordStrength.weak;
      feedback = 'Weak – add more variety';
    } else if (rulesMet == 2) {
      strength = PasswordStrength.medium;
      feedback = 'Medium – almost there';
    } else if (rulesMet == 3) {
      strength = PasswordStrength.good;
      feedback = 'Good – one more rule to go';
    } else {
      strength = PasswordStrength.strong;
      feedback = 'Strong – excellent password!';
    }

    entropy = rulesMet * 10 + password.length;

    return (
      strength: strength,
      feedback: feedback,
      entropy: entropy,
      rulesMet: rulesMet,
      ruleLabels: ruleLabels,
    );
  }

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator> {
  late String _password;
  PasswordStrength _strength = PasswordStrength.empty;
  String _feedback = '';
  int _entropy = 0;
  // _rulesMet removed because it was never used
  final List<String> _ruleLabels = [];

  @override
  void initState() {
    super.initState();
    _password = widget.password;
    _updateStrength();
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      _password = widget.password;
      _updateStrength();
    }
  }

  void _updateStrength() {
    final result = PasswordStrengthIndicator.evaluatePassword(_password);
    _strength = result.strength;
    _feedback = result.feedback;
    _entropy = result.entropy;
    // removed: _rulesMet = result.rulesMet;
    _ruleLabels.clear();
    _ruleLabels.addAll(result.ruleLabels);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _strength == PasswordStrength.empty
        ? Colors.grey.shade300
        : _strength == PasswordStrength.weak
            ? Colors.red
            : _strength == PasswordStrength.medium
                ? Colors.orange
                : _strength == PasswordStrength.good
                    ? Colors.lightBlue
                    : Colors.green;

    final textColor = _strength == PasswordStrength.empty
        ? Colors.grey
        : _strength == PasswordStrength.weak
            ? Colors.red.shade700
            : _strength == PasswordStrength.medium
                ? Colors.orange.shade700
                : _strength == PasswordStrength.good
                    ? Colors.lightBlue.shade700
                    : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: _strength == PasswordStrength.empty
                ? 0
                : _strength == PasswordStrength.weak
                    ? 0.25
                    : _strength == PasswordStrength.medium
                        ? 0.5
                        : _strength == PasswordStrength.good
                            ? 0.75
                            : 1.0,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _feedback,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_strength != PasswordStrength.empty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '~${_entropy.toString()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_password.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: _ruleLabels.map((label) {
              final isMet = label.startsWith('✅');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMet ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isMet ? Colors.green.shade200 : Colors.red.shade200,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMet ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

enum PasswordStrength { empty, weak, medium, good, strong }
