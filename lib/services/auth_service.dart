import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Email/Password Login
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // ✅ Email/Password Sign Up
  Future<bool> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Sign-up error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // ✅ Phone Number Verification
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    void Function(PhoneAuthCredential) onVerified,
    void Function(FirebaseAuthException) onFailed,
    void Function(String verificationId, int? resendToken) onCodeSent,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onVerified(credential);
      },
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // ✅ Sign In with SMS Code
  Future<void> signInWithSmsCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }
}

