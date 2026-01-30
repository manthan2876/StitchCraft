import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthService {
  // Lazy initialization of FirebaseAuth
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      developer.log('Sign Up Error: $e');
      return null;
    }
  }

  // Login & Save Session
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Professional Touch: Persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      return result.user;
    } catch (e) {
      developer.log('Login Error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
