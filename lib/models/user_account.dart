// lib/models/user_account.dart
import 'package:haven_os/core/enums/learning_mode.dart';

enum UserRole { administrator, adult, teen, child }

enum AccountType { parent, adult, teen, child }

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
  final LearningMode learningMode;
  final SchoolAgeGroup schoolAgeGroup;
  final bool allowFinalAnswers;

  // ===== HOUSEHOLD ACCESS (added for invite system) =====
  /// When this account's household access expires. `null` = permanent.
  /// Set by InviteService when a viewer accepts a time-limited invite.
  final DateTime? accessExpiresAt;

  /// UID of the account that granted this access (for audit + revoke).
  /// `null` for the original owner / self-created accounts.
  final String? grantedByUid;
  // ======================================================

  // ===== PREFERENCES =====
  final String weightUnit; // 'lb' or 'kg'
  final String temperatureUnit; // 'C' or 'F'
  final String currencySymbol; // '$', 'EUR', 'GBP', 'JPY'
  final String dateFormat; // 'MM/dd/yyyy' or 'dd/MM/yyyy'
  final String languageCode; // 'en', 'es', etc. (future use)
  // =========================

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
    this.learningMode = LearningMode.standard,
    this.schoolAgeGroup = SchoolAgeGroup.older,
    this.allowFinalAnswers = false,
    this.accessExpiresAt,
    this.grantedByUid,
    this.weightUnit = 'lb',
    this.temperatureUnit = 'C',
    this.currencySymbol = '\$',
    this.dateFormat = 'MM/dd/yyyy',
    this.languageCode = 'en',
  });

  bool get isChild => role == UserRole.child || type == AccountType.child;
  bool get isTeen => role == UserRole.teen || type == AccountType.teen;
  bool get isParent =>
      role == UserRole.administrator || type == AccountType.parent;
  bool get isAdult => role == UserRole.adult || type == AccountType.adult;

  /// True if this account's household access is still valid right now.
  /// Permanent accounts (null expiry) always return true.
  bool get hasActiveAccess {
    if (accessExpiresAt == null) return true;
    return accessExpiresAt!.isAfter(DateTime.now());
  }

  /// True if this account's access has expired and needs renewal.
  bool get isAccessExpired {
    if (accessExpiresAt == null) return false;
    return accessExpiresAt!.isBefore(DateTime.now());
  }

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
        'learningMode': learningMode.index,
        'schoolAgeGroup': schoolAgeGroup.index,
        'allowFinalAnswers': allowFinalAnswers,
        'accessExpiresAt': accessExpiresAt?.toIso8601String(),
        'grantedByUid': grantedByUid,
        // preferences
        'weightUnit': weightUnit,
        'temperatureUnit': temperatureUnit,
        'currencySymbol': currencySymbol,
        'dateFormat': dateFormat,
        'languageCode': languageCode,
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
      learningMode: LearningMode.values[json['learningMode'] ?? 0],
      schoolAgeGroup: SchoolAgeGroup.values[json['schoolAgeGroup'] ?? 1],
      allowFinalAnswers: json['allowFinalAnswers'] ?? false,
      accessExpiresAt: json['accessExpiresAt'] != null
          ? DateTime.tryParse(json['accessExpiresAt'])
          : null,
      grantedByUid: json['grantedByUid'],
      weightUnit: json['weightUnit'] ?? 'lb',
      temperatureUnit: json['temperatureUnit'] ?? 'C',
      currencySymbol: json['currencySymbol'] ?? '\$',
      dateFormat: json['dateFormat'] ?? 'MM/dd/yyyy',
      languageCode: json['languageCode'] ?? 'en',
    );
  }
}
