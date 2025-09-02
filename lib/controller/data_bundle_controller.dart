import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class DataBundleController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetches data bundles for the selected network
  static Future<List<Map<String, dynamic>>?> fetchDataBundles(String network) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found.");
        return null;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      String endpoint = "get-data-bundles/${network.toLowerCase()}-data";
      final response = await ApiService.getRequest("/transactions/$endpoint", extraHeaders: extraHeaders);

      debugPrint("🔹 Data Bundles API Response for $network: $response");

      if (response["status"] == true) {
        return List<Map<String, dynamic>>.from(response["data"]);
      } else {
        debugPrint("⚠️ Error fetching data bundles: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Data Bundle API Error: $e");
      return null;
    }
  }

  /// Buys a data bundle and returns a result map
  Future<Map<String, dynamic>> buyDataBundle({
    required String networkProvider,
    required String dataPlan,
    required String phoneNumber,
    required String pin,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return {
          'success': false,
          'message': '🔒 You’ve been logged out. Please log in again.',
        };
      }

      final String endpoint = "/transactions/buy-data-bundle";
      final Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "network_provider": "${networkProvider.toLowerCase()}-data",
        "data_plan": dataPlan,
        "phone_number": phoneNumber,
        "transaction_pin": pin,
      };

      debugPrint("📤 Sending Data Purchase Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 Data Purchase API Response: $response");

      final status = response["status"];
      final message = (response["message"] ?? "").toString().trim();

      if (status == true) {
        return {'success': true, 'message': '✅ Data purchase successful!'};
      } else {
        String friendlyMessage = "❌ Something went wrong.";
        if (message.toLowerCase().contains("invalid pin")) {
          friendlyMessage = "🔐 Your transaction PIN is incorrect.";
        } else if (message.toLowerCase().contains("insufficient")) {
          friendlyMessage = "💸 Your wallet doesn’t have enough funds.";
        } else if (message.toLowerCase().contains("unauthenticated")) {
          friendlyMessage = "🔒 Session expired. Please log in again.";
        } else if (message.isNotEmpty) {
          friendlyMessage = message;
        }

        return {'success': false, 'message': friendlyMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Network error occurred. Please try again.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
