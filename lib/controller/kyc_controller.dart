import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycVerificationController {
  static const _cacheKey = 'cached_kyc_verifications';

  /// Verify KYC using user ID
  static Future<Map<String, dynamic>?> verifyKycWithUserId({
    required String userId,
    required String idType,
    required String idValue,
    required String transactionPin,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      final body = {
        "id_type": idType,
        "id_value": idValue,
        "customer_wallet_number_or_uuid": userId,
        "transaction_pin": transactionPin,
      };

      debugPrint("🔑 Sending KYC verification request for user: $userId");
      debugPrint("ID Type: $idType");

      final response = await ApiService.postRequest(
        "/customers/kyc-verifications/link/verified",
        body,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 KYC Verification Response: $response");

      if (response["status"] == true) {
        return response["data"] as Map<String, dynamic>;
      } else {
        debugPrint("⚠️ KYC verification failed: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ KYC Verification Error: $e");
      return null;
    }
  }

  // Fetch All KYC Verifications
  static Future<List<Map<String, dynamic>>?> fetchKycVerifications() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return null;
      }

      debugPrint("🔑 Token for KYC fetch: $token");

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
      };

      final response = await ApiService.getRequest(
        "/customers/kyc-verifications",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 KYC Verifications API Response: $response");

      if (response["status"] == true && response["data"] != null) {
        final kycData = response["data"] as List<dynamic>;

        final List<Map<String, dynamic>> verifications = kycData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // ✅ Save to SharedPreferences as JSON string
        await prefs.setString(_cacheKey, jsonEncode(verifications));

        for (var verification in verifications) {
          debugPrint("🔍 KYC Verification: $verification");
        }

        return verifications;
      } else {
        debugPrint("⚠️ Error fetching KYC verifications: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ KYC Verifications API Error: $e");
      return null;
    }
  }

  // Optional: Load cached data from SharedPreferences
  static Future<List<Map<String, dynamic>>?> loadCachedKycVerifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint("❌ Error parsing cached KYC verifications: $e");
      }
    }
    return null;
  }
}
