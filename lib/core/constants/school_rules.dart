import 'package:haven_os/core/enums/learning_mode.dart';

class SchoolRules {
  // Default settings
  static const bool allowFinalAnswers = false;
  static const SchoolAgeGroup defaultAgeGroup = SchoolAgeGroup.older;

  // Guiding response templates
  static const Map<SchoolSubject, List<String>> guidingQuestions = {
    SchoolSubject.math: [
      'What do you know about this problem so far?',
      'Can you break it down into smaller steps?',
      'What happens if you try it a different way?',
      'Does your answer make sense when you check it?',
    ],
    SchoolSubject.reading: [
      'What do you think the main idea is?',
      'Which sentence feels most important to you?',
      'Can you summarize that in your own words?',
      'What do you think happens next?',
    ],
    SchoolSubject.science: [
      'What did you observe?',
      'What do you think will happen next?',
      'How could you test that idea?',
      'What evidence do you have?',
    ],
    SchoolSubject.writing: [
      'What\'s the main idea you want to share?',
      'Who is your audience?',
      'Can you write one strong sentence about your topic?',
      'What details support your main idea?',
    ],
    SchoolSubject.general: [
      'What do you already know about this?',
      'Where does it start feeling confusing?',
      'Let\'s think about it step by step.',
      'What would you tell a friend about this?',
    ],
  };

  // Praise responses
  static const List<String> praiseResponses = [
    'Great thinking!',
    'Nice reasoning!',
    'That\'s a good question!',
    'I like how you\'re thinking about this.',
    'You\'re on the right track!',
    'That\'s a great observation!',
  ];

  // Encouragement for being stuck
  static const List<String> stuckResponses = [
    'It\'s okay to feel stuck. Let\'s take a step back.',
    'What part makes sense so far?',
    'Let\'s try looking at it from a different angle.',
    'Maybe draw a picture or write down what you know.',
  ];
}
