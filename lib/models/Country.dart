import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../utils/api_service.dart';

class Country {
  final String id;
  final String name;
  final String code;
  final String phoneCode;

  Country({
    required this.id,
    required this.name,
    required this.code,
    required this.phoneCode,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      phoneCode: json['phone_code'] ?? '',
    );
  }

  @override
  String toString() => '$name ($phoneCode)';
}




class CountryService {
  static Future<List<Country>> fetchCountries({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      final extraHeaders = {
        if (token != null) 'Authorization': 'Bearer $token',
        'AppID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await ApiService.getRequest(
        "/countries?items_per_page=10000",
        extraHeaders: extraHeaders,
      );

      debugPrint("🌍 Country API Raw Response: $response");

      if (response == null) {
        if (retryCount < 3) {
          debugPrint("🔁 Country retry due to null response (${retryCount + 1}/3)");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return fetchCountries(retryCount: retryCount + 1);
        }
        throw Exception("Country API returned null response after retries");
      }

      if (response["status"] == true || response["status"] == "success") {
        dynamic data = response["data"];

        // If data is a string, try decoding
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            debugPrint("❌ Invalid JSON in countries response: $e");
            throw Exception("Invalid country data format");
          }
        }

        if (data is List) {
          return data.map((json) => Country.fromJson(json)).toList();
        }

        if (data is Map && data.containsKey("data")) {
          final nested = data["data"];
          if (nested is List) {
            return nested.map((json) => Country.fromJson(json)).toList();
          }
        }

        throw Exception("Unexpected country data format");
      } else {
        final message = response["message"] ?? "Unknown error";
        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("🔁 Unauthorized. Retrying (${retryCount + 1}/3)");
          await Future.delayed(Duration(seconds: retryCount + 1));
          return fetchCountries(retryCount: retryCount + 1);
        }

        throw Exception("Country fetch failed: $message");
      }
    } catch (e) {
      debugPrint("❌ Country fetch exception: $e");

      if ((e.toString().contains('timeout') || e.toString().contains('connection')) && retryCount < 3) {
        debugPrint("🔁 Retry network exception (${retryCount + 1}/3)");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return fetchCountries(retryCount: retryCount + 1);
      }

      rethrow;
    }
  }
}
