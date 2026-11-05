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
  Future<Map<String, dynamic>?> signUp(
    String email,
    String password,
    String name, {
    String? shopName,
    String? phone,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      // 1. Sign up with Supabase Auth
      final sbResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.stitchcraft://login-callback/',
        data: {
          'name': name,
          if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      final String? token = sbResponse.session?.accessToken;
      if (token == null) {
        return {
          'requiresVerification': true,
          'message': 'Account created! Please check your email to verify your account before logging in.',
        };
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
          if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
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
        await prefs.setString('userRole', data['role'] ?? 'owner');
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

  // Verify email using 6-digit OTP code or confirmation token received in Gmail
  Future<Map<String, dynamic>?> verifyEmailOtp(String email, String token) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanToken = token.trim();
      if (cleanEmail.isEmpty || cleanToken.isEmpty) {
        throw Exception('Email and verification code are required');
      }

      AuthResponse? authResp;
      // 1. Try Supabase verification directly
      try {
        if (cleanToken.length <= 8 && int.tryParse(cleanToken) != null) {
          authResp = await Supabase.instance.client.auth.verifyOTP(
            email: cleanEmail,
            token: cleanToken,
            type: OtpType.signup,
          );
        } else {
          String tokenHash = cleanToken;
          if (cleanToken.contains('token=')) {
            final uri = Uri.tryParse(cleanToken);
            tokenHash = uri?.queryParameters['token'] ?? cleanToken;
          }
          authResp = await Supabase.instance.client.auth.verifyOTP(
            tokenHash: tokenHash,
            type: OtpType.signup,
          );
        }
      } catch (sbErr) {
        developer.log('Direct Supabase verify note: $sbErr', name: 'AuthService');
      }

      // 2. Call backend /api/auth/verify to provision user & shop
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': cleanEmail,
          'token': cleanToken,
          'type': 'signup',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final sessionToken = authResp?.session?.accessToken ?? data['token'];
        if (sessionToken != null) {
          await _secureStorage.write(key: _tokenKey, value: sessionToken);
        }

        final userObj = data['user'] ?? data;
        final String userId = userObj['_id'] ?? userObj['id'] ?? '';
        final String userName = userObj['name'] ?? '';
        final String userEmail = userObj['email'] ?? cleanEmail;
        final String role = userObj['role'] ?? 'owner';
        final String? shopId = userObj['shopId'] is Map
            ? userObj['shopId']['_id']
            : userObj['shopId'];

        final newUser = User(
          id: userId,
          name: userName,
          phone: userEmail,
          role: UserRole.fromString(role),
          updatedAt: DateTime.now(),
        );
        await _dbService.addUser(newUser);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.remove('token');
        if (userId.isNotEmpty) await prefs.setString('userId', userId);
        if (userName.isNotEmpty) await prefs.setString('userName', userName);
        await prefs.setString('userRole', role);
        if (shopId != null && shopId.toString().isNotEmpty) {
          await prefs.setString('shopId', shopId.toString());
        }

        return data;
      } else {
        if (authResp?.session != null) {
          final token = authResp!.session!.accessToken;
          await _secureStorage.write(key: _tokenKey, value: token);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          return {'verified': true, 'token': token};
        }
        throw Exception(data['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      developer.log('Verify Email Error: $e', name: 'AuthService');
      rethrow;
    }
  }

  // Resend verification email via Gmail SMTP
  Future<void> resendVerificationEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address');
    }

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
        emailRedirectTo: 'io.supabase.stitchcraft://login-callback/',
      );
    } catch (e) {
      developer.log('Supabase direct resend note: $e', name: 'AuthService');
      // Fallback: request via backend resend endpoint
      final res = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': cleanEmail}),
      );
      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        throw Exception(body['message'] ?? 'Failed to resend verification email');
      }
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
        final String role = data['role'] ?? 'owner';
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
        final String? previousShopId = prefs.getString('shopId');
        if (shopId != null && previousShopId != null && previousShopId != shopId) {
          // If a different shop logs in on the device, clear out old shop data to prevent cross-tailor data leakage
          await _dbService.clearAllData();
        }

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

      // Clear local database so no tailor's data leaks to another tailor on this device
      await _dbService.clearAllData();
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

  // Get Current User ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Get Current User Model
  Future<User?> getCurrentUser() async {
    try {
      final userId = await getUserId();
      if (userId == null) return null;
      return await _dbService.getUser(userId);
    } catch (_) {
      return null;
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
