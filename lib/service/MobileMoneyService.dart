import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class MobileMoneyService {

  /// Fetch all beneficiaries for the current user
  static Future<Map<String, dynamic>> fetchBeneficiaries({
    int page = 1,
    int itemsPerPage = 15,
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
      };

      final response = await ApiService.getRequest(
        "/customers/beneficiaries",
        extraHeaders: extraHeaders, // ✅ use both headers
      );

      if (response['status'] == true && response["data"] != null) {
        debugPrint("✅ Beneficiaries fetched successfully");
        return response;
      } else {
        debugPrint("❌ Failed to fetch beneficiaries: ${response['message']}");
        return response;
      }
    } catch (e) {
      debugPrint("❌ Error fetching beneficiaries: $e");
      return {'status': false, 'message': 'Error fetching beneficiaries: $e'};
    }
  }


  /// Create a mobile money contract (send/receive payment)
  static Future<Map<String, dynamic>> createMobileMoneyContract({
    required String walletUuid,
    required String contractType, // "deposit" or "payout"
    required double amount,
    required String recipientPhoneOrUuid,
    required String description,
    required String transactionPin,
    bool saveToBeneficiaries = true,
    String? networkProvider,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      final Map<String, dynamic> requestData = {
        "wallet_number_or_uuid": walletUuid,
        "contract_type": contractType,
        "contract_amount": amount,
        "recipient_or_payer_number_or_benf_uuid": recipientPhoneOrUuid,
        "contract_description": description,
        "transaction_pin": transactionPin,
        "should_save_recipient_or_payer_to_beneficiaries": saveToBeneficiaries,
      };

      if (networkProvider != null) {
        requestData["recipient_or_payer_network_provider"] = networkProvider;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Content-Type': 'application/json',
      };

      final response = await ApiService.postRequest(
        "/cross-border-payment-mgt/mobile-money-contracts",
        requestData,
        extraHeaders: extraHeaders,
      );

      if (response['status'] == true) {
        debugPrint("✅ Mobile money contract created successfully");
        return {"success": true, "message": response["message"] ?? "✅ Your transaction was successful! Funds have been sent."};
      } else {
        debugPrint("❌ Failed to create mobile money contract: ${response['message']}");
        return {"success": false, "message": response["message"] ?? "✅ Your transaction failed."};
      }
    } catch (e) {
      debugPrint("❌ Error creating mobile money contract: $e");
      return {"success": false, "message": 'Error creating mobile money contract: $e'};

    //  return {'status': false, 'message': 'Error creating mobile money contract: $e'};
    }
  }

  /// Get user wallets (assuming this endpoint exists)
  static Future<Map<String, dynamic>> fetchWallets({int retryCount = 0}) async {
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
      };

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Raw Wallets API Response: $response");

      // Check if response is null or empty
      if (response == null) {
        debugPrint("❌ Received null response from API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying due to null response (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1)); // Progressive delay
          return fetchWallets(retryCount: retryCount + 1);
        }
        throw Exception("API returned null response after retries");
      }

      // Handle successful response
      if (response["status"] == true || response["status"] == "success") {
        dynamic data = response["data"];

        // Handle if it's a JSON-encoded string
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            debugPrint("❌ Failed to decode wallet data: $e");
            throw Exception("Invalid JSON format in response");
          }
        }

        // Handle null or empty data
        if (data == null) {
          debugPrint("⚠️ API returned null data - treating as empty wallet list");
          return {'data': []};
        }

        // Pass the full list of wallets directly
        if (data is List) {
          debugPrint("✅ Found ${data.length} wallets");
          return {'data': data};
        }

        // Handle nested "data" key
        if (data is Map && data.containsKey("data")) {
          final nestedData = data["data"];
          if (nestedData is List) {
            debugPrint("✅ Found ${nestedData.length} wallets (nested)");
            return {'data': nestedData};
          } else if (nestedData == null) {
            debugPrint("⚠️ Nested data is null - treating as empty wallet list");
            return {'data': []};
          }
        }

        debugPrint("❌ Unexpected data format: $data (Type: ${data.runtimeType})");
        throw Exception("Unexpected data format from API");
      } else {
        final errorMsg = response["message"] ?? "Unknown API error";
        debugPrint("❌ API Error: $errorMsg (Status: ${response["status"]})");

        // Handle 401 errors with retry
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("🔁 401 Unauthorized - Retrying (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return fetchWallets(retryCount: retryCount + 1);
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Wallets API Exception: $e");

      // Handle network/timeout errors with retry
      if ((e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection')) &&
          retryCount < 3) {
        debugPrint("🔁 Network/Auth error - Retrying (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return fetchWallets(retryCount: retryCount + 1);
      }

      rethrow; // Re-throw the exception to be handled by the calling code
    }
  }
}
