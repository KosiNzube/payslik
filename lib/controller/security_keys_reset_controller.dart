import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityKeysResetController {

  /** VALIDATE THE INITIAL AND AFTER PASSWORD RESET ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessPaswordResetAttempt({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {

    String validationErrors = "";

    // App-level validations
    if (newPassword.isEmpty) {
      validationErrors += 'The New Password Field is required.\n';
    }
    if (newPasswordConfirmation.isEmpty) {
      validationErrors += 'The New Password Confirmation field is required.\n';
    }
    if (oldPassword.isEmpty) {
      validationErrors += 'The Old or Current Password Field is required.\n';
    }

    // final validation check
    if(validationErrors.isNotEmpty) {
      return {'status':'error', 'message':validationErrors};
    }

    
    // Call the API via the ApiService class
    final response = await ApiService.postRequest("/user/change-password", {
      'password': newPassword,
      'old_password': oldPassword,
      'password_confirmation': newPasswordConfirmation
    });

    if (response.containsKey('status')) {
      if (response['status'] == 'success' && response.containsKey('message')) {
        return {"status": "success", "message": response['message'], "data": response['data']??[]};
      } else if (response['status'] == 'failed' && response.containsKey('error')) {
        return {"status": "error", "message": response['error']};
      }
    }

    return {"status": "error", "message": "Changing User Password attempt failed."};
  }


  /** VALIDATE THE INITIAL AND AFTER TRANSACTION PIN RESET ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessTransactionPINResetAttempt({
    required String newTransactionPin,
    required String newTransactionPinConfirmation,
    bool isfinalSubmission = false,
    String oldTransactionPin = "",
  }) async {

    String validationErrors = "";

    // App-level validations
    if (newTransactionPin.isEmpty) {
      validationErrors += 'The New Transaction PIN field is required.\n';
    }
    if (newTransactionPinConfirmation.isEmpty) {
      validationErrors += 'The New Transaction PIN Confirmation field is required.\n';
    }

    // final validation check
    if(validationErrors.isNotEmpty) {
      return {'status':'error', 'message':validationErrors};
    }

    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {

      if (oldTransactionPin.isEmpty) {
        return {"status": "error", "message": "The old Transaction Pin provided is invalid."};
      }

      // Call the API via the ApiService class
      final response = await ApiService.postRequest("/user/change-pin", {
        'pin': newTransactionPin,
        'old_pin': oldTransactionPin,
        'pin_confirmation': newTransactionPinConfirmation,
      });

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message'], "data": response['data']??[]};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }

    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }

    return {"status": "error", "message": "Changing Transaction PIN attempt failed."};
  }


}

