import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:gobeller/utils/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class WalletService {
  static const String _baseUrl = "https://app.gobeller.com/api/v1/customers/wallets?page=1&items_per_page=15";

  Future<Map<String, dynamic>?> fetchWalletData() async {
    try {
      String? token = await AuthService.getAuthToken();
      final prefs = await SharedPreferences.getInstance();
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        throw Exception("No authentication token found.");
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "AppID": appId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse["status"] == true && jsonResponse["data"]["data"].isNotEmpty) {
          final wallet = jsonResponse["data"]["data"][0];
          return {
            "wallet_number": wallet["wallet_number"],
            "balance": wallet["balance"],
            "currency_symbol": wallet["currency"]["symbol"],
          };
        }
      }

      return null;
    } catch (e) {
      print("Error fetching wallet data: $e");
      return null;
    }
  }


  static Future<Map<String, dynamic>> createCustomerWallet({
    required String accountType,
    required String currencyId,
    int retryCount = 0
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestBody = {
        'account_type': accountType,
        'currency_id': currencyId,
      };

      final response = await ApiService.postRequest(
        "/customers/wallets",
        requestBody,
        extraHeaders: extraHeaders,
      );

      if (response['status'] == 'success') {
        debugPrint("✅ Wallet created successfully");
        return response;
      } else {
        debugPrint("❌ Failed to create wallet: ${response['message']}");
        return response;
      }

    } catch (e) {
      debugPrint("❌ Error creating wallet: $e");
      return {
        'status': 'error',
        'message': 'Failed to create wallet: $e'
      };
    }
  }

// Usage example:
  static Future<void> createInternalWallet(String currency_ID) async {
    final result = await createCustomerWallet(
      accountType: "internal-account",
      currencyId: currency_ID,
    );

    if (result['status'] == 'success') {
      print("Wallet created successfully!");
      // Handle success - maybe navigate to wallet screen or show success message
    } else {
      print("Failed to create wallet: ${result['message']}");
      // Handle error - show error message to user
    }
  }
}
