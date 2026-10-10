// lib/features/auth/presentation/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/app_state.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../models/user_account.dart';
import '../../../models/household.dart';
import '../../../services/household_cloud_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'package:haven_os/features/haven_central/haven_central_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username or email is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Resolves the real username for this user. Order of trust:
  ///   1. Firestore users/{uid}.username (the profile - source of truth)
  ///   2. the Firebase Auth displayName, if it is set and is not the uid
  ///   3. the fallback passed in (legacy username or email prefix)
  /// Also repairs the Auth displayName so it matches the profile.
  Future<String> _resolveUsername(fb.User user, String fallback) async {
    String? fromProfile;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snap.exists) {
        final stored = (snap.data()?['username'] ?? '').toString().trim();
        if (stored.isNotEmpty && stored != user.uid) fromProfile = stored;
      }
    } catch (e) {
      debugPrint('profile lookup error: $e');
    }

    final current = user.displayName?.trim() ?? '';
    final currentUsable = current.isNotEmpty && current != user.uid;

    final String resolved;
    if (fromProfile != null) {
      resolved = fromProfile;
    } else if (currentUsable) {
      resolved = current;
    } else {
      resolved = fallback;
    }

    // Keep the Auth displayName in step with the resolved username.
    if (current != resolved) {
      try {
        await user.updateDisplayName(resolved);
      } catch (_) {}
    }

    return resolved;
  }

  /// Finds (or creates) the household this Firebase user belongs to in
  /// Firestore, makes sure its invite code is published, and remembers the
  /// household id in secure storage under 'household_id'.
  ///
  /// Order of choice when the user is in more than one household: a
  /// household they JOINED (someone else owns it) wins over their own solo
  /// one, so joining a partner sticks after the next sign-in.
  ///
  /// NOTE: UserAccount.householdId is deliberately left alone. Local lists
  /// (bills, gig income, animals) are filtered by it, so changing it here
  /// would hide data already saved on this phone.
  ///
  /// Never blocks sign-in: on any failure it returns a message to show.
  Future<String?> _ensureCloudHousehold(fb.User user, String username) async {
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('households')
          .where('memberIds', arrayContains: user.uid)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 12));

      Household? chosen;
      for (final d in snap.docs) {
        final h = Household.fromJson(d.data());
        if (h.id.isEmpty) continue;
        if (chosen == null || (chosen.ownerUserId == user.uid && h.ownerUserId != user.uid)) {
          chosen = h;
        }
      }

      if (chosen == null) {
        final code = await _freshInviteCode(db);
        chosen = Household(
          id: 'hh_${user.uid}',
          name: "$username's Household",
          createdAt: DateTime.now(),
          inviteCode: code,
          ownerUserId: user.uid,
          memberIds: [user.uid],
        );
      }

      // Publishes the household and its invite-code index (merge, so it is
      // safe to repeat on every sign-in).
      await HouseholdCloudService.instance
          .publishHousehold(chosen)
          .timeout(const Duration(seconds: 12));

      await const FlutterSecureStorage()
          .write(key: 'household_id', value: chosen.id);
      return null;
    } catch (e) {
      debugPrint('cloud household error: $e');
      return 'Signed in, but household sharing could not be set up: $e';
    }
  }

  Future<String> _freshInviteCode(FirebaseFirestore db) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    for (var i = 0; i < 6; i++) {
      final body = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
      final code = 'HAVEN-$body';
      final existing = await db.collection('household_invites').doc(code).get();
      if (!existing.exists) return code;
    }
    return 'HAVEN-${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  Future<void> _finalizeLogin(fb.User firebaseUser, String fallbackUsername) async {
    if (!mounted) return;

    final displayUsername = await _resolveUsername(firebaseUser, fallbackUsername);

    // The Firestore folder the app reads is chosen from this stored value
    // (see FirestoreService._getUserId). Set it here, on EVERY sign-in path,
    // from the resolved username - otherwise a stale value from an earlier
    // login or sign-up keeps pointing at the wrong folder.
    try {
      await const FlutterSecureStorage()
          .write(key: 'auth_username', value: displayUsername);
    } catch (e) {
      debugPrint('auth_username write error: $e');
    }

    final householdProblem =
        await _ensureCloudHousehold(firebaseUser, displayUsername);

    if (!mounted) return;

    if (householdProblem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(householdProblem),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 8),
        ),
      );
    }

    final appState = context.read<AppState>();
    final u = UserAccount(
      id: firebaseUser.uid,
      householdId: 'pending_join',
      name: displayUsername,
    );
    try {
      appState.setCurrentUser(u);
    } catch (e) {
      debugPrint('setCurrentUser error $e');
    }

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HavenCentralScreen(username: displayUsername),
      ),
    );
  }

  Future<void> _signIn() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (_validateIdentifier(identifier) != null ||
        _validatePassword(password) != null) {
      _showError('Please fill in all fields correctly');
      return;
    }

    setState(() => _isLoading = true);

    // ---- Step 1: check for a legacy local account (pre-Firebase-migration)
    // Real accounts created before the Firebase migration live in
    // SharedPreferences under 'registered_users'. If we find a match here,
    // we verify the password against the OLD local hash first - that's what
    // proves this person actually owns the account, since they may not have
    // a Firebase account yet at all.
    Map<String, dynamic>? legacyUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registered_users');
      if (usersJson != null && usersJson.isNotEmpty) {
        final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        final matches = users.where((u) {
          final storedUsername = (u['username'] ?? '').toString().trim();
          final storedEmail = (u['email'] ?? '').toString().trim();
          return storedUsername.toLowerCase() == identifier.toLowerCase() ||
              storedEmail.toLowerCase() == identifier.toLowerCase();
        }).toList();
        if (matches.isNotEmpty) legacyUser = matches.first;
      }
    } catch (e) {
      debugPrint('legacy lookup error: $e');
    }

    if (legacyUser != null) {
      final resolvedUsername = (legacyUser['username'] ?? identifier).toString();
      final resolvedEmail = (legacyUser['email'] ?? '').toString().trim();
      final salt = (legacyUser['salt'] ?? '').toString();
      final storedHash = (legacyUser['passwordHash'] ?? '').toString();
      final inputHash = _hashPassword(password, salt);

      if (storedHash.isEmpty || storedHash != inputHash) {
        setState(() => _isLoading = false);
        _showError('Wrong password for this account.');
        return;
      }

      if (resolvedEmail.isEmpty) {
        setState(() => _isLoading = false);
        _showError(
          "This account has no email on file, so it can't be upgraded "
          'automatically. Contact support to fix this manually.',
        );
        return;
      }

      try {
        final user = await FirebaseAuthService().rawSignIn(resolvedEmail, password);
        await _finalizeLogin(user, resolvedUsername);
        return;
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          try {
            final user = await FirebaseAuthService().createAccount(
              resolvedEmail,
              password,
              resolvedUsername,
              signOutAfter: false,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account upgraded! Check your email to verify it '
                    'when you get a chance.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
            await _finalizeLogin(user, resolvedUsername);
            return;
          } catch (e2) {
            setState(() => _isLoading = false);
            _showError('Could not upgrade account: $e2');
            return;
          }
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          setState(() => _isLoading = false);
          _showError(
            'This account was already upgraded and now uses a different '
            'password. Use "Forgot Password?" to reset it by email.',
          );
          return;
        } else {
          setState(() => _isLoading = false);
          _showError('Sign in error: ${e.message ?? e.code}');
          return;
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Sign in error: $e');
        return;
      }
    }

    // ---- Step 2: no legacy record - this is a Firebase-native account.
    if (!identifier.contains('@')) {
      setState(() => _isLoading = false);
      _showError('No account found for "$identifier".');
      return;
    }

    try {
      await FirebaseAuthService().login(identifier, password);
      final user = fb.FirebaseAuth.instance.currentUser!;

      // The email prefix is only the last-resort fallback. _finalizeLogin
      // prefers the Firestore profile username, then a usable displayName.
      final fallback = identifier.split('@')[0];
      await _finalizeLogin(user, fallback);
    } on fb.FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      switch (e.code) {
        case 'user-not-found':
          _showError('No account found for "$identifier".');
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _showError('Wrong password.');
          break;
        case 'email-not-verified':
          _showError(
            'Please verify your email first - check your inbox for the '
            'link we sent when you signed up.',
          );
          break;
        default:
          _showError('Sign in error: ${e.message ?? e.code}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Sign in error: $e');
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.teal.shade700,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome to Haven OS',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in with your Username or Email',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _identifierCtrl,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateIdentifier,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validatePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _signIn(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign In', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text('Create One'),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}