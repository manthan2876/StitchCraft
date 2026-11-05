import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/services/auth_service.dart';

class AuthRepository {
  final _authService = AuthService();

  Future<Map<String, dynamic>?> login(String email, String password) {
    return _authService.login(email, password);
  }

  Future<Map<String, dynamic>?> signUp(
    String email,
    String password,
    String name, {
    String? shopName,
    String? phone,
  }) {
    return _authService.signUp(
      email,
      password,
      name,
      shopName: shopName,
      phone: phone,
    );
  }

  Future<Map<String, dynamic>?> verifyEmailOtp(String email, String token) {
    return _authService.verifyEmailOtp(email, token);
  }

  Future<void> resendVerificationEmail(String email) {
    return _authService.resendVerificationEmail(email);
  }

  Future<void> logout() {
    return _authService.logout();
  }

  Future<String?> getToken() {
    return _authService.getToken();
  }

  Future<UserRole> getUserRole() {
    return _authService.getUserRoleEnum();
  }

  Future<bool> isOwner() => _authService.isOwner();
  Future<bool> isManager() => _authService.isManager();
  Future<bool> canManageShop() => _authService.canManageShop();
  Future<bool> canDeleteShop() => _authService.canDeleteShop();
}

