import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  // Add helper method to get headers with auth token and appId
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String appId = prefs.getString('appId') ?? '';

    return {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Accept': 'application/json',
      'AppID': appId,
    };
  }

  // Update fetchUserProfile
  static Future<Map<String, dynamic>?> fetchUserProfile({bool forceRefresh = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest("/profile", extraHeaders: headers);
      debugPrint("🔹 User Profile API Response: $response");

      // Validate response structure
      if (response is! Map<String, dynamic>) {
        throw {
          'status': false,
          'message': 'Invalid response format',
          'data': null
        };
      }

      final bool? status = response["status"] as bool?;
      final dynamic responseData = response["data"];

      if (status == true && responseData != null) {
        final profileData = responseData as Map<String, dynamic>? ?? <String, dynamic>{};

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfileRaw', json.encode(profileData));

        // Handle wallet data safely
        final dynamic walletDataRaw = profileData["getPrimaryWallet"];
        final Map<String, dynamic>? walletData = walletDataRaw is Map<String, dynamic> ? walletDataRaw : null;

        // Handle KYC data safely
        final dynamic rawKyc = profileData["first_kyc_verification"];
        Map<String, dynamic>? firstKycVerification;

        if (rawKyc is List && rawKyc.isNotEmpty) {
          // If it's a non-empty list, take the first item
          final firstItem = rawKyc[0];
          if (firstItem is Map<String, dynamic>) {
            firstKycVerification = Map<String, dynamic>.from(firstItem);
          }
        } else if (rawKyc is Map<String, dynamic> && rawKyc.isNotEmpty) {
          // If it's a map directly
          firstKycVerification = Map<String, dynamic>.from(rawKyc);
        }
        // If it's null, empty array, or empty map, firstKycVerification remains null

        // Safely extract wallet information with proper null checks
        final dynamic walletBalanceRaw = walletData?["balance"];
        final dynamic walletNumberRaw = walletData?["wallet_number"];
        final dynamic currencyData = walletData?["currency"];
        final dynamic bankData = walletData?["bank"];

        final String? walletCurrency = currencyData is Map<String, dynamic> ? currencyData["code"] as String? : null;
        final String? bankName = bankData is Map<String, dynamic> ? bankData["name"] as String? : null;
        final String? walletNumber = walletNumberRaw as String?;
        final dynamic walletBalance = walletBalanceRaw;

        final bool hasWallet = walletData != null &&
            walletBalance != null &&
            walletNumber != null &&
            walletCurrency != null &&
            bankName != null;

        // Get organization info safely
        final dynamic organizationIdRaw = profileData["organization_id"];
        final String organizationId = organizationIdRaw?.toString() ?? '';

        // Safely extract status information
        final dynamic statusData = profileData["status"];
        final String statusLabel = statusData is Map<String, dynamic> ? (statusData["label"] as String? ?? 'Unknown') : 'Unknown';
        final String statusColor = statusData is Map<String, dynamic> ? (statusData["color"] as String? ?? '#000000') : '#000000';

        // Safely extract user type information
        final dynamic userTypeData = profileData["user_type"];
        final String userType = userTypeData is Map<String, dynamic> ? (userTypeData["type"] as String? ?? 'Unknown') : 'Unknown';

        // Safely extract ads data
        final dynamic adsData = profileData["ads"];
        final Map<String, dynamic> ads = adsData is Map<String, dynamic> ? adsData : <String, dynamic>{};

        Map<String, dynamic> userProfile = {
          'id': (profileData["id"] as String?) ?? '',
          'full_name': (profileData["full_name"] as String?) ?? '',
          'first_name': (profileData["first_name"] as String?) ?? '',
          'middle_name': (profileData["middle_name"] as String?) ?? '',
          'last_name': (profileData["last_name"] as String?) ?? '',
          'email': (profileData["email"] as String?) ?? '',
          'username': (profileData["username"] as String?) ?? '',
          'telephone': (profileData["telephone"] as String?) ?? '',
          'gender': (profileData["gender"] as String?) ?? '',
          'date_of_birth': (profileData["date_of_birth"] as String?) ?? '',
          'physical_address': (profileData["physical_address"] as String?) ?? '',
          'should_send_sms': (profileData["should_send_sms"] as bool?) ?? false,
          'job_title': (profileData["job_title"] as String?) ?? '',
          'profile_image_url': profileData["profile_image_url"] as String?,
          'status': statusLabel,
          'status_color': statusColor,
          'user_type': userType,
          'organization_id': organizationId,
          'organization': 'Unknown Org', // Since full org data isn't in response
          'wallet_balance': walletBalance?.toString() ?? "0.00",
          'wallet_number': walletNumber ?? "N/A",
          'wallet_currency': walletCurrency ?? "N/A",
          'bank_name': bankName ?? "N/A",
          'has_wallet': hasWallet,
          'first_kyc_verification': firstKycVerification ?? <String, dynamic>{},
          'kyc_image_encoding': (firstKycVerification?["imageEncoding"] as String?) ?? '',
          'getPrimaryWallet': walletData, // Keep original structure
          'ads': ads, // Include ads data
          'email_verified_at': profileData["email_verified_at"] as String?,
          'telephone_verified_at': profileData["telephone_verified_at"] as String?,
          'has_ever_loggedin': (profileData["has_ever_loggedin"] as bool?) ?? false,
          'last_loggedin_at': profileData["last_loggedin_at"] as String?,
          'created_at': profileData["created_at"] as String?,
          'updated_at': profileData["updated_at"] as String?,
          'last_updated': DateTime.now().toIso8601String(),
        };

        debugPrint("✅ Updated User Profile: $userProfile");
        return userProfile;
      } else {
        final String errorMessage = response["message"] as String? ?? 'Failed to load profile';
        debugPrint("⚠️ Error fetching profile: $errorMessage");
        throw {
          'status': status ?? false,
          'message': errorMessage,
          'data': responseData
        };
      }
    } catch (e) {
      debugPrint("❌ Profile API Error: $e");

      // If it's already a properly formatted error, re-throw it
      if (e is Map<String, dynamic>) {
        throw e;
      }

      // Otherwise, wrap it in a proper error format
      throw {
        'status': false,
        'message': e.toString(),
        'data': null
      };
    }
  }  // Change Password
  static Future<String> changePassword(
      String currentPassword, String newPassword, String newPasswordConfirmation) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_password_confirmation": newPasswordConfirmation,
      };

      final response = await ApiService.postRequest(
        "/change-password",
        body,
        extraHeaders: headers,
      );

      debugPrint("🔹 Change Password API Response: $response");

      if (response["status"] == true) {
        return "Password changed successfully."; // Return success message
      } else {
        return response["message"] ?? "Failed to change password."; // Return error message
      }
    } catch (e) {
      debugPrint("❌ Change Password API Error: $e");
      return "An error occurred while changing the password.";
    }
  }

  // Fetch Customer Support Details
  static Future<Map<String, dynamic>?> fetchCustomerSupportDetails() async {
    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/organizations/customer-support-details",
        extraHeaders: headers,
      );

      debugPrint("📞 Support API Response: $response");

      if (response["status"] == true) {
        final supportData = response["data"];

        // Store raw support data
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerSupportRaw', json.encode(supportData));

        final address = supportData["address"] ?? {};
        final socialMedia = supportData["social_media"] ?? {};

        Map<String, dynamic> parsedSupportDetails = {
          'organization_full_name': supportData["organization_full_name"] ?? '',
          'organization_short_name': supportData["organization_short_name"] ?? '',
          'organization_description': supportData["organization_description"] ?? '',
          'public_existing_website': supportData["public_existing_website"] ?? '',
          'official_email': supportData["official_email"] ?? '',
          'official_telephone': supportData["official_telephone"] ?? '',
          'support_hours': supportData["support_hours"] ?? '',
          'live_chat_url': supportData["live_chat_url"] ?? '',
          'faq_url': supportData["faq_url"] ?? '',
          'address': {
            'physical_address': address["physical_address"] ?? '',
            'country': address["country"] ?? '',
          },
          'social_media': {
            'twitter': socialMedia["twitter"] ?? '',
            'facebook': socialMedia["facebook"] ?? '',
            'instagram': socialMedia["instagram"] ?? '',
          },
        };

        // Store parsed data
        await prefs.setString('customerSupportDetails', json.encode(supportData));


        debugPrint("✅ Saved parsed support details to SharedPreferences.");
        return parsedSupportDetails;
      } else {
        debugPrint("⚠️ Failed to load support details: ${response["message"]}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Support API Error: $e");
      return null;
    }
  }



  // Change Transaction PIN
  static Future<String> changeTransactionPin(String currentPin, String newPin, String confirmPin) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {
        "current_pin": currentPin,
        "new_pin": newPin,
        'new_pin_confirmation':confirmPin,
      };

      final response = await ApiService.postRequest(
        "/change-transaction-pin",
        body,
        extraHeaders: headers,
      );

      debugPrint("🔹 Change Transaction PIN API Response: $response");

      if (response["status"] == true) {
        return "Transaction PIN changed successfully."; // Return success message
      } else {
        return response["message"] ?? "Failed to change transaction PIN."; // Return error message
      }
    } catch (e) {
      debugPrint("❌ Change Transaction PIN API Error: $e");
      return "An error occurred while changing the transaction PIN.";
    }
  }


  // Fetch All KYC Verifications
  static Future<List<Map<String, dynamic>>?> getKycVerifications() async {
    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/customers/kyc-verifications",
        extraHeaders: headers,
      );

      debugPrint("🔹 KYC Verifications API Response: $response");

      if (response["status"] == true) {
        final kycData = response["data"]["data"] as List<dynamic>;

        // Cast each KYC entry to a Map<String, dynamic> safely
        final List<Map<String, dynamic>> verifications = kycData
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        debugPrint("✅ Parsed KYC Verifications: $verifications");

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

  static Future<Map<String, dynamic>> linkKycVerification({
    required String idType,
    required String idValue,
    required String walletIdentifier,
    required String transactionPin,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? appId = prefs.getString('appId');

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Authentication required. Please log in again.'
        };
      }

      if (appId == null || appId.isEmpty) {
        return {
          'success': false,
          'message': '⚙️ App configuration missing. Please restart the app.'
        };
      }

      debugPrint("🔑 Token for link KYC: $token");
      debugPrint("🆔 AppID for link KYC: $appId");

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      final Map<String, dynamic> body = {
        "id_type": idType,
        "id_value": idValue,
        "customer_wallet_number_or_uuid": walletIdentifier,
        "transaction_pin": transactionPin,
      };

      debugPrint("📤 Submitting KYC Link Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response = await ApiService.postRequest(
        "/customers/kyc-verifications/link/verified",
        body,
        extraHeaders: headers,
      ).timeout(const Duration(seconds: 60));

      debugPrint("🔹 Link KYC API Response: $response");

      final bool status = response['status'] == true;
      final String message = (response['message'] ?? '').toString().trim();

      if (status) {
        return {
          'success': true,
          'message': "✅ KYC linked successfully."
        };
      } else {
        String friendlyMessage = '⚠️ Failed to link KYC.';

        if (message.isNotEmpty) {
          friendlyMessage = message;
        } else if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          friendlyMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : '⚠️ Failed to link KYC.';
        }

        return {'success': false, 'message': friendlyMessage};
      }

    } on SocketException {
      return {
        'success': false,
        'message': '📶 No internet connection. Please check your network and try again.'
      };
    } on ClientException {
      return {
        'success': false,
        'message': '🌐 Unable to connect to the server. Please try again later.'
      };
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (error.contains("socketexception") || error.contains("failed host lookup")) {
        return {
          'success': false,
          'message': '📡 Network error. Please check your internet connection.'
        };
      }

      debugPrint("❌ Link KYC API Error: $e");
      return {
        'success': false,
        'message': '❌ Something went wrong. Please try again shortly.'
      };
    }
  }


  // Fetch Wallets
  static Future<Map<String, dynamic>> fetchWallets() async {
    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: headers,
      );

      debugPrint("🔹 Wallets Profile API Response: $response");

      if (response["status"] == true && response["data"] is List) {
        List<dynamic> walletList = response["data"];

        if (walletList.isNotEmpty) {
          return {
            'data': walletList,
          };
        } else {
          debugPrint("ℹ️ No wallets found.");
          return {};
        }
      } else {
        debugPrint("⚠️ Invalid response format or status is false.");
        return {};
      }
    } catch (e) {
      debugPrint("❌ Wallets API Error: $e");
      return {};
    }
  }

}