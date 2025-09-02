import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AirtimeController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> buyAirtime({
    required String networkProvider,
    required String phoneNumber,
    required String amount,
    required String pin,
    }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return {'success': false, 'message': 'You’ve been logged out. Please log in again.'};
      }

      final String endpoint = "/transactions/buy-airtime";
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      final Map<String, dynamic> body = {
        "network_provider": networkProvider.toLowerCase(),
        "final_amount": double.tryParse(amount) ?? 0,
        "phone_number": phoneNumber,
        "transaction_pin": pin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      final status = response["status"];
      final message = (response["message"] ?? "").toString().trim();

      if (status == true) {
        return {'success': true, 'message': 'Airtime purchased successfully!'};
      } else {
        String friendlyMessage = "❌ Something went wrong.";
        if (message.toLowerCase().contains("invalid pin")) {
          friendlyMessage = "🔐 Your transaction PIN is incorrect.";
        } else if (message.toLowerCase().contains("insufficient")) {
          friendlyMessage =  message;
        } else if (message.toLowerCase().contains("unauthenticated")) {
          friendlyMessage =  message;
        } else if (message.isNotEmpty) {
          friendlyMessage = message;
        }

        return {'success': false, 'message': friendlyMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred. Please try again.'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Future<Map<String, dynamic>> buyAirtime({
  //   required String networkProvider,
  //   required String phoneNumber,
  //   required String amount,
  //   required String pin,
  //   }) async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? token = prefs.getString('auth_token');
  //     final String appId = prefs.getString('appId') ?? '';
  //
  //     if (token == null) {
  //       return {'success': false, 'message': 'You’ve been logged out. Please log in again.'};
  //     }
  //
  //     final String endpoint = "/transactions/buy-airtime";
  //     final Map<String, String> headers = {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //       'AppID': appId,
  //     };
  //
  //     final Map<String, dynamic> body = {
  //       "network_provider": networkProvider.toLowerCase(),
  //       "final_amount": double.tryParse(amount) ?? 0,
  //       "phone_number": phoneNumber,
  //       "transaction_pin": pin,
  //     };
  //
  //     final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
  //
  //     final bool status = response["status"] == true;
  //     final int statusCode = response["statusCode"] ?? 500; // Safe fallback
  //     final String message = (response["message"] ?? "").toString().trim();
  //
  //     if (status) {
  //       return {'success': true, 'message': 'Airtime purchased successfully!'};
  //     } else {
  //       String friendlyMessage;
  //
  //       if (statusCode == 401) {
  //         // If true HTTP 401, then it's session expired
  //         friendlyMessage = 'Session expired. Please login again.';
  //       } else {
  //         // Otherwise, use backend message or fallback
  //         friendlyMessage = message.isNotEmpty ? message : "❌ Something went wrong.";
  //       }
  //
  //       return {'success': false, 'message': friendlyMessage};
  //     }
  //   } catch (e) {
  //     return {'success': false, 'message': 'Network error occurred. Please try again.'};
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }


  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
