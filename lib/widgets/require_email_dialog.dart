import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequireEmailDialog {
  static Future<void> checkAndPrompt(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    final hasEmail = user.email != null && user.email!.isNotEmpty;
    final hasStoredEmail = data != null && (data['email'] as String?)?.isNotEmpty == true;
    
    if (!hasEmail && !hasStoredEmail) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _RequireEmailPopup(),
      );
    }
  }
}

class _RequireEmailPopup extends StatefulWidget {
  const _RequireEmailPopup();
  @override
  State<_RequireEmailPopup> createState() => _RequireEmailPopupState();
}

class _RequireEmailPopupState extends State<_RequireEmailPopup> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _error;

  Future<void> _save() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter valid email');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.verifyBeforeUpdateEmail(email);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'email': email,
        'emailPendingVerification': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification sent to $email - Check inbox to keep your data safe')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Secure Your Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add email to verify your account so you won\'t lose your data on any device.'),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email for verification',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : _save,
          child: _sending ? const CircularProgressIndicator() : const Text('Send Verification Link'),
        ),
      ],
    );
  }
}
