import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Per-user PIN management with salted hashing and rate limiting
class PinLock {
  static const _storage = FlutterSecureStorage();

  // Key prefixes for per-user storage
  static const String _pinHashPrefix = 'pin_hash_';
  static const String _saltPrefix = 'pin_salt_';
  static const String _attemptsPrefix = 'pin_attempts_';
  static const String _lockoutUntilPrefix = 'pin_lockout_';

  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  // ---- Set PIN ----
  static Future<void> setPin(String userId, String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: '${_pinHashPrefix}$userId', value: hash);
    await _storage.write(key: '${_saltPrefix}$userId', value: salt);
    // Reset attempts when setting a new PIN
    await _storage.write(key: '${_attemptsPrefix}$userId', value: '0');
    await _storage.delete(key: '${_lockoutUntilPrefix}$userId');
  }

  // ---- Verify PIN ----
  static Future<bool> verifyPin(String userId, String pin) async {
    // Check lockout
    final lockoutUntil = await _getLockoutUntil(userId);
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      return false; // Account is locked
    }

    // Get stored hash and salt
    final hash = await _storage.read(key: '${_pinHashPrefix}$userId');
    final salt = await _storage.read(key: '${_saltPrefix}$userId');
    if (hash == null || salt == null) return false;

    // Verify
    final computedHash = _hashPin(pin, salt);
    final isValid = computedHash == hash;

    if (isValid) {
      // Reset attempts on success
      await _storage.write(key: '${_attemptsPrefix}$userId', value: '0');
      await _storage.delete(key: '${_lockoutUntilPrefix}$userId');
      return true;
    } else {
      // Increment attempts
      final attempts = await _getAttempts(userId);
      final newAttempts = attempts + 1;
      await _storage.write(
          key: '${_attemptsPrefix}$userId', value: newAttempts.toString());

      if (newAttempts >= _maxAttempts) {
        // Lock the account
        final lockoutUntil = DateTime.now().add(_lockoutDuration);
        await _storage.write(
          key: '${_lockoutUntilPrefix}$userId',
          value: lockoutUntil.toIso8601String(),
        );
      }
      return false;
    }
  }

  // ---- Check if user has a PIN ----
  static Future<bool> hasPin(String userId) async {
    final hash = await _storage.read(key: '${_pinHashPrefix}$userId');
    return hash != null;
  }

  // ---- Remove PIN ----
  static Future<void> removePin(String userId) async {
    await _storage.delete(key: '${_pinHashPrefix}$userId');
    await _storage.delete(key: '${_saltPrefix}$userId');
    await _storage.delete(key: '${_attemptsPrefix}$userId');
    await _storage.delete(key: '${_lockoutUntilPrefix}$userId');
  }

  // ---- Get remaining attempts ----
  static Future<int> getRemainingAttempts(String userId) async {
    final lockoutUntil = await _getLockoutUntil(userId);
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      return 0; // Locked out
    }
    final attempts = await _getAttempts(userId);
    return _maxAttempts - attempts;
  }

  // ---- Get lockout remaining time ----
  static Future<Duration?> getLockoutRemaining(String userId) async {
    final lockoutUntil = await _getLockoutUntil(userId);
    if (lockoutUntil == null) return null;
    final remaining = lockoutUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // ---- Private helpers ----

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    final combined = pin + salt;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<int> _getAttempts(String userId) async {
    final value = await _storage.read(key: '${_attemptsPrefix}$userId');
    return int.tryParse(value ?? '0') ?? 0;
  }

  static Future<DateTime?> _getLockoutUntil(String userId) async {
    final value = await _storage.read(key: '${_lockoutUntilPrefix}$userId');
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
