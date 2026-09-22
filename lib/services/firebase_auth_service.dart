// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  fb.User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // CREATE ACCOUNT - Sends verification link.
  //
  // signOutAfter controls what happens once the account is created:
  //   - true  (default): used by the real sign-up screen. A brand-new user
  //     must verify their email before they can actually sign in, so we
  //     sign them back out immediately and send them to the sign-in screen.
  //   - false: used when lazily migrating an existing local
  //     (SharedPreferences 'registered_users') account to Firebase on their
  //     next successful local-password login. They already proved they own
  //     the account by matching their existing password, so they stay
  //     signed in rather than being forced to re-verify before continuing
  //     to use an app they already had access to.
  Future<fb.User> createAccount(
    String email,
    String password,
    String username, {
    bool signOutAfter = true,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(username);
    await user.sendEmailVerification();

    // FIX: previously keyed this doc by `username`, which is not guaranteed
    // unique across Firebase accounts (two different emails could pick the
    // same display username) and would silently overwrite one another's
    // profile doc. Keyed by the real Firebase UID instead; username is
    // still stored as a field for lookups.
    await _firestore.collection('users').doc(user.uid).set({
      'email': email.trim(),
      'username': username,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'uid': user.uid,
    }, firestore.SetOptions(merge: true));

    if (signOutAfter) {
      await _auth.signOut();
    } else {
      await _storage.write(key: 'auth_username', value: username);
      await _storage.write(key: 'auth_email', value: email.trim());
    }

    return user;
  }

  // Raw sign-in with no verified-email enforcement. Callers that need to
  // distinguish "no account" from "wrong password" from "not verified"
  // (the sign-in screen's legacy-fallback logic) should use this directly
  // and inspect the thrown FirebaseAuthException's `.code` themselves.
  Future<fb.User> rawSignIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!;
  }

  // LOGIN - Convenience wrapper that also enforces email verification.
  Future<void> login(String email, String password) async {
    final user = await rawSignIn(email, password);
    if (!user.emailVerified) {
      await _auth.signOut();
      throw fb.FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email not verified - check inbox for link',
      );
    }
    final username = user.displayName ?? email.split('@')[0];
    await _storage.write(key: 'auth_username', value: username);
    await _storage.write(key: 'auth_email', value: email.trim());
  }

  // FORGOT - Sends a real password reset link to the given email.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> resendVerification() async {
    await _auth.currentUser!.sendEmailVerification();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _storage.delete(key: 'auth_username');
      await _storage.delete(key: 'auth_email');
      await _storage.delete(key: 'auth_token');
    } catch (_) {}
    // NOTE: left unchanged from the existing file — this wipes ALL
    // FlutterSecureStorage keys app-wide, not just the three above. If
    // anything else (e.g. PinLock) stores secrets in FlutterSecureStorage,
    // logging out would also clear those. Out of scope for tonight's
    // email-migration work; flagging rather than silently changing it.
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
