import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CableTVController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _subscriptionPlans = [];
  List<Map<String, dynamic>> get subscriptionPlans => _subscriptionPlans;

  Map<String, dynamic>? _customerDetails;
  Map<String, dynamic>? get customerDetails => _customerDetails;

  double _balance = 0.0;
  double get balance => _balance;

  Future<void> fetchSubscriptionPlans(String cableTvType) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found.");
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/transactions/get-subscriptions?cableTvType=$cableTvType",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      debugPrint("🔹 Subscription Plans API Response: $response");

      if (response["status"] == true) {
        _subscriptionPlans = List<Map<String, dynamic>>.from(response["data"]);
      } else {
        debugPrint("⚠️ Error fetching subscription plans: ${response["message"]}");
        _subscriptionPlans = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching subscription plans: $e");
      _subscriptionPlans = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> verifySmartCard(String cableTvType, String smartCardNumber, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> body = {
        "cable_tv_type": cableTvType,
        "smart_card_number": smartCardNumber,
      };

      final response = await ApiService.postRequest(
        "/transactions/verify-smart-card",
        body,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      debugPrint("🔹 Smart Card Verification API Response: $response");

      if (response["status"] == true) {
        _customerDetails = response["data"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${response["message"]} - ${_customerDetails?["customer_name"]}")),
        );
      } else {
        _customerDetails = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${response["message"]}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      _customerDetails = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Verification failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isLoading = false;
    notifyListeners();
  }



  Future<Map<String, dynamic>> subscribeToCableTV({
    required String cableTvType,
    required String smartCardNumber,
    required String subscriptionPlan,
    required String phoneNumber,
    required String transactionPin,
    required BuildContext context, // <- add this back
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

      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "cable_tv_type": cableTvType,
        "smart_card_number": smartCardNumber,
        "subscription_plan": subscriptionPlan,
        "phone_number": phoneNumber,
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/transactions/subscribe-cable-tv",
        body,
        extraHeaders: headers,
      );

      final status = response["status"];
      final message = (response["message"] ?? "").toString().trim();

      if (status == true) {
        _balance = response["data"]["balance"].toDouble();
        return {
          'success': true,
          'message': '📺 Subscription successful! New Balance: $_balance',
        };
      } else {
        String friendlyMessage = "❌ Subscription failed.";
        if (message.toLowerCase().contains("invalid pin")) {
          friendlyMessage = "🔐 Your transaction PIN is incorrect.";
        } else if (message.toLowerCase().contains("insufficient")) {
          friendlyMessage = "💸 Your wallet doesn’t have enough funds.";
        } else if (message.toLowerCase().contains("unauthenticated")) {
          friendlyMessage = "🔒 Session expired. Please log in again.";
        } else if (message.isNotEmpty) {
          friendlyMessage = message;
        }

        return {
          'success': false,
          'message': friendlyMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '🌐 Network error occurred. Please try again.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
