import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Login error: $e'); // ✅ Log specific error
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Sign-up error: $e'); // ✅ Log error to terminal
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
