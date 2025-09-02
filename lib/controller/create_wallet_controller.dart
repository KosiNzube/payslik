import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CurrencyController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _balance = 0.0;
  double get balance => _balance;

  // Fetch available currencies from the API
  static Future<List<Map<String, dynamic>>> fetchCurrencies({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      final headers = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];
      }

      final response = await ApiService.getRequest(
        "/customers/currencies?page=1&items_per_page=15&category=fiat",
        extraHeaders: headers,
      );

      debugPrint(response.toString());

      if (response["status"] == false) {
        debugPrint("Error: ${response["message"]}");
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchCurrencies(retryCount: retryCount + 1);  // Retry up to 3 times
        }
        return [];
      }

      var currencies = response["data"]["data"];
      return List<Map<String, dynamic>>.from(currencies);
    } catch (e) {
      debugPrint("❌ Currencies API Error: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCurrencieX({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String appId = prefs.getString('appId') ?? '';

      final extraHeaders = {
        'AppID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };


      final response = await ApiService.getRequest(
        "/organizations/open-currencies/supported?page=1&items_per_page=15",
        extraHeaders: extraHeaders,
      );

      debugPrint(response.toString());

      if (response["status"] == false) {
        debugPrint("Error: ${response["message"]}");
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchCurrencies(retryCount: retryCount + 1);  // Retry up to 3 times
        }
        return [];
      }

      var currencies = response["data"]["data"];
      return List<Map<String, dynamic>>.from(currencies);
    } catch (e) {
      debugPrint("❌ Currencies API Error: $e");
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> fetchCurrenciesMM({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      final headers = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];
      }

      final response = await ApiService.getRequest(
        "/customers/currencies?page=1&items_per_page=15&category=fiat&type=mobilemoney",
        extraHeaders: headers,
      );

      if (response["status"] == false) {
        debugPrint("Error: ${response["message"]}");
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchCurrencies(retryCount: retryCount + 1);  // Retry up to 3 times
        }
        return [];
      }

      var currencies = response["data"]["data"];
      return List<Map<String, dynamic>>.from(currencies);
    } catch (e) {
      debugPrint("❌ Currencies API Error: $e");
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> fetchCryptoCurrencies({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      final headers = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];
      }

      final response = await ApiService.getRequest(
        "/customers/currencies?page=1&items_per_page=15&category=crypto",
        extraHeaders: headers,
      );

      if (response["status"] == false) {
        debugPrint("Error: ${response["message"]}");
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("401 Unauthorized - Retrying...");
          return fetchCryptoCurrencies(retryCount: retryCount + 1);
        }
        return [];
      }

      var currencies = response["data"]["data"];
      return List<Map<String, dynamic>>.from(currencies);
    } catch (e) {
      debugPrint("❌ Crypto Currencies API Error: $e");
      return [];
    }
  }




  // Fetch available wallet types from the API
  static Future<List<Map<String, dynamic>>> fetchWalletTypes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];  // Return an empty list if no token is found
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'AppID': appId,  // Added AppID to headers
      };

      final response = await ApiService.getRequest(
        "/wallet-types?items_per_page=15",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Wallet Types API Response: $response");

      if (response["status"] == true) {
        var walletTypes = response["data"]["data"];
        debugPrint("Available wallet types: $walletTypes");

        return List<Map<String, dynamic>>.from(walletTypes);
      } else {
        debugPrint("Error: ${response["message"]}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Wallet Types API Error: $e");
      return [];
    }
  }

  // Fetch available banks from the API
  static Future<List<Map<String, dynamic>>> fetchBanks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token'); // Get the stored token

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        return [];  // Return an empty list if no token is found
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',  // Include the token in the Authorization header
      };

      // Make API request to the new endpoint /virtual-wallet-banks
      final response = await ApiService.getRequest(
        "/virtual-wallet-banks?items_per_page=15",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Virtual Wallet Banks API Response: $response");

      // Check if the response status is true
      if (response["status"] == true) {
        // Extract the banks data from the nested response
        var banks = response["data"]["data"];

        debugPrint("Available virtual wallet banks: $banks");

        // Return the banks as a list of maps
        return List<Map<String, dynamic>>.from(banks);
      } else {
        // Log and return an empty list if there's an error in the response
        debugPrint("Error: ${response["message"]}");
        return [];
      }
    } catch (e) {
      // Catch and log any errors during the API call
      debugPrint("❌ Virtual Wallet Banks API Error: $e");
      return [];
    }
  }


  static Future<dynamic> createWallet(Map<String, dynamic> body) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        throw Exception("Unauthorized: Please login again.");
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'AppID': appId,
      };

      debugPrint("📤 Submitting wallet creation with body: $body");

      final response = await ApiService.postRequest(
        "/customers/wallets",
        body,
        extraHeaders: headers,
      );

      debugPrint("✅ Wallet creation raw response: \n\n\n\n\n\n\n\n\n\n\n\n$response \n\n\n\n\n\n\n\n\n\n\n\n***********************************************************");

      if (response is Map<String, dynamic>) {
        final statusCode = response["statusCode"];
        final status = response["status"];
        final message = response["message"];

        // If server sent statusCode 500, force nice message
        if (statusCode == 500) {
          throw Exception("Oops, could not get an account for you right now. Try again later.");
        }

        // If API status field says "error", throw the provided message
        if (status == "error") {
          throw Exception(message ?? "An unknown error occurred.");
        }

        return response;
      } else {
        // If response is totally invalid
        throw Exception("Oops, could not get an account for you right now. Try again later.");
      }
    } catch (e) {
      debugPrint("❌ Error creating wallet: $e");

      String errorMessage = e.toString().replaceFirst("Exception: ", "");

      // If error is unexpected network/server-side, override with friendly message
      if (errorMessage.contains("SocketException") || errorMessage.contains("TimeoutException")) {
        errorMessage = "Oops, could not get an account for you right now. Try again later.";
      }

      throw Exception(errorMessage);
    }
  }





// static Future<dynamic> createWallet(Map<String, dynamic> body) async {
//   try {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('auth_token');
//     final String appId = prefs.getString('appId') ?? '';
//
//     if (token == null) {
//       debugPrint("❌ No auth token found.");
//       throw Exception("Unauthorized: Please login again.");
//     }
//
//     final headers = {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//       'AppID': appId,
//     };
//
//     debugPrint("📤 Submitting wallet creation with body: $body");
//
//     final response = await ApiService.postRequest(
//       "/customers/wallets",
//       body,
//       extraHeaders: headers,
//     );
//
//     debugPrint("✅ Wallet creation response: $response");
//
//     // Check if status is error and throw with custom message
//     if (response is Map<String, dynamic> && response["status"] == "error") {
//       throw Exception(response["message"] ?? "An unknown error occurred");
//     }
//
//     return response;
//   } catch (e) {
//     debugPrint("❌ Error creating wallet: $e");
//
//     // Pass back the error to the UI in a way that can be shown nicely
//     throw Exception(e.toString().replaceAll("Exception: ", ""));
//   }
// }




}
