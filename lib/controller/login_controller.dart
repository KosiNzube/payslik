import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> loginUser({
    String? username,
    String? password,
    bool useStoredCredentials = false,
  }) async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? finalUsername = username;
      String? finalPassword = password;

      if (useStoredCredentials) {
        finalUsername = prefs.getString('saved_username');
        finalPassword = prefs.getString('saved_password');
        if (finalUsername == null || finalPassword == null) {
          return {
            'success': false,
            'message': 'Stored credentials not found.',
          };
        }
      }

      if (finalUsername == null || finalPassword == null) {
        return {
          'success': false,
          'message': 'Username and password are required.',
        };
      }

      final body = {
        'username': finalUsername,
        'password': finalPassword,
      };

      const String endpoint = '/login';
      final appId = prefs.getString('appId') ?? '';
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers)
          .timeout(const Duration(seconds: 60));

      final bool status = response['status'] == true;
      final String message = (response['message'] ?? '').toString().trim();

      if (status && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final String? token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          return {
            'success': false,
            'message': 'Login succeeded but no token was returned.'
          };
        }

        print("\n\n\n\n\n\n\n\n\n************************"+token+"\n\n\n\n\n\n\n");

        await prefs.setString('auth_token', token);
        await prefs.setString('saved_username', finalUsername);
        await prefs.setString('saved_password', finalPassword);

        final profile = data['profile'];
        if (profile != null) {
          await prefs.setString('user_profile', jsonEncode(profile));
          await prefs.setString('first_name', profile['first_name'] ?? '');
          await prefs.setString('full_name', profile['full_name'] ?? '');

          final String? telephoneVerifiedAt = profile['telephone_verified_at'];
          bool isPhoneVerified = false;

          if (telephoneVerifiedAt != null && telephoneVerifiedAt.isNotEmpty) {
            try {
              DateTime.parse(telephoneVerifiedAt); // will throw if invalid
              isPhoneVerified = true;
            } catch (e) {
              // invalid format, leave isPhoneVerified as false
            }
          }

          await prefs.setBool('is_phone_verified', isPhoneVerified);
        }

        return {'success': true, 'message': '✅ Login successful!'};
      } else {
        return {
          'success': false,
          'message': message.isNotEmpty ? message : '❌ Login failed.'
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message':
        '⏱️ The request took too long. Please check your internet connection and try again.'
      };
    } catch (e) {
      return {'success': false, 'message': '❌ Unexpected error: $e'};
    } finally {
      _setLoading(false);
    }
  }



  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void showMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
