import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletToBankTransferController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  bool isLoadingWallets = true;
  bool isLoadingBanks = true;
  // Add this method
  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  bool _isVerifyingWallet = false;
  bool get isVerifyingWallet => _isVerifyingWallet;

  String _beneficiaryName = "";
  String get beneficiaryName => _beneficiaryName;

  List<Map<String, dynamic>> _savedBeneficiaries = [];
  List<Map<String, dynamic>> get savedBeneficiaries => _savedBeneficiaries;


  // Setter method to update beneficiary name
  void setBeneficiaryName(String name) {
    _beneficiaryName = name;
    notifyListeners(); // Notify listeners when the beneficiary name changes
  }

  // Method to clear the beneficiary name
  void clearBeneficiaryName() {
    _beneficiaryName = "";  // Clear the beneficiary name
    notifyListeners(); // Notify listeners to refresh UI
  }
  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> get banks => _banks;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  /// **Fetch authentication token**
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// **Fetches list of banks**
  /// **Fetches list of banks**
  Future<void> fetchBanks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/banks",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      // 🔍 Print full response to console
      print("🔍 Banks API Response: ${jsonEncode(response)}");

      if (response["status"] == true) {
        _banks = (response["data"] as List).map((bank) => {
          "id": bank["id"] ?? "Unknown",
          "bank_code": bank["code"],
          "bank_name": bank["name"]
        }).toList();

        // ✅ Save to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('saved_banks', jsonEncode(_banks));

      } else {
        _transactionMessage = "⚠️ We couldn't retrieve the list of banks. Please try again later.";
        _banks = [];
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while fetching banks. Please check your internet connection and try again.";
      _banks = [];
      print("❌ fetchBanks error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }



  /// **Fetches source wallets**
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



  /// **Verifies a bank account before processing transfer**
  Future<void> verifyBankAccount({
    required String accountNumber,
    required String bankId,
    }) async {
    _isVerifyingWallet = true;
    _beneficiaryName = "";
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _beneficiaryName = "❌ You are not logged in. Please log in to continue.";
        _isVerifyingWallet = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/verify/bank-account/$accountNumber/$bankId",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true && response["data"] != null) {
        _beneficiaryName = response["data"]["account_name"] ?? "Unknown Account";
      } else {
        _beneficiaryName = "❌ Unable to verify the account. Please check the account number and try again.";
      }
    } catch (e) {
      _beneficiaryName = "❌ We encountered an error while verifying the account. Please try again later.";
    }

    _isVerifyingWallet = false;
    notifyListeners();
  }

  /// **Initiate Wallet to Bank Transfer**
  Future<void> initializeBankTransfer({
    required String sourceWallet,
    required String bankCode,
    required String accountNumber,
    required double amount,
    required String narration,
    }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ Authentication failed. Please log in.";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.postRequest(
        "/customers/wallet-to-bank-transaction/initiate",
        {
          "source_wallet_number": sourceWallet,
          "bank_code": bankCode,
          "account_number": accountNumber,
          "amount": amount,
          "narration": narration.isNotEmpty ? narration : "Wallet to Bank Transfer",
        },
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Transfer initialized successfully!";
      } else {
        _transactionMessage = response["message"] ?? "❌ Transaction failed.";
      }
    } catch (e) {
      _transactionMessage = "❌ Error initializing transfer. Please try again.";
      debugPrint("❌ Error: $e");
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// **Complete the Transfer**
  /// **Fetch authentication token**

  /// **Complete the Wallet to Bank Transfer**
  Future<Map<String, dynamic>> completeBankTransfer({
    required String sourceWallet,
    required String destinationAccountNumber,
    required String bankId,
    required double amount,
    required String description,
    required String transactionPin,
    required bool saveBeneficiary,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isProcessing = false;
        notifyListeners();
        return {"success": false, "message": _transactionMessage};
      }

      final requestBody = {
        "source_wallet_number": sourceWallet,
        "destination_account_number": destinationAccountNumber,
        "bank_id": bankId,
        "amount": amount,
        "description": description.isNotEmpty ? description : "Wallet to Bank Transfer",
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-to-bank-transaction/process",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Your transfer was successful! Funds have been sent to the bank.";
        _isProcessing = false;
        notifyListeners();
        return {"success": true, "message": _transactionMessage};
      } else {
        _transactionMessage = response["message"] ?? "❌ Transfer failed. Please check your details and try again.";
        _isProcessing = false;
        notifyListeners();
        return {"success": false, "message": _transactionMessage};
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while processing the transfer. Please try again.";
      _isProcessing = false;
      notifyListeners();
      return {"success": false, "message": _transactionMessage};
    }
  }
  /// **Save a new bank account beneficiary**
  Future<Map<String, dynamic>> saveBeneficiary({
    required String beneficiaryName,
    required String accountNumber,
    required String bankId,
    required String transactionPin,
    String? nickname,
    String? currencyId, // Optional
  }) async {
    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        return {
          "success": false,
          "message": "❌ You are not logged in. Please log in to continue."
        };
      }

      final Map<String, dynamic> requestBody = {
        "beneficiary_type": "bank-account", // explicitly hardcoded
        "beneficiary_name": beneficiaryName,
        "beneficiary_identifier": accountNumber,
        "bank_id": bankId,
        "transaction_pin": transactionPin,
      };

      if (nickname != null && nickname.isNotEmpty) {
        requestBody["nickname"] = nickname;
      }

      if (currencyId != null && currencyId.isNotEmpty) {
        requestBody["currency_id"] = currencyId;
      }

      // Log payload
      debugPrint("📤 Saving beneficiary with payload: ${jsonEncode(requestBody)}");

      final response = await ApiService.postRequest(
        "/customers/beneficiaries/store/new",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      // Optional: log response for debugging
      debugPrint("📥 Response from save beneficiary: ${jsonEncode(response)}");

      if (response["status"] == true) {
        return {
          "success": true,
          "message": response["message"] ?? "✅ Beneficiary saved successfully."
        };
      } else {
        return {
          "success": false,
          "message": response["message"] ?? "❌ Failed to save beneficiary."
        };
      }
    } catch (e) {
      debugPrint("❌ Error saving beneficiary: $e");
      return {
        "success": false,
        "message": "❌ An error occurred while saving the beneficiary. Please try again."
      };
    }
  }

  /// **Fetches saved beneficiaries for the logged-in customer**
  Future<void> fetchSavedBeneficiaries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(
        "/customers/beneficiaries",
        extraHeaders: {'Authorization': 'Bearer $token'},
      );

      if (response["status"] == true && response["data"] != null) {
        final List data = response["data"];
        _savedBeneficiaries = data.map<Map<String, dynamic>>((beneficiary) {
          return {
            "id": beneficiary["id"],
            "beneficiary_name": beneficiary["beneficiary_name"] ?? "",
            "account_number": beneficiary["beneficiary_identifier"] ?? "",
            "bank_id": beneficiary["bank_id"] ?? "",
            "bank_name": beneficiary["bank_name"] ?? "",
            "nickname": beneficiary["nickname"] ?? "",
            "telephone": beneficiary["owner"]?["telephone"] ?? "",
          };
        }).toList();

        // ✅ Save to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('saved_beneficiaries', jsonEncode(_savedBeneficiaries));
      } else {
        _transactionMessage = "⚠️ Could not fetch saved beneficiaries.";
        _savedBeneficiaries = [];
      }
    } catch (e) {
      _transactionMessage = "❌ Error fetching beneficiaries. Please try again.";
      _savedBeneficiaries = [];
      debugPrint("❌ fetchSavedBeneficiaries error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }


}
