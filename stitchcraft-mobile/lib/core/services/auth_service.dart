import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final DatabaseService _dbService = DatabaseService();

  static String get baseUrl {
    // Point directly to production Render backend server
    return 'https://stitchcraft-backend.onrender.com/api';
  }

  // Sign Up via Supabase Auth & provision MongoDB Atlas
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

      // 2. Provision user profile & default shop inside MongoDB Atlas
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
          role: (data['role']?.toString().toLowerCase().contains('admin') ?? false)
              ? UserRole.admin
              : UserRole.staff,
          updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
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

  // Login via Supabase Auth & sync profile details from MongoDB Atlas
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

      // 2. Fetch corresponding MongoDB Atlas user profile details
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
          role: role.toLowerCase().contains('admin') ? UserRole.admin : UserRole.staff,
          updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('token', token);
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

  // Get Current User Role
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'staff';
  }

  // Get Current JWT Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
