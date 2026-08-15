// lib/features/haven_central/command_parser.dart
import 'haven_central_viewmodel.dart';

class CommandParser {
  static String parse(String input, HavenCentralViewModel model) {
    final lower = input.toLowerCase().trim();

    final addMatch =
        RegExp(r'add\s+(\d+\.?\d*)\s+(?:to\s+)?(.+)', caseSensitive: false)
            .firstMatch(lower);
    if (addMatch != null) {
      final amount = double.tryParse(addMatch.group(1)!) ?? 0.0;
      final category = addMatch.group(2)!.trim();
      if (category.contains('income') || category.contains('salary')) {
        model.addIncome(amount, category);
        return '✅ Added \$${amount.toStringAsFixed(2)} as income to "$category".';
      } else {
        model.addExpense(amount, category);
        return '✅ Added \$${amount.toStringAsFixed(2)} as expense to "$category".';
      }
    }

    if (lower.contains('overdue') && lower.contains('task')) {
      final overdue = model.tasks
          .where((t) => !t.isDone && t.dueDate.isBefore(DateTime.now()))
          .toList();
      if (overdue.isEmpty) return '🎉 No overdue tasks!';
      return '⚠️ Overdue tasks:\n${overdue.map((t) => '• ${t.title}').join('\n')}';
    }

    if (lower.contains('farm') && lower.contains('status')) {
      return model.farmStatus();
    }

    if (lower == 'help' || lower == '?') {
      return '''
Available commands:
• "Add \$50 to groceries" – adds expense
• "Add income \$200" – adds income
• "Show overdue tasks"
• "Farm status"
• "Help"
''';
    }

    return '🤖 I didn\'t understand. Try "Help" for commands.';
  }
}
