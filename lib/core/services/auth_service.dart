import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class AuthService {
  // Lazy initialization of FirebaseAuth
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Sign Up Error: ${e.code} - ${e.message}',
        name: 'AuthService',
      );
      rethrow;
    } catch (e) {
      developer.log('Unexpected Sign Up Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Login & Save Session
  Future<User?> login(String email, String password) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Professional Touch: Persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      // Simulating Role Retrieval (In real app, fetch from Firestore 'users' collection)
      // For MVP: If email contains 'admin', role is Admin, else Staff
      String role = email.toLowerCase().contains('admin') ? 'admin' : 'staff';
      await prefs.setString('userRole', role);

      return result.user;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Login Error: ${e.code} - ${e.message}',
        name: 'AuthService',
      );
      rethrow;
    } catch (e) {
      developer.log('Unexpected Login Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userRole');
    } catch (e) {
      developer.log('Logout Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Get Current User Role
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'staff';
  }
}
