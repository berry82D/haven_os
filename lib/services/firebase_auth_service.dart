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
  bool get isEmailVerified => _auth.currentUser?.emailVerified?? false;

  // CREATE ACCOUNT - Sends verification link
  Future<void> createAccount(String email, String password, String username) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
    await cred.user!.updateDisplayName(username);
    await cred.user!.sendEmailVerification();
    await _storage.write(key: 'auth_username', value: username);
    await _storage.write(key: 'auth_email', value: email.trim());
    await _firestore.collection('users').doc(username).set({
      'email': email.trim(),
      'username': username,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'uid': cred.user!.uid,
    }, firestore.SetOptions(merge: true));
  }

  // LOGIN - Checks verification
  Future<void> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    if (!(cred.user!.emailVerified)) {
      throw Exception('Email not verified - check inbox for link');
    }
    final username = cred.user!.displayName?? email.split('@')[0];
    await _storage.write(key: 'auth_username', value: username);
    await _storage.write(key: 'auth_email', value: email.trim());
  }

  // FORGOT - Sends password reset email link (verification)
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
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

