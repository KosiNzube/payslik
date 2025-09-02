import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  // Store auth token securely
  static Future<void> storeAuthToken(String token) async {
    await _storage.write(key: "auth_token", value: token);
  }

  // Retrieve stored token
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: "auth_token");
  }

  // Logout: Clear stored token
  static Future<void> logoutUser() async {
    await _storage.delete(key: "auth_token");
  }
}
