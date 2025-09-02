import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class VirtualAccountService {
  static Future<Map<String, dynamic>> checkExistingRequests({
    String? currencyCode,
    int page = 1,
    int itemsPerPage = 20,
    int retryCount = 0,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        throw Exception("Authentication required");
      }

      // Build query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'items_per_page': itemsPerPage.toString(),
      };

      // Add currency code if provided
      if (currencyCode != null && currencyCode.isNotEmpty) {
        queryParams['currency_code'] = currencyCode;
      }

      // Build endpoint with query parameters
      String endpoint = "/cross-border-payment-mgt/virtual-account-requests?currency_code="+currencyCode!;


      final extraHeaders = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
        'Accept': 'application/json',
      };

      final response = await ApiService.getRequest(
        endpoint,
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Raw Virtual Account Requests API Response\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n: $response\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

      if (response['status'] == true) {
        debugPrint("✅ Virtual Account Requests fetched successfully");
        return response;
      } else {
        debugPrint("❌ API returned error: ${response['message']}");
        throw Exception(response['message'] ?? 'Failed to fetch virtual account requests');
      }

    } catch (e) {
      debugPrint("❌ Error fetching virtual account requests: $e");

      if (retryCount < 2) {
        debugPrint("🔄 Retrying... Attempt ${retryCount + 1}");
        await Future.delayed(Duration(seconds: 1));
        return checkExistingRequests(
          currencyCode: currencyCode,
          page: page,
          itemsPerPage: itemsPerPage,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  // Helper method to check if user has any requests for a specific currency
  static Future<bool> hasRequestForCurrency(String currencyCode) async {
    try {
      final response = await checkExistingRequests(currencyCode: currencyCode);

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];

        if (data is List && data.isNotEmpty) {
          // Check if any request is not rejected/cancelled
          for (var request in data) {
            final status = request['status']['slug'];
            if (status != 'rejected') {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint("Error checking currency request: $e");
      return false;
    }
  }

  // Helper method to get the latest request for a specific currency
  static Future<Map<String, dynamic>?> getLatestRequestForCurrency(String currencyCode) async {
    try {
      final response = await checkExistingRequests(currencyCode: currencyCode);
      final data = response['data'];

      if (data is List && data.isNotEmpty) {
        return data.first; // Return the first (latest) request
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error getting latest currency request: $e");
      return null;
    }
  }
}