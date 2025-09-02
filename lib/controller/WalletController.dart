import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/static_secure_storage_helper.dart';

class WalletController {
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
        "/customers/wallets?category=fiat",
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

  static Future<Map<String, dynamic>> fetchWalletsALL({int retryCount = 0}) async {
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




  static Future<Map<String, dynamic>> fetchCryptoWallets({int retryCount = 0}) async {
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
        "/customers/wallets?category=crypto",
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



  static Future<String?> _getAuthToken() async {
    try {
      return await StaticSecureStorageHelper.retrieveItem(key: 'auth_token');
    } catch (e) {
      debugPrint("❌ Error retrieving auth token: $e");
      return null;
    }
  }

  /// Get app ID from shared preferences
  static Future<String> _getAppId() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('appId') ?? '';
    } catch (e) {
      debugPrint("❌ Error retrieving app ID: $e");
      return '';
    }
  }

  /// Verify wallet address or account number
  static Future<Map<String, dynamic>> verifyWalletAddress(
      String walletNumber, {
        int retryCount = 0,
      }) async {
    try {
      final String? token = await _getAuthToken();
      final String appId = await _getAppId();

      debugPrint("🔍 Verifying wallet address: $walletNumber");

      final extraHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (appId.isNotEmpty) 'AppID': appId,
      };

      final response = await ApiService.getRequest(
        "/verify/wallet-number/$walletNumber",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Wallet Verification Response: $response");

      if (response == null) {
        debugPrint("❌ Received null response from verification API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying verification (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return verifyWalletAddress(walletNumber, retryCount: retryCount + 1);
        }
        throw Exception("Verification API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        debugPrint("✅ Wallet verification successful");
        return response;
      } else {
        final errorMsg = response["message"] ?? "Wallet verification failed";
        debugPrint("❌ Verification Error: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Wallet Verification Exception: $e");

      if (retryCount < 3 && (e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection'))) {
        debugPrint("🔁 Network/Auth error - Retrying verification (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return verifyWalletAddress(walletNumber, retryCount: retryCount + 1);
      }

      rethrow;
    }
  }

  /// Initiate wallet-to-wallet transaction
  static Future<Map<String, dynamic>> initiateWalletTransaction({
    required String sourceWalletNumber,
    required String destinationWalletNumber,
    required double amount,
    required String description,
    int retryCount = 0,
  }) async {
    try {
      final String? token = await _getAuthToken();
      final String appId = await _getAppId();

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      debugPrint("🚀 Initiating transaction: $sourceWalletNumber -> $destinationWalletNumber (₦$amount)");

      final extraHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (appId.isNotEmpty) 'AppID': appId,
      };

      final requestBody = {
        "source_wallet_number": sourceWalletNumber,
        "destination_wallet_number": destinationWalletNumber,
        "amount": amount,
        "description": description,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-to-wallet-transaction/initiate",
        requestBody,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Transaction Initiation Response: $response");

      if (response == null) {
        debugPrint("❌ Received null response from transaction initiation API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying initiation (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return initiateWalletTransaction(
            sourceWalletNumber: sourceWalletNumber,
            destinationWalletNumber: destinationWalletNumber,
            amount: amount,
            description: description,
            retryCount: retryCount + 1,
          );
        }
        throw Exception("Transaction initiation API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        debugPrint("✅ Transaction initiation successful");
        return response;
      } else {
        final errorMsg = response["message"] ?? "Transaction initiation failed";
        debugPrint("❌ Initiation Error: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Transaction Initiation Exception: $e");

      if (retryCount < 3 && (e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection'))) {
        debugPrint("🔁 Network/Auth error - Retrying initiation (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return initiateWalletTransaction(
          sourceWalletNumber: sourceWalletNumber,
          destinationWalletNumber: destinationWalletNumber,
          amount: amount,
          description: description,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  /// Process wallet-to-wallet transaction
  static Future<Map<String, dynamic>> processWalletTransaction({
    required String sourceWalletNumber,
    required String destinationWalletNumber,
    required double amount,
    required String description,
    required String transactionPin,
    int retryCount = 0,
  }) async {
    try {
      final String? token = await _getAuthToken();
      final String appId = await _getAppId();

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      debugPrint("🔄 Processing transaction: $sourceWalletNumber -> $destinationWalletNumber (₦$amount)");

      final extraHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (appId.isNotEmpty) 'AppID': appId,
      };

      final requestBody = {
        "source_wallet_number": sourceWalletNumber,
        "destination_wallet_number": destinationWalletNumber,
        "amount": amount,
        "description": description,
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-to-wallet-transaction/process",
        requestBody,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Transaction Processing Response: $response");

      if (response == null) {
        debugPrint("❌ Received null response from transaction processing API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying processing (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return processWalletTransaction(
            sourceWalletNumber: sourceWalletNumber,
            destinationWalletNumber: destinationWalletNumber,
            amount: amount,
            description: description,
            transactionPin: transactionPin,
            retryCount: retryCount + 1,
          );
        }
        throw Exception("Transaction processing API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        debugPrint("✅ Transaction processing successful");
        return response;
      } else {
        final errorMsg = response["message"] ?? "Transaction processing failed";
        debugPrint("❌ Processing Error: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Transaction Processing Exception: $e");

      if (retryCount < 3 && (e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection'))) {
        debugPrint("🔁 Network/Auth error - Retrying processing (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return processWalletTransaction(
          sourceWalletNumber: sourceWalletNumber,
          destinationWalletNumber: destinationWalletNumber,
          amount: amount,
          description: description,
          transactionPin: transactionPin,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  /// Initiate wallet funds swap (currency exchange)
  static Future<Map<String, dynamic>> initiateWalletFundsSwap({
    required String sourceWalletNumberOrUuid,
    required double sourceWalletSwapAmount,
    required String destinationWalletNumberOrUuid,
    required String description,
    int retryCount = 0,
  }) async {
    try {
      final String? token = await _getAuthToken();
      final String appId = await _getAppId();

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      debugPrint("🔄 Initiating funds swap: $sourceWalletNumberOrUuid -> $destinationWalletNumberOrUuid (₦$sourceWalletSwapAmount)");

      final extraHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'AppID': appId,
      };

      final requestBody = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "source_wallet_swap_amount": sourceWalletSwapAmount,
        "destination_wallet_number_or_uuid": destinationWalletNumberOrUuid,
        "description": description,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-funds-swap/initiate",
        requestBody,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Funds Swap Initiation Response: $response");

      if (response == null) {
        debugPrint("❌ Received null response from funds swap initiation API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying swap initiation (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return initiateWalletFundsSwap(
            sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
            sourceWalletSwapAmount: sourceWalletSwapAmount,
            destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
            description: description,
            retryCount: retryCount + 1,
          );
        }
        throw Exception("Funds swap initiation API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        debugPrint("✅ Funds swap initiation successful");
        return response;
      } else {
        final errorMsg = response["message"] ?? "Funds swap initiation failed";
        debugPrint("❌ Swap Initiation Error: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Funds Swap Initiation Exception: $e");

      if (retryCount < 3 && (e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection'))) {
        debugPrint("🔁 Network/Auth error - Retrying swap initiation (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return initiateWalletFundsSwap(
          sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
          sourceWalletSwapAmount: sourceWalletSwapAmount,
          destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
          description: description,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  /// Process wallet funds swap (currency exchange)
  static Future<Map<String, dynamic>> processWalletFundsSwap({
    required String sourceWalletNumberOrUuid,
    required double sourceWalletSwapAmount,
    required String destinationWalletNumberOrUuid,
    required String description,
    required String transactionPin,
    int retryCount = 0,
  }) async {
    try {
      final String? token = await _getAuthToken();
      final String appId = await _getAppId();

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      debugPrint("🔄 Processing funds swap: $sourceWalletNumberOrUuid -> $destinationWalletNumberOrUuid (₦$sourceWalletSwapAmount)");

      final extraHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'AppID': appId,
      };

      final requestBody = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "source_wallet_swap_amount": sourceWalletSwapAmount,
        "destination_wallet_number_or_uuid": destinationWalletNumberOrUuid,
        "description": description,
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-funds-swap/process",
        requestBody,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Funds Swap Processing Response: $response");

      if (response == null) {
        debugPrint("❌ Received null response from funds swap processing API");
        if (retryCount < 3) {
          debugPrint("🔁 Retrying swap processing (${retryCount + 1}/3)...");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return processWalletFundsSwap(
            sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
            sourceWalletSwapAmount: sourceWalletSwapAmount,
            destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
            description: description,
            transactionPin: transactionPin,
            retryCount: retryCount + 1,
          );
        }
        throw Exception("Funds swap processing API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        debugPrint("✅ Funds swap processing successful");
        return response;
      } else {
        final errorMsg = response["message"] ?? "Funds swap processing failed";
        debugPrint("❌ Swap Processing Error: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Funds Swap Processing Exception: $e");

      if (retryCount < 3 && (e.toString().contains('401') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection'))) {
        debugPrint("🔁 Network/Auth error - Retrying swap processing (${retryCount + 1}/3)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return processWalletFundsSwap(
          sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
          sourceWalletSwapAmount: sourceWalletSwapAmount,
          destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
          description: description,
          transactionPin: transactionPin,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  /// Complete wallet-to-wallet transaction flow (initiate + process)
  static Future<Map<String, dynamic>> completeWalletTransaction({
    required String sourceWalletNumber,
    required String destinationWalletNumber,
    required double amount,
    required String description,
    required String transactionPin,
    bool verifyWallets = true,
  }) async {
    try {
      debugPrint("🚀 Starting complete wallet transaction flow");

      // Step 1: Verify destination wallet if requested
      if (verifyWallets) {
        debugPrint("🔍 Verifying destination wallet...");
        await verifyWalletAddress(destinationWalletNumber);
      }

      // Step 2: Initiate transaction
      debugPrint("🚀 Initiating transaction...");
      final initiateResponse = await initiateWalletTransaction(
        sourceWalletNumber: sourceWalletNumber,
        destinationWalletNumber: destinationWalletNumber,
        amount: amount,
        description: description,
      );

      // Step 3: Process transaction
      debugPrint("🔄 Processing transaction...");
      final processResponse = await processWalletTransaction(
        sourceWalletNumber: sourceWalletNumber,
        destinationWalletNumber: destinationWalletNumber,
        amount: amount,
        description: description,
        transactionPin: transactionPin,
      );

      debugPrint("✅ Complete wallet transaction flow successful");
      return {
        "status": true,
        "message": "Transaction completed successfully",
        "initiate_response": initiateResponse,
        "process_response": processResponse,
      };
    } catch (e) {
      debugPrint("❌ Complete wallet transaction flow failed: $e");
      rethrow;
    }
  }

  /// Complete wallet funds swap flow (initiate + process)
  static Future<Map<String, dynamic>> completeWalletFundsSwap({
    required String sourceWalletNumberOrUuid,
    required double sourceWalletSwapAmount,
    required String destinationWalletNumberOrUuid,
    required String description,
    required String transactionPin,
  }) async {
    try {
      debugPrint("🚀 Starting complete wallet funds swap flow");

      // Step 1: Initiate swap
      debugPrint("🚀 Initiating funds swap...");
      final initiateResponse = await initiateWalletFundsSwap(
        sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
        sourceWalletSwapAmount: sourceWalletSwapAmount,
        destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
        description: description,
      );

      // Step 2: Process swap
      debugPrint("🔄 Processing funds swap...");
      final processResponse = await processWalletFundsSwap(
        sourceWalletNumberOrUuid: sourceWalletNumberOrUuid,
        sourceWalletSwapAmount: sourceWalletSwapAmount,
        destinationWalletNumberOrUuid: destinationWalletNumberOrUuid,
        description: description,
        transactionPin: transactionPin,
      );

      debugPrint("✅ Complete wallet funds swap flow successful");
      return {
        "status": true,
        "message": "Funds swap completed successfully",
        "initiate_response": initiateResponse,
        "process_response": processResponse,
      };
    } catch (e) {
      debugPrint("❌ Complete wallet funds swap flow failed: $e");
      rethrow;
    }
  }




}

