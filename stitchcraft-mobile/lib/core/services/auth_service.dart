import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:stitchcraft/core/config/api_config.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const String _tokenKey = 'auth_token';

  static String get baseUrl => ApiConfig.baseUrl;

  // Sign Up via Supabase Auth and provision the application profile
  Future<Map<String, dynamic>?> signUp(String email, String password, String name) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      // 1. Sign up with Supabase Auth
      final sbResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final String? token = sbResponse.session?.accessToken;
      if (token == null) {
        throw Exception('Please verify your email address to complete registration.');
      }

      // 2. Provision the user profile and default shop through the API
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save local user copy
        final newUser = User(
          id: data['_id'] ?? data['id'] ?? '',
          name: data['name'] ?? name,
          phone: data['email'] ?? email,
          role: UserRole.fromString(data['role']),
          updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);

        // Save session token in hardware-backed secure storage
        await _secureStorage.write(key: _tokenKey, value: token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token'); // Clear from plaintext storage
        await prefs.setString('userId', newUser.id);
        await prefs.setString('userName', newUser.name);
        await prefs.setString('userRole', data['role'] ?? 'staff');
        if (data['shopId'] != null) {
          await prefs.setString('shopId', data['shopId']);
        }
        await prefs.setBool('isLoggedIn', true);

        return data;
      } else {
        throw Exception(data['message'] ?? 'Sign Up Failed');
      }
    } catch (e) {
      developer.log('Sign Up Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Login via Supabase Auth and sync profile details from the API
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      // 1. Authenticate with Supabase Auth
      final sbResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final String? token = sbResponse.session?.accessToken;
      if (token == null) {
        throw Exception('Failed to obtain authentication token from Supabase');
      }

      // 2. Fetch the corresponding application profile
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final String userId = data['_id'] ?? data['id'] ?? '';
        final String userName = data['name'] ?? '';
        final String userEmail = data['email'] ?? email;
        final String role = data['role'] ?? 'staff';
        final String? shopId = data['shopId'] is Map ? data['shopId']['_id'] : data['shopId'];

        // Save local user copy
        final newUser = User(
          id: userId,
          name: userName,
          phone: userEmail,
          role: UserRole.fromString(role),
          updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);

        // Save session token in hardware-backed secure storage
        await _secureStorage.write(key: _tokenKey, value: token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.remove('token'); // Clear from plaintext storage
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setString('userRole', role);
        final String? avatar = data['avatar'] ?? data['avatarUrl'];
        if (avatar != null && avatar.isNotEmpty) {
          await prefs.setString('userAvatar', avatar);
        } else {
          await prefs.remove('userAvatar');
        }
        if (shopId != null) {
          await prefs.setString('shopId', shopId);
        }

        return data;
      } else {
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      developer.log('Login Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Logout cleanly from both Supabase Auth and Local Session
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await _secureStorage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('userAvatar');
      await prefs.remove('shopId');
    } catch (e) {
      developer.log('Logout Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Send Password Reset Email via Supabase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty) {
        throw Exception('Please enter your email address');
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(cleanEmail);
    } catch (e) {
      developer.log('Password Reset Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Get Current User Role
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'staff';
  }

  Future<UserRole> getUserRoleEnum() async {
    final roleStr = await getUserRole();
    return UserRole.fromString(roleStr);
  }

  Future<bool> isOwner() async => (await getUserRoleEnum()).isOwner;
  Future<bool> isManager() async => (await getUserRoleEnum()).isManager;
  Future<bool> isStaff() async => (await getUserRoleEnum()).isStaff;
  Future<bool> isKarigar() async => (await getUserRoleEnum()).isKarigar;
  Future<bool> canManageShop() async => (await getUserRoleEnum()).canManageShop;
  Future<bool> canDeleteShop() async => (await getUserRoleEnum()).canDeleteShop;
  Future<bool> canManageStaff() async => (await getUserRoleEnum()).canManageStaff;
  Future<bool> canDeleteOrders() async => (await getUserRoleEnum()).canDeleteOrders;
  Future<bool> canViewFinancials() async => (await getUserRoleEnum()).canViewFinancials;

  // Get Current JWT Token (from Supabase Auth session with fallback to Secure Storage)
  Future<String?> getToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        if (session.isExpired) {
          developer.log('Supabase token expired. Refreshing session...', name: 'AuthService');
          final response = await Supabase.instance.client.auth.refreshSession();
          final newToken = response.session?.accessToken;
          if (newToken != null && newToken.isNotEmpty) {
            await _secureStorage.write(key: _tokenKey, value: newToken);
            return newToken;
          }
        } else {
          final token = session.accessToken;
          if (token.isNotEmpty) {
            return token;
          }
        }
      }
    } catch (e) {
      developer.log('Supabase token check/refresh note: $e', name: 'AuthService');
    }

    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // Auto-migrate legacy token if present
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString('token');
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove('token');
      return legacyToken;
    }

    return null;
  }

  // Force refresh active session token
  Future<String?> refreshToken() async {
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      final newToken = response.session?.accessToken;
      if (newToken != null && newToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: newToken);
        return newToken;
      }
    } catch (e) {
      developer.log('Forced token refresh note: $e', name: 'AuthService');
    }
    return null;
  }

  // Get Current User Data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return null;

      final localUser = await _dbService.getUser(userId);
      if (localUser == null) return null;

      return {
        'email': localUser.phone, // Phone acts as email in user model mapping
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
