import 'package:haven_os/core/enums/learning_mode.dart';

enum UserRole {
  administrator,
  adult,
  teen,
  child,
}

enum AccountType {
  parent,
  adult,
  teen,
  child,
}

class UserAccount {
  final String id;
  final String householdId;
  final String name;
  final UserRole role;
  final AccountType type;
  final bool hasPin;
  final bool useBiometrics;
  final bool autoLogin;
  final Map<String, bool> permissions;

  // NEW: per-account School Help settings. Previously these lived
  // as global fields on AppState, meaning every account on a device
  // shared one setting — wrong once multiple kids at different ages
  // use the same install. Defaults match AppState's old global
  // defaults (LearningMode.standard, SchoolAgeGroup index 1, false)
  // so existing behavior is unchanged for accounts that don't set
  // these explicitly.
  final LearningMode learningMode;
  final SchoolAgeGroup schoolAgeGroup;
  final bool allowFinalAnswers;

  UserAccount({
    required this.id,
    required this.householdId,
    required this.name,
    this.role = UserRole.adult,
    this.type = AccountType.adult,
    this.hasPin = false,
    this.useBiometrics = false,
    this.autoLogin = true,
    this.permissions = const {},
    this.learningMode = LearningMode.standard, // NEW
    this.schoolAgeGroup = SchoolAgeGroup.older, // NEW
    this.allowFinalAnswers = false, // NEW
  });

  bool get isChild => role == UserRole.child || type == AccountType.child;
  bool get isTeen => role == UserRole.teen || type == AccountType.teen;
  bool get isParent =>
      role == UserRole.administrator || type == AccountType.parent;
  bool get isAdult => role == UserRole.adult || type == AccountType.adult;

  Map<String, dynamic> toJson() => {
        'id': id,
        'householdId': householdId,
        'name': name,
        'role': role.index,
        'type': type.index,
        'hasPin': hasPin,
        'useBiometrics': useBiometrics,
        'autoLogin': autoLogin,
        'permissions': permissions,
        'learningMode': learningMode.index, // NEW
        'schoolAgeGroup': schoolAgeGroup.index, // NEW
        'allowFinalAnswers': allowFinalAnswers, // NEW
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      householdId: json['householdId'],
      name: json['name'],
      role: UserRole.values[json['role'] ?? 1],
      type: AccountType.values[json['type'] ?? 1],
      hasPin: json['hasPin'] ?? false,
      useBiometrics: json['useBiometrics'] ?? false,
      autoLogin: json['autoLogin'] ?? true,
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
      learningMode: // NEW
          LearningMode.values[json['learningMode'] ?? 0],
      schoolAgeGroup: // NEW
          SchoolAgeGroup.values[json['schoolAgeGroup'] ?? 1],
      allowFinalAnswers: json['allowFinalAnswers'] ?? false, // NEW
    );
  }
}
