import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ElectricityController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  String? _meterOwnerName;
  String? get meterOwnerName => _meterOwnerName;

  List<Map<String, String>> _electricityDiscos = [];
  List<Map<String, String>> _meterTypes = [];

  List<Map<String, String>> get electricityDiscos => _electricityDiscos;
  List<Map<String, String>> get meterTypes => _meterTypes;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String appId = prefs.getString('appId') ?? '';

    return {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'AppID': appId,
    };
  }

  /// Fetch Meter Services (Discos & Meter Types)
  Future<void> fetchMeterServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/transactions/get-meter-services",
        extraHeaders: headers,
      );

      debugPrint("🔹 Meter Services API Response: $response");

      if (response["status"] == true) {
        _electricityDiscos = List<Map<String, String>>.from(
          response["data"]["electricity_discos"].map((disco) => {
            "id": disco["id"].toString(),
            "name": disco["name"].toString(),
          }),
        );

        _meterTypes = List<Map<String, String>>.from(
          response["data"]["meter_types"].map((type) => {
            "id": type["id"].toString(),
            "name": type["name"].toString(),
          }),
        );

        debugPrint("✅ Electricity Discos: $_electricityDiscos");
        debugPrint("✅ Meter Types: $_meterTypes");
      } else {
        debugPrint("⚠️ Error fetching meter services: ${response["message"]}");
      }
    } catch (e) {
      debugPrint("❌ Meter Services API Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verify Meter Number
  Future<void> verifyMeterNumber({
    required String electricityDisco,
    required String meterType,
    required String meterNumber,
    required BuildContext context,
  }) async {
    _isVerifying = true;
    _meterOwnerName = null;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final String endpoint = "/transactions/verify-meter-number";
      final Map<String, String> headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "electricity_disco": electricityDisco,
        "meter_type": meterType,
        "meter_number": meterNumber,
      };

      debugPrint("📤 Sending Meter Verification Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 Meter Verification API Response: $response");

      if (response["status"] == true) {
        _meterOwnerName = response["data"]["meter_name"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Meter Verified: $_meterOwnerName")),
        );
      } else {
        _meterOwnerName = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: ${response["message"]}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Verification failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isVerifying = false;
    notifyListeners();
  }

  /// Purchase Electricity
  // Future<Map<String, dynamic>> purchaseElectricity({
  //   required String meterNumber,
  //   required String electricityDisco,
  //   required String meterType,
  //   required String amount,
  //   required String phoneNumber,
  //   required String pin,
  //   }) async {
  //   _isPurchasing = true;
  //   notifyListeners();
  //
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final String? token = prefs.getString('auth_token');
  //     final String appId = prefs.getString('appId') ?? '';
  //
  //     if (token == null) {
  //       return {'success': false, 'message': '🔒 You’ve been logged out. Please log in again.'};
  //     }
  //
  //     final String endpoint = "/transactions/buy-electricity";
  //     final Map<String, String> headers = {
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "application/json",
  //       "AppID": appId,
  //     };
  //
  //     final Map<String, dynamic> body = {
  //       "meter_number": meterNumber,
  //       "electricity_disco": electricityDisco,
  //       "meter_type": meterType,
  //       "final_amount": double.tryParse(amount) ?? 0,
  //       "phone_number": phoneNumber,
  //       "transaction_pin": pin,
  //     };
  //
  //     final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
  //     final status = response["status"];
  //     final message = (response["message"] ?? "").toString().trim();
  //
  //     if (status == true) {
  //       return {'success': true, 'message': '⚡️ Electricity purchased successfully!'};
  //     } else {
  //       String friendlyMessage = "❌ Something went wrong.";
  //       if (message.toLowerCase().contains("invalid pin")) {
  //         friendlyMessage = "🔐 Your transaction PIN is incorrect.";
  //       } else if (message.toLowerCase().contains("insufficient")) {
  //         friendlyMessage = "💸 Your wallet doesn’t have enough funds.";
  //       } else if (message.toLowerCase().contains("unauthenticated")) {
  //         friendlyMessage = "🔒 Session expired. Please log in again.";
  //       } else if (message.isNotEmpty) {
  //         friendlyMessage = message;
  //       }
  //
  //       return {'success': false, 'message': friendlyMessage};
  //     }
  //   } catch (e) {
  //     return {'success': false, 'message': '🌐 Network error occurred. Please try again.'};
  //   } finally {
  //     _isPurchasing = false;
  //     notifyListeners();
  //   }
  // }

  Future<Map<String, dynamic>> purchaseElectricity({
    required String meterNumber,
    required String electricityDisco,
    required String meterType,
    required String amount,
    required String phoneNumber,
    required String pin,
  }) async {
    _isPurchasing = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return {'success': false, 'message': '🔒 You’ve been logged out. Please log in again.'};
      }

      final String endpoint = "/transactions/buy-electricity";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "meter_number": meterNumber,
        "electricity_disco": electricityDisco,
        "meter_type": meterType,
        "final_amount": double.tryParse(amount) ?? 0,
        "phone_number": phoneNumber,
        "transaction_pin": pin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      final status = response["status"];
      final message = (response["message"] ?? "").toString().trim();

      if (status == true) {
        return {'success': true, 'message': '⚡️ Electricity purchased successfully!'};
      } else {
        // Directly use backend message if available
        String friendlyMessage = message.isNotEmpty ? message : "❌ Something went wrong.";
        return {'success': false, 'message': friendlyMessage};
      }
    } catch (e) {
      return {'success': false, 'message': '🌐 Network error occurred. Please try again.'};
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }
}
