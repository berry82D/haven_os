import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haven_os/core/security/pin_lock.dart';
import 'package:haven_os/models/user_account.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  // Expose storage so other services (like HouseholdService) can use it.
  static FlutterSecureStorage get storage => _storage;

  static const String _accountsKey = 'accounts';
  static const String _currentUserIdKey = 'current_user_id';

  // ---- Account Management ----

  static Future<void> saveAccounts(List<UserAccount> accounts) async {
    final json = accounts.map((a) => a.toJson()).toList();
    await _storage.write(key: _accountsKey, value: jsonEncode(json));
  }

  static Future<List<UserAccount>> loadAccounts() async {
    final data = await _storage.read(key: _accountsKey);
    if (data == null) return [];
    try {
      final json = jsonDecode(data) as List;
      return json.map((j) => UserAccount.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCurrentUserId(String userId) async {
    await _storage.write(key: _currentUserIdKey, value: userId);
  }

  static Future<String?> loadCurrentUserId() async {
    return await _storage.read(key: _currentUserIdKey);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _accountsKey);
    await _storage.delete(key: _currentUserIdKey);
  }

  // ---- Create Account ----

  static Future<UserAccount> createAccount({
    required String name,
    required String householdId,
    AccountType type = AccountType.adult,
    UserRole role = UserRole.adult,
    bool hasPin = false,
    bool useBiometrics = false,
    bool autoLogin = true,
    Map<String, bool> permissions = const {}, // NEW
  }) async {
    final accounts = await loadAccounts();
    final newAccount = UserAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      householdId: householdId,
      name: name,
      type: type,
      role: role,
      hasPin: hasPin,
      useBiometrics: useBiometrics,
      autoLogin: autoLogin,
      permissions: permissions, // NEW
    );
    accounts.add(newAccount);
    await saveAccounts(accounts);
    return newAccount;
  }

  static Future<void> deleteAccount(String userId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == userId);
    await saveAccounts(accounts);
    final currentId = await loadCurrentUserId();
    if (currentId == userId) {
      await saveCurrentUserId('');
    }
  }

  // ---- Current User ----

  static Future<UserAccount?> getCurrentUser() async {
    final userId = await loadCurrentUserId();
    if (userId == null || userId.isEmpty) return null;
    final accounts = await loadAccounts();
    try {
      return accounts.firstWhere((a) => a.id == userId);
    } catch (_) {
      return null;
    }
  }

  static Future<UserAccount?> getUserById(String userId) async {
    final accounts = await loadAccounts();
    try {
      return accounts.firstWhere((a) => a.id == userId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateUser(UserAccount user) async {
    final accounts = await loadAccounts();
    final index = accounts.indexWhere((a) => a.id == user.id);
    if (index != -1) {
      accounts[index] = user;
      await saveAccounts(accounts);
    }
  }

  static Future<void> setCurrentUser(String userId) async {
    await saveCurrentUserId(userId);
  }

  static Future<void> logout() async {
    await saveCurrentUserId('');
  }

  // ---- PIN / Password Management (using PinLock) ----

  static Future<bool> verifyPin(String userId, String pin) async {
    return await PinLock.verifyPin(userId, pin);
  }

  static Future<void> setPin(String userId, String pin) async {
    await PinLock.setPin(userId, pin);
    // Update the account's hasPin flag
    final accounts = await loadAccounts();
    final index = accounts.indexWhere((a) => a.id == userId);
    if (index != -1) {
      final updated = UserAccount(
        id: accounts[index].id,
        householdId: accounts[index].householdId,
        name: accounts[index].name,
        type: accounts[index].type,
        role: accounts[index].role,
        hasPin: true,
        useBiometrics: accounts[index].useBiometrics,
        autoLogin: accounts[index].autoLogin,
        permissions: accounts[index].permissions,
      );
      accounts[index] = updated;
      await saveAccounts(accounts);
    }
  }

  static Future<void> removePin(String userId) async {
    await PinLock.removePin(userId);
    // Update the account's hasPin flag
    final accounts = await loadAccounts();
    final index = accounts.indexWhere((a) => a.id == userId);
    if (index != -1) {
      final updated = UserAccount(
        id: accounts[index].id,
        householdId: accounts[index].householdId,
        name: accounts[index].name,
        type: accounts[index].type,
        role: accounts[index].role,
        hasPin: false,
        useBiometrics: accounts[index].useBiometrics,
        autoLogin: accounts[index].autoLogin,
        permissions: accounts[index].permissions,
      );
      accounts[index] = updated;
      await saveAccounts(accounts);
    }
  }

  static Future<bool> hasPin(String userId) async {
    return await PinLock.hasPin(userId);
  }

  static Future<int> getRemainingAttempts(String userId) async {
    return await PinLock.getRemainingAttempts(userId);
  }

  static Future<Duration?> getLockoutRemaining(String userId) async {
    return await PinLock.getLockoutRemaining(userId);
  }
}
