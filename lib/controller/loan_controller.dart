import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class LoanController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _loanProducts = [];
  List<Map<String, dynamic>> get loanProducts => _loanProducts;

  bool _isVerifyingWallet = false;
  bool get isVerifyingWallet => _isVerifyingWallet;

  String _beneficiaryName = "";
  String get beneficiaryName => _beneficiaryName;

  Map<String, dynamic>? _loanBalanceData;
  Map<String, dynamic>? get loanBalanceData => _loanBalanceData;

  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> get banks => _banks;

  /// Replace _getAuthToken with _getHeaders
  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String appId = prefs.getString('appId') ?? '';
    
    return {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'AppID': appId,
    };
  }

  Future<void> verifyBankAccount({
    required String accountNumber,
    required String bankId,
  }) async {
    _isVerifyingWallet = true;
    _beneficiaryName = "";
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/verify/bank-account/$accountNumber/$bankId",
        extraHeaders: headers,
      );

      print("\n🏦 Bank Account Verification Response:");
      print("Status: ${response['status']}");
      print("Message: ${response['message']}");
      print("Full Response: $response");
      
      if (response["data"] != null) {
        print("\nAccount Details:");
        print("Account Name: ${response["data"]["account_name"]}");
        print("Account Number: ${response["data"]["account_number"]}");
        print("Bank Name: ${response["data"]["bank_name"]}");
      }
      print("\n"); // Add a blank line after the response

      if (response["status"] == true && response["data"] != null) {
        _beneficiaryName = response["data"]["account_name"] ?? "Unknown Account";
      } else {
        _beneficiaryName =
        "❌ Unable to verify the account. Please check the account number and try again.";
      }
    } catch (e) {
      print("❌ Error verifying bank account: $e");
      _beneficiaryName =
      "❌ We encountered an error while verifying the account. Please try again later.";
    } finally {
      _isVerifyingWallet = false;
      notifyListeners();
    }
  }

  /// Fetches eligible loan products and parses paginated structure
  Future<bool> getEligibleLoanProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No authentication token found.");
        return false;
      }

      const String endpoint = "/loan-mgt/eligible-loan-products";

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'AppID': appId, // <-- Added appID to header
      };

      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Loan Products API Response: $response");
      debugPrint("🔎 response['data'] type: ${response['data']?.runtimeType}");

      if (response["status"] == true &&
          response["data"] is List) {

        // Parse the list directly from response['data']
        final List<dynamic> productsList = response["data"];
        _loanProducts = productsList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        notifyListeners();
        return true;
      } else {
        debugPrint("⚠️ Failed to fetch eligible loan products or unexpected data format: ${response["message"]}");
        _loanProducts = [];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Loan Product Fetch Error: $e");
      _loanProducts = [];
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// 🔍 Helper to get product name from ID
  String? getProductNameById(String productId) {
    try {
      final product = _loanProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return product["product_name"];
    } catch (e) {
      debugPrint("❌ Error getting product name: $e");
      return null;
    }
  }

  Future<void> fetchLoanBalance() async {
    _isLoading = true;
    notifyListeners();

    final response = await getLoanBalanceInfo();

    if (response['success'] == true && response['data'] != null) {
      // Assuming 'data' is a list and you want the first element's info
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        _loanBalanceData = Map<String, dynamic>.from(data[0]);
      } else if (data is Map<String, dynamic>) {
        _loanBalanceData = data;
      } else {
        _loanBalanceData = null;
      }
    } else {
      _loanBalanceData = null;
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<Map<String, dynamic>> calculateLoanRepayment({
    required String loanProductId,
    required double loanAmount,
    required String repaymentStartDate,
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
          'message': '🔒 You have been logged out. Please log in again.'
        };
      }

      const String endpoint = "/loan-mgt/loan-products/repayment/calculator";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "loan_product_id": loanProductId,
        "loan_amount": loanAmount,
        "desired_loan_disbursement_date": repaymentStartDate,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      // Log the full response here:
      print('🔵 Loan repayment API response: $response');

      final status = response["status"];
      final message = (response["message"] ?? "").toString().trim();

      if (status == true && response["data"] != null) {
        return {
          'success': true,
          'message': '✅ Repayment calculation successful.',
          'data': response["data"],  // return raw data without key transformation
        };
      }
      else {
        String friendlyMessage = message.isNotEmpty ? message : "❌ Could not calculate repayment.";
        return {'success': false, 'message': friendlyMessage};
      }
    } catch (e) {
      print('⚠️ Exception caught in calculateLoanRepayment: $e');
      return {
        'success': false,
        'message': '🌐 Network error occurred. Please try again.'
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitLoanApplication({
    required String loanProductId,
    required double loanAmount,
    String? description,
    required bool isEarningMonthlySalary,
    required String repaymentStartDate,
    double? monthlySalaryAmount,
    double? otherIncomeAmount,
    String? monthlyExpenses,
    required String maritalStatus,
    required bool isHouseOwner,
    String? houseAddress,
    required bool hasDependents,
    int? noOfDependents,
    required bool isPlanningToRelocate,
    String? newRelocationAddress,
    required String preferredRepaymentMethod,
    String? repaymentWalletId,
    String? repaymentBankId,
    String? repaymentBankAccountName,
    String? repaymentBankAccountNumber,
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
          'message': '🔒 You have been logged out. Please log in again.'
        };
      }

      const String endpoint = "/loan-mgt/loans";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "AppID": appId,
      };

      final Map<String, dynamic> body = {
        "loan_product_id": loanProductId,
        "loan_amount": loanAmount,
        "desired_loan_disbursement_date": repaymentStartDate,
        if (description != null) "description": description,
        "is_earning_monthly_salary": isEarningMonthlySalary,
        if (isEarningMonthlySalary && monthlySalaryAmount != null)
          "monthly_salary_amount": monthlySalaryAmount,
        if (otherIncomeAmount != null) "other_income_amount": otherIncomeAmount,
        if (monthlyExpenses != null) "monthly_expenses": monthlyExpenses,
        "marital_status": maritalStatus,
        "is_house_owner": isHouseOwner,
        if (isHouseOwner && houseAddress != null) "house_address": houseAddress,
        "has_dependents": hasDependents,
        if (hasDependents && noOfDependents != null) "no_of_dependents": noOfDependents,
        "is_planning_to_relocate": isPlanningToRelocate,
        if (isPlanningToRelocate && newRelocationAddress != null)
          "new_relocation_address": newRelocationAddress,
        "preferred_repayment_method": preferredRepaymentMethod,
        if (preferredRepaymentMethod == "wallet" && repaymentWalletId != null)
          "repayment_wallet_id": repaymentWalletId,
        if ((preferredRepaymentMethod == "bank" || preferredRepaymentMethod == "direct-debit") && repaymentBankId != null)
          "repayment_bank_id": repaymentBankId,
        if (repaymentBankAccountName != null)
          "repayment_bank_account_name": repaymentBankAccountName,
        if ((preferredRepaymentMethod == "bank" || preferredRepaymentMethod == "direct-debit") && repaymentBankAccountNumber != null)
          "repayment_bank_account_number": repaymentBankAccountNumber,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      print('📤 Loan Application Submission Response: $response');

      final bool status = response["status"] ?? false;
      final String message = response["message"]?.toString() ?? "Something went wrong.";

      if (status && response["data"] != null) {
        return {
          'success': true,
          'message': "✅ Loan application submitted successfully.",
          'data': response["data"],
        };
      } else {
        return {
          'success': false,
          'message': "❌ Submission failed: $message",
        };
      }
    } catch (e) {
      print("⚠️ Loan submission error: $e");
      return {
        'success': false,
        'message': "🌐 Network error. Please try again.",
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>> getLoanBalanceInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return {
          'success': false,
          'message': '🔒 You have been logged out. Please log in again.',
        };
      }

      const String endpoint = "/loan-mgt/loans";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "AppID": appId,
      };

      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      print("💰 Loan Balance Info Response: $response");

      final bool status = response["status"] ?? false;
      final String message = response["message"]?.toString() ?? "Something went wrong.";

      if (status && response["data"] != null) {
        return {
          'success': true,
          'message': "✅ Loan balance retrieved successfully.",
          'data': response["data"],
        };
      } else {
        return {
          'success': false,
          'message': "❌ Failed to retrieve loan balance: $message",
        };
      }
    } catch (e) {
      print("⚠️ Loan balance fetch error: $e");
      return {
        'success': false,
        'message': "🌐 Network error. Please try again.",
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> fetchBanks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      const String endpoint = "/banks?support_direct_debit_mandates=true";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "AppID": appId, // <-- Added appID to header
      };

      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      // Debug prints for bank response
      print("\n🏦 Bank List Response:");
      print("Status: ${response['status']}");
      print("Message: ${response['message']}");
      print("Total Banks: ${response['data']?.length ?? 0}");
      print("\nBank List Data:");
      if (response['data'] != null && response['data'] is List) {
        (response['data'] as List).forEach((bank) {
          print("Bank ID: ${bank['id']} - Name: ${bank['name']}");
        });
      }
      print("\n"); // Add a blank line after the bank list

      if (response["status"] == true && response["data"] != null) {
        final List<dynamic> bankList = response["data"];
        _banks = bankList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        _banks = [];
        _transactionMessage = response["message"] ?? "Failed to fetch banks";
      }
    } catch (e) {
      print("❌ Error fetching banks: $e");
      _banks = [];
      _transactionMessage = "Failed to fetch banks. Please try again later.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSourceWallets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: headers,
      );

      print("🔹 Loan controller Raw Wallets API Response: $response");

      if (response["status"] == true && response["data"] is List) {
        // Data is directly under response["data"], not response["data"]["data"]
        final List wallets = response["data"];

        print("🔹 Total wallets found: ${wallets.length}");

        // Filter wallets with ownership_type == 'personal-wallet'
        final personalWallets = wallets.where((wallet) {
          final ownershipType = wallet["ownership_type"]?.toString() ?? "";
          print("🔹 Wallet ownership_type: $ownershipType");
          return ownershipType == "personal-wallet";
        }).toList();

        print("🔹 Personal wallets found: ${personalWallets.length}");

        _sourceWallets = personalWallets.map((wallet) {
          // Get wallet type name from wallet_type_id or use a default
          String walletTypeName = _getWalletTypeName(wallet["wallet_type_id"]);

          // Get currency symbol - check if currency data is nested
          String currencySymbol = "₦"; // default
          if (wallet["currency"] != null && wallet["currency"]["symbol"] != null) {
            currencySymbol = wallet["currency"]["symbol"];
          } else if (wallet["currency_symbol"] != null) {
            currencySymbol = wallet["currency_symbol"];
          }

          final walletData = {
            "id": wallet["id"]?.toString() ?? "",
            "account_number": wallet["wallet_number"]?.toString() ?? "",
            "available_balance": wallet["balance"]?.toString() ?? "0.00",
            "currency_symbol": currencySymbol,
            "wallet_type": walletTypeName,
            "ownership_label": wallet["ownership_label"]?.toString() ?? "",
          };

          print("🔹 Processed wallet: $walletData");
          return walletData;
        }).toList();

        print("🔹 Final sourceWallets count: ${_sourceWallets.length}");

        if (_sourceWallets.isEmpty) {
          _transactionMessage = "⚠️ No personal wallets found. Found ${wallets.length} total wallets.";
        }
      } else {
        print("❌ Invalid response structure: ${response.runtimeType}");
        print("❌ Response data type: ${response["data"].runtimeType}");
        _transactionMessage = "⚠️ Wallet list is missing or invalid.";
        _sourceWallets = [];
      }
    } catch (e, stackTrace) {
      print("❌ Error fetching wallets: $e");
      print("❌ Stack trace: $stackTrace");
      _transactionMessage = "❌ Error fetching wallets. Please try again.";
      _sourceWallets = [];
    }
    _isLoading = false;
    notifyListeners();
  }

// Helper method to get wallet type name
  String _getWalletTypeName(String? walletTypeId) {
    // You can implement a mapping based on your wallet types
    // For now, return a generic name or the ID itself
    if (walletTypeId == null || walletTypeId.isEmpty) {
      return "Wallet";
    }

    // You might want to maintain a map of wallet type IDs to names
    // Example:
    // final walletTypeMap = {
    //   "ee7119eb-a682-46e0-b3da-637d355c5831": "Primary Wallet",
    //   // Add more mappings as needed
    // };
    // return walletTypeMap[walletTypeId] ?? "Wallet";

    return "Wallet"; // Default for now
  }


}
