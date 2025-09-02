import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  bool _isRequestingToken = false;
  String _requestError = '';
  bool _tokenRequested = false;
  String? _requestedEmail;

  // Add new state variables
  bool _isVerifyingToken = false;
  String _verificationError = '';
  bool _tokenVerified = false;

  // Add new state variables for password reset
  bool _isResettingPassword = false;
  String _resetError = '';
  bool _passwordReset = false;

  // Getters
  bool get isRequestingToken => _isRequestingToken;
  String get requestError => _requestError;
  bool get tokenRequested => _tokenRequested;
  String? get requestedEmail => _requestedEmail;

  // Add new getters
  bool get isVerifyingToken => _isVerifyingToken;
  String get verificationError => _verificationError;
  bool get tokenVerified => _tokenVerified;

  bool get isResettingPassword => _isResettingPassword;
  String get resetError => _resetError;
  bool get passwordReset => _passwordReset;

  /// Request password reset token
  Future<bool> requestResetToken(String email) async {
    try {
      _isRequestingToken = true;
      _requestError = '';
      _tokenRequested = false;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/password/request-token',
        {
          'email': email,
        },
      );

      // Enhanced console logging
      debugPrint('\n🔹 Reset Token Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Full Response: $response\n');

      if (response['status'] == true) {
        _tokenRequested = true;
        _requestedEmail = email;
        _requestError = '';
        notifyListeners();
        return true;
      } else {
        _requestError = response['message'] ?? 'Failed to request reset token';
        _tokenRequested = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Enhanced error logging
      debugPrint('\n❌ Reset Token Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Stack Trace: ${StackTrace.current}\n');

      _requestError = 'An error occurred while requesting reset token';
      _tokenRequested = false;
      notifyListeners();
      return false;
    } finally {
      _isRequestingToken = false;
      notifyListeners();
    }
  }

  /// Verify reset token
  Future<bool> verifyResetToken(String email, String token) async {
    try {
      _isVerifyingToken = true;
      _verificationError = '';
      _tokenVerified = false;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/password/verify-token',
        {
          'email': email,
          'token': token,
        },
      );

      // Enhanced console logging
      debugPrint('\n🔹 Token Verification Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Full Response: $response\n');

      if (response['status'] == true) {
        _tokenVerified = true;
        _verificationError = '';
        notifyListeners();
        return true;
      } else {
        _verificationError = response['message'] ?? 'Failed to verify token';
        _tokenVerified = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Enhanced error logging
      debugPrint('\n❌ Token Verification Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Stack Trace: ${StackTrace.current}\n');

      _verificationError = 'An error occurred while verifying the token';
      _tokenVerified = false;
      notifyListeners();
      return false;
    } finally {
      _isVerifyingToken = false;
      notifyListeners();
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _isResettingPassword = true;
      _resetError = '';
      _passwordReset = false;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/password/reset',
        {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      // Enhanced console logging
      debugPrint('\n🔹 Password Reset Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Full Response: $response\n');

      if (response['status'] == true) {
        _passwordReset = true;
        _resetError = '';
        notifyListeners();
        return true;
      } else {
        _resetError = response['message'] ?? 'Failed to reset password';
        _passwordReset = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Enhanced error logging
      debugPrint('\n❌ Password Reset Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Email: $email');
      debugPrint('└─ Stack Trace: ${StackTrace.current}\n');

      _resetError = 'An error occurred while resetting password';
      _passwordReset = false;
      notifyListeners();
      return false;
    } finally {
      _isResettingPassword = false;
      notifyListeners();
    }
  }

  /// Clear all state data
  @override
  void clearRequestData() {
    // Clear existing data
    _isRequestingToken = false;
    _requestError = '';
    _tokenRequested = false;
    _requestedEmail = null;

    // Clear verification data
    _isVerifyingToken = false;
    _verificationError = '';
    _tokenVerified = false;

    // Clear reset data
    _isResettingPassword = false;
    _resetError = '';
    _passwordReset = false;
    
    notifyListeners();
  }
}