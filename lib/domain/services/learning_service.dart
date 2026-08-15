import 'package:haven_os/core/enums/learning_mode.dart';
import 'package:haven_os/core/constants/school_rules.dart';

class LearningService {
  final SchoolAgeGroup ageGroup;
  final bool allowFinalAnswers;

  LearningService({
    this.ageGroup = SchoolAgeGroup.older,
    this.allowFinalAnswers = false,
  });

  /// Process a school/learning query
  Map<String, dynamic> processQuery(String query) {
    final lower = query.toLowerCase();

    // Detect subject
    final subject = _detectSubject(lower);

    // Check if it's a "just tell me" request
    if (_isAskingForAnswer(lower) && !allowFinalAnswers) {
      return _buildResponse(
        subject: subject,
        message: _getRefusalMessage(subject),
        isGuiding: true,
        hints: _getHints(subject),
      );
    }

    // Check if it's a math problem
    final mathResult = _parseMathProblem(query);
    if (mathResult != null) {
      return _buildMathResponse(mathResult);
    }

    // Check if it's reading comprehension
    if (_isReadingQuestion(lower)) {
      return _buildReadingResponse();
    }

    // Check if it's science
    if (_isScienceQuestion(lower)) {
      return _buildScienceResponse();
    }

    // Check if it's writing
    if (_isWritingQuestion(lower)) {
      return _buildWritingResponse();
    }

    // Default guiding response
    return _buildResponse(
      subject: subject,
      message: _getGuidingQuestion(subject),
      isGuiding: true,
      hints: _getHints(subject),
    );
  }

  // ---- Subject Detection ----

  SchoolSubject _detectSubject(String query) {
    if (query.contains(RegExp(r'\d+.*[×x\*+-/]|\+|\-|\*|divided by'))) {
      return SchoolSubject.math;
    }
    if (query.contains('read') ||
        query.contains('paragraph') ||
        query.contains('meaning') ||
        query.contains('understand')) {
      return SchoolSubject.reading;
    }
    if (query.contains('science') ||
        query.contains('experiment') ||
        query.contains('hypothesis') ||
        query.contains('evidence')) {
      return SchoolSubject.science;
    }
    if (query.contains('write') ||
        query.contains('essay') ||
        query.contains('paragraph') ||
        query.contains('spell')) {
      return SchoolSubject.writing;
    }
    return SchoolSubject.general;
  }

  // ---- Math ----

  Map<String, dynamic>? _parseMathProblem(String query) {
    // Parse: "15 × 8" or "15 x 8" or "15 * 8"
    final mathPattern = RegExp(r'(\d+)\s*[×x\*]\s*(\d+)');
    final match = mathPattern.firstMatch(query);
    if (match != null) {
      final num1 = int.parse(match.group(1)!);
      final num2 = int.parse(match.group(2)!);
      return {'type': 'multiplication', 'num1': num1, 'num2': num2};
    }

    // Parse: "15 + 8" or "15 - 8" etc.
    final addPattern = RegExp(r'(\d+)\s*\+\s*(\d+)');
    final addMatch = addPattern.firstMatch(query);
    if (addMatch != null) {
      final num1 = int.parse(addMatch.group(1)!);
      final num2 = int.parse(addMatch.group(2)!);
      return {'type': 'addition', 'num1': num1, 'num2': num2};
    }

    final subPattern = RegExp(r'(\d+)\s*\-\s*(\d+)');
    final subMatch = subPattern.firstMatch(query);
    if (subMatch != null) {
      final num1 = int.parse(subMatch.group(1)!);
      final num2 = int.parse(subMatch.group(2)!);
      return {'type': 'subtraction', 'num1': num1, 'num2': num2};
    }

    return null;
  }

  Map<String, dynamic> _buildMathResponse(Map<String, dynamic> mathData) {
    final num1 = mathData['num1'] as int;
    final num2 = mathData['num2'] as int;
    final type = mathData['type'] as String;

    String message;
    List<String> hints;

    switch (type) {
      case 'multiplication':
        final breakDown = num1 > 10
            ? 'What do you get if you do 10 × $num2 first? Then what about the remaining ${num1 - 10} × $num2?'
            : 'What do you get if you do $num1 × ${num2 ~/ 2} first? Then add $num1 × ${num2 - (num2 ~/ 2)}?';
        message = 'Great math question! Let\'s break it down. $breakDown';
        hints = [
          'Try breaking the numbers into smaller parts.',
          'What\'s $num1 × 10? Then what about $num1 × ${num2 - 10}?',
          'Add those two results together – what do you get?',
          'Does your answer seem reasonable?',
        ];
        break;

      case 'addition':
        message =
            'Let\'s add these numbers! What\'s $num1 + $num2? Think about it step by step.';
        hints = [
          'What\'s $num1 + 10? Then add the remaining ${num2 - 10}.',
          'Count up from $num1 by $num2 – what do you get?',
          'Does your answer seem reasonable?',
        ];
        break;

      case 'subtraction':
        message =
            'Let\'s subtract! What\'s $num1 - $num2? Take it step by step.';
        hints = [
          'What\'s $num1 - 10? Then subtract the remaining ${num2 - 10}.',
          'Count down from $num1 by $num2 – what do you get?',
          'Does your answer seem reasonable?',
        ];
        break;

      default:
        message = 'Let\'s work through this math problem together.';
        hints = [
          'What\'s the first thing you notice?',
          'What do you need to do first?'
        ];
    }

    return _buildResponse(
      subject: SchoolSubject.math,
      message: message,
      isGuiding: true,
      hints: hints,
    );
  }

  // ---- Reading ----

  bool _isReadingQuestion(String query) {
    final readingWords = [
      'read',
      'paragraph',
      'meaning',
      'understand',
      'main idea',
      'summary',
      'what does it mean'
    ];
    return readingWords.any((word) => query.contains(word));
  }

  Map<String, dynamic> _buildReadingResponse() {
    return _buildResponse(
      subject: SchoolSubject.reading,
      message:
          'Let\'s read it carefully together. What do you think the main idea is so far? Which sentence feels most important?',
      isGuiding: true,
      hints: [
        'Look at the first sentence – what is it telling you?',
        'What words are repeated? That might be the key idea.',
        'Can you summarize it in your own words?',
        'What do you think the author wants you to understand?',
      ],
    );
  }

  // ---- Science ----

  bool _isScienceQuestion(String query) {
    final scienceWords = [
      'science',
      'experiment',
      'hypothesis',
      'evidence',
      'observe',
      'test',
      'gravity',
      'plant',
      'animal'
    ];
    return scienceWords.any((word) => query.contains(word));
  }

  Map<String, dynamic> _buildScienceResponse() {
    return _buildResponse(
      subject: SchoolSubject.science,
      message:
          'Science is about asking questions and testing ideas! What do you think the answer is? What evidence do you have?',
      isGuiding: true,
      hints: [
        'What did you observe?',
        'What do you think will happen?',
        'How could you test your idea?',
        'What evidence supports your thinking?',
      ],
    );
  }

  // ---- Writing ----

  bool _isWritingQuestion(String query) {
    final writingWords = [
      'write',
      'essay',
      'paragraph',
      'spell',
      'sentence',
      'grammar',
      'edit'
    ];
    return writingWords.any((word) => query.contains(word));
  }

  Map<String, dynamic> _buildWritingResponse() {
    return _buildResponse(
      subject: SchoolSubject.writing,
      message:
          'Writing is a process! Let\'s think about what you want to say. What\'s your main idea?',
      isGuiding: true,
      hints: [
        'What\'s the most important thing you want to say?',
        'Who is your audience?',
        'Can you write one strong sentence about your main idea?',
        'What details support your main idea?',
      ],
    );
  }

  // ---- Helpers ----

  bool _isAskingForAnswer(String query) {
    final phrases = [
      'tell me the answer',
      'just tell me',
      'give me the answer',
      'what is the answer',
      'solve it for me'
    ];
    return phrases.any((phrase) => query.contains(phrase));
  }

  String _getRefusalMessage(SchoolSubject subject) {
    switch (subject) {
      case SchoolSubject.math:
        return 'I can help you figure it out step by step! Let\'s start with what you already know about the problem.';
      case SchoolSubject.reading:
        return 'Let\'s find the answer together. What do you think so far?';
      case SchoolSubject.science:
        return 'Great question! Let\'s think about it together. What do you already know?';
      case SchoolSubject.writing:
        return 'I\'d love to help you write it! What\'s the main idea you want to share?';
      default:
        return 'I can help you figure it out. What\'s the first step you see?';
    }
  }

  String _getGuidingQuestion(SchoolSubject subject) {
    final questions = SchoolRules.guidingQuestions[subject] ??
        SchoolRules.guidingQuestions[SchoolSubject.general]!;
    return questions[DateTime.now().second % questions.length];
  }

  List<String> _getHints(SchoolSubject subject) {
    final questions = SchoolRules.guidingQuestions[subject] ??
        SchoolRules.guidingQuestions[SchoolSubject.general]!;
    return questions;
  }

  Map<String, dynamic> _buildResponse({
    required SchoolSubject subject,
    required String message,
    required bool isGuiding,
    List<String>? hints,
  }) {
    // Add occasional praise
    final shouldPraise = DateTime.now().second % 3 == 0;
    final praise = shouldPraise
        ? SchoolRules.praiseResponses[
            DateTime.now().millisecond % SchoolRules.praiseResponses.length]
        : null;

    final fullMessage = praise != null ? '$praise $message' : message;

    return {
      'type': subject.name,
      'message': fullMessage,
      'isGuiding': isGuiding,
      'hints': hints ?? [],
      'subject': subject.name,
    };
  }
}
