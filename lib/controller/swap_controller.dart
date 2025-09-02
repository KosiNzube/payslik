import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwapController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isVerifyingWallet = false;
  bool get isVerifyingWallet => _isVerifyingWallet;

  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  String _beneficiaryName = "";
  String get beneficiaryName => _beneficiaryName;

  double _amountProcessable = 0.0;
  double get amountProcessable => _amountProcessable;

  double _expectedBalanceAfter = 0.0;
  double get expectedBalanceAfter => _expectedBalanceAfter;

  String _transactionCurrency = "NGN";
  String get transactionCurrency => _transactionCurrency;

  String _transactionCurrencySymbol = "₦";
  String get transactionCurrencySymbol => _transactionCurrencySymbol;

  String _actualBalanceBefore = "0.00";
  String get actualBalanceBefore => _actualBalanceBefore;

  String _platformChargeFee = "0.00";
  String get platformChargeFee => _platformChargeFee;

  String _totalAmountProcessable = "0.00";
  String get totalAmountProcessable => _totalAmountProcessable;

  String _transactionReference = "";
  String get transactionReference => _transactionReference;

  String _transactionStatus = "";
  String get transactionStatus => _transactionStatus;

  void clearBeneficiaryName() {
    _beneficiaryName = "";
    notifyListeners();
  }

  /// **Reset controller state** to initial values
  void resetState() {
    _isLoading = false;
    _isProcessing = false;
    _isVerifyingWallet = false;
    _sourceWallets = [];
    _isInitialized = false;
    _transactionMessage = "";
    _beneficiaryName = "";
    _amountProcessable = 0.0;
    _expectedBalanceAfter = 0.0;
    _transactionCurrency = "NGN";
    _transactionCurrencySymbol = "₦";
    _actualBalanceBefore = "0.00";
    _platformChargeFee = "0.00";
    _totalAmountProcessable = "0.00";
    _transactionReference = "";
    _transactionStatus = "";

    notifyListeners();
  }

  /// **Fetch authentication token**
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// **Fetches source wallets from API**
  Future<void> fetchSourceWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ Authentication required.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      print("🔹 Raw Wallets API Response: $response");

      // ✅ The "data" field is a List, not a Map
      if (response["status"] == true && response["data"] is List) {
        final List wallets = response["data"];

        _sourceWallets = wallets.map((wallet) {
          return {
            "account_number": wallet["wallet_number"]?.toString() ?? "",
            "id":wallet["id"]?.toString() ?? "",

            "available_balance": wallet["balance"]?.toString() ?? "0.00",
            "currency_symbol": wallet["currency"]?["symbol"] ?? "₦",
            "wallet_type": wallet["wallet_type_id"] ?? "Unknown Wallet Type",
            "ownership_label": wallet["ownership_label"] ?? "",
          };
        }).toList();
      } else {
        _transactionMessage = "⚠️ Wallet list is missing or invalid.";
        _sourceWallets = [];
      }
    } catch (e) {
      print("❌ Error fetching wallets: $e");
      _transactionMessage = "❌ Error fetching wallets. Please try again.";
      _sourceWallets = [];
    }

    _isLoading = false;
    notifyListeners();
  }






}
