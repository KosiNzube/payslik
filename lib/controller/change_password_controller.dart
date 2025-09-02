import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Method to change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final String endpoint = "/api/v1/change-password";
      final Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_password_confirmation": newPasswordConfirmation,
      };

      debugPrint("📤 Sending Change Password Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 Change Password API Response: $response");

      if (response["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${response["message"]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: ${response["message"]}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Request failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
