import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:stitchcraft/core/services/auth_service.dart';

class ProfileService {
  final _authService = AuthService();

  // Fetch complete profile with signed avatar URL
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final profileResponse = await http.get(
        Uri.parse('${AuthService.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (profileResponse.statusCode == 200) {
        final data = json.decode(profileResponse.body) as Map<String, dynamic>;
        final avatarPath = data['avatar'] as String?;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          try {
            final encodedPath = Uri.encodeComponent(avatarPath);
            final viewUrlResponse = await http.get(
              Uri.parse('${AuthService.baseUrl}/upload/view-url/profile-images/$encodedPath'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            if (viewUrlResponse.statusCode == 200) {
              final viewData = json.decode(viewUrlResponse.body);
              data['avatar'] = viewData['signedUrl'];
            }
          } catch (e) {
            developer.log("Error loading avatar view url: $e", name: 'ProfileService');
          }
        }
        return data;
      }
    } catch (e) {
      developer.log("Error fetching profile: $e", name: 'ProfileService');
    }
    return null;
  }

  // Upload photo to Supabase storage bucket via signed upload URL
  Future<String?> uploadProfilePhoto(List<int> bytes, String fileName) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      // 1. Get signed upload URL from backend
      final urlResponse = await http.post(
        Uri.parse('${AuthService.baseUrl}/upload/get-upload-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bucketName': 'profile-images',
          'fileName': fileName,
        }),
      );

      if (urlResponse.statusCode != 200 && urlResponse.statusCode != 201) {
        throw Exception("Failed to get upload URL: ${urlResponse.body}");
      }

      final urlData = json.decode(urlResponse.body);
      final signedUrl = urlData['signedUrl'] as String?;
      if (signedUrl == null) {
        throw Exception("Signed URL not found in response: ${urlResponse.body}");
      }

      // 2. Put bytes directly to Supabase storage (no auth header needed)
      final uploadResponse = await http.put(
        Uri.parse(signedUrl),
        headers: {
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        return fileName;
      } else {
        throw Exception("Supabase upload failed: ${uploadResponse.body}");
      }
    } catch (e) {
      developer.log("Upload photo error: $e", name: 'ProfileService');
      rethrow;
    }
  }

  // Update profile details
  Future<Map<String, dynamic>?> updateProfile({String? name, String? avatar}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final bodyMap = <String, dynamic>{};
      if (name != null) bodyMap['name'] = name;
      if (avatar != null) bodyMap['avatar'] = avatar;

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bodyMap),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Update failed');
      }
    } catch (e) {
      developer.log("Update profile error: $e", name: 'ProfileService');
      rethrow;
    }
  }

  // Fetch shops
  Future<List<dynamic>> fetchShops() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/shops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      developer.log("Fetch shops error: $e", name: 'ProfileService');
    }
    return [];
  }

  // Switch shop
  Future<Map<String, dynamic>?> switchShop(String shopId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/auth/switch-shop/$shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', newToken);
          if (data['shopId'] != null) {
            await prefs.setString('shopId', data['shopId']);
          }
        }
        return data;
      }
    } catch (e) {
      developer.log("Switch shop error: $e", name: 'ProfileService');
    }
    return null;
  }
}
