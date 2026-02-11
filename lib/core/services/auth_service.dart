import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';

class AuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  // Sign Up
  Future<firebase_auth.User?> signUp(String email, String password, String name) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create Local User Record
      if (result.user != null) {
        final newUser = User(
            id: result.user!.uid,
            name: name,
            phone: email, // Using email as phone for now or need separate field
            role: email.toLowerCase().contains('admin') ? UserRole.admin : UserRole.staff,
            updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', newUser.role.toString().split('.').last);
      }

      return result.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Sign Up Error: ${e.code} - ${e.message}', name: 'AuthService');
      rethrow;
    } catch (e) {
      developer.log('Unexpected Sign Up Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Login & Save Session
  Future<firebase_auth.User?> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      firebase_auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final String userId = result.user?.uid ?? '';
      
      // Fetch Role from Local DB
      User? localUser = await _dbService.getUser(userId);
      
      String role = 'staff';
      if (localUser != null) {
          role = localUser.role.toString().split('.').last;
      } else {
          // If not in local DB (new device), deduce and create
          role = email.toLowerCase().contains('admin') ? 'admin' : 'staff';
          // Create local record
          final newUser = User(
              id: userId,
              name: result.user?.displayName ?? 'User',
              phone: email,
              role: role == 'admin' ? UserRole.admin : UserRole.staff,
              updatedAt: DateTime.now(),
          );
          await _dbService.addUser(newUser);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', role);

      return result.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Login Error: ${e.code} - ${e.message}', name: 'AuthService');
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

  // Get Current User Data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final localUser = await _dbService.getUser(currentUser.uid);
      if (localUser == null) return null;

      return {
        'email': currentUser.email ?? '',
        'shopName': localUser.name,
        'phone': localUser.phone,
        'role': localUser.role.toString().split('.').last,
      };
    } catch (e) {
      developer.log('Get User Data Error: $e', name: 'AuthService');
      return null;
    }
  }
}
