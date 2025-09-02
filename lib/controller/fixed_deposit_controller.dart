import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';
import '../models/interest_payout_duration.dart';

class FixedDepositController extends ChangeNotifier {
  List<Map<String, dynamic>> _fixedDepositProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> get fixedDepositProducts => _fixedDepositProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Map<String, dynamic>? _selectedProduct;
  bool _isLoadingDetails = false;
  String _detailsError = '';

  Map<String, dynamic>? get selectedProduct => _selectedProduct;
  bool get isLoadingDetails => _isLoadingDetails;
  String get detailsError => _detailsError;

  Map<String, dynamic>? _calculatorResult;
  bool _isCalculating = false;
  String _calculatorError = '';

  Map<String, dynamic>? get calculatorResult => _calculatorResult;
  bool get isCalculating => _isCalculating;
  String get calculatorError => _calculatorError;

  // Add new state variables for contract creation
  bool _isCreatingContract = false;
  String _contractError = '';
  Map<String, dynamic>? _createdContract;

  // Add getters
  bool get isCreatingContract => _isCreatingContract;
  String get contractError => _contractError;
  Map<String, dynamic>? get createdContract => _createdContract;

  // Add state variables for contracts
  List<Map<String, dynamic>> _fixedDepositContracts = [];
  bool _isLoadingContracts = false;
  String _contractsError = '';

  // Add getters
  List<Map<String, dynamic>> get fixedDepositContracts => _fixedDepositContracts;
  bool get isLoadingContracts => _isLoadingContracts;
  String get contractsError => _contractsError;

  /// Get authentication headers
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

  /// Fetches all available fixed deposit products
  Future<void> getFixedDepositProducts() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response = await ApiService.getRequest('/fixed-deposit-mgt/fixed-deposit-products');
      debugPrint("🔎 response['data'] type: ${response['data'].runtimeType}");
      debugPrint("🔎 response['status']: ${response['status']}");

      if (response['status'] == true) {
        // Convert List<dynamic> to List<Map<String, dynamic>>
        final productsList = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((item) => Map<String, dynamic>.from(item))
        );
        
        _fixedDepositProducts = productsList;
        _errorMessage = '';
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch products';
        _fixedDepositProducts = [];
      }
    } catch (e) {
      debugPrint("❌ Fixed Deposit Products Fetch Error: $e");
      _errorMessage = 'An error occurred while fetching products';
      _fixedDepositProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper method to get product details by ID
  Map<String, dynamic>? getProductById(String productId) {
    try {
      return _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint("❌ Error getting product by ID: $e");
      return null;
    }
  }

  /// Helper method to get product name by ID (updated field name)
  String? getProductNameById(String productId) {
    try {
      final product = _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return product["name"]; // Changed from "product_name" to "name"
    } catch (e) {
      debugPrint("❌ Error getting product name: $e");
      return null;
    }
  }

  /// Helper method to get interest rate by product ID
  double? getInterestRateById(String productId) {
    try {
      final product = _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return double.tryParse(product["interest_rate"]?.toString() ?? "0");
    } catch (e) {
      debugPrint("❌ Error getting interest rate: $e");
      return null;
    }
  }

  /// Filter products by minimum amount (updated field name)
  List<Map<String, dynamic>> getProductsByMinAmount(double amount) {
    return _fixedDepositProducts.where((product) {
      final minAmount = double.tryParse(product["min_amount"]?.toString() ?? "0") ?? 0.0;
      return minAmount <= amount;
    }).toList();
  }

  /// Filter products by term (duration) - updated to handle new tenure structure
  List<Map<String, dynamic>> getProductsByTerm(int termInDays) {
    return _fixedDepositProducts.where((product) {
      final tenureType = product["tenure_type"]?.toString() ?? "daily";
      final minPeriod = product["tenure_min_period"]?.toInt() ?? 0;
      final maxPeriod = product["tenure_max_period"]?.toInt();

      // Convert term to days based on tenure type
      int minTermInDays = minPeriod;
      int? maxTermInDays = maxPeriod;

      switch (tenureType.toLowerCase()) {
        case "monthly":
          minTermInDays = minPeriod * 30;
          maxTermInDays = maxPeriod != null ? maxPeriod * 30 : null;
          break;
        case "yearly":
          minTermInDays = minPeriod * 365;
          maxTermInDays = maxPeriod != null ? maxPeriod * 365 : null;
          break;
        case "daily":
        default:
        // Already in days
          break;
      }

      return termInDays >= minTermInDays &&
          (maxTermInDays == null || termInDays <= maxTermInDays);
    }).toList();
  }

  /// Get the highest interest rate product
  Map<String, dynamic>? getHighestRateProduct() {
    if (_fixedDepositProducts.isEmpty) return null;

    return _fixedDepositProducts.reduce((a, b) {
      final rateA = double.tryParse(a["interest_rate"]?.toString() ?? "0") ?? 0.0;
      final rateB = double.tryParse(b["interest_rate"]?.toString() ?? "0") ?? 0.0;
      return rateA > rateB ? a : b;
    });
  }

  /// Get product code by ID
  String? getProductCodeById(String productId) {
    try {
      final product = _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return product["code"];
    } catch (e) {
      debugPrint("❌ Error getting product code: $e");
      return null;
    }
  }

  /// Check if product allows premature withdrawal
  bool? allowsPrematureWithdrawal(String productId) {
    try {
      final product = _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return product["allow_premature_withdrawal"];
    } catch (e) {
      debugPrint("❌ Error checking premature withdrawal: $e");
      return null;
    }
  }

  /// Get product status
  String? getProductStatus(String productId) {
    try {
      final product = _fixedDepositProducts.firstWhere(
            (product) => product["id"] == productId,
        orElse: () => {},
      );
      return product["status"]?["label"];
    } catch (e) {
      debugPrint("❌ Error getting product status: $e");
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = "";
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _fixedDepositProducts = [];
    _errorMessage = "";
    notifyListeners();
  }

  /// Refresh fixed deposit products
  Future<void> refreshProducts() async {
    await getFixedDepositProducts();
  }

  Future<bool> getProductDetails(String productId) async {
    try {
      _isLoadingDetails = true;
      _detailsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/fixed-deposit-mgt/fixed-deposit-products/$productId'
      );

      if (response['status'] == true) {
        _selectedProduct = response['data'];
        _detailsError = '';
        notifyListeners();
        return true;
      } else {
        _detailsError = response['message'] ?? 'Failed to fetch product details';
        _selectedProduct = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Fixed Deposit Product Details Error: $e");
      _detailsError = 'An error occurred while fetching product details';
      _selectedProduct = null;
      notifyListeners();
      return false;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  // Add helper method to generate tenure options
  // List<int> getTenureOptions(Map<String, dynamic> product) {
  //   final minPeriod = product['tenure_min_period'] ?? 0;
  //   final maxPeriod = product['tenure_max_period'];
  //   final List<int> options = [];
  //
  //   if (minPeriod is int) {
  //     int start = minPeriod;
  //     // If maxPeriod is null, generate reasonable options based on tenure type
  //     int end;
  //     switch (product['tenure_type']?.toString().toLowerCase()) {
  //       case 'daily':
  //         end = maxPeriod ?? (start + 365); // Up to 1 year
  //         break;
  //       case 'monthly':
  //         end = maxPeriod ?? (start + 60); // Up to 5 years
  //         break;
  //       case 'yearly':
  //         end = maxPeriod ?? (start + 10); // Up to 10 years
  //         break;
  //       default:
  //         end = maxPeriod ?? (start + 12); // Default to 1 year worth of periods
  //     }
  //
  //     // Generate options
  //     for (int i = start; i <= end; i++) {
  //       options.add(i);
  //
  //       // Add larger steps for longer periods to avoid too many options
  //       if (product['tenure_type'] == 'daily' && i >= 30) {
  //         i += 14; // Add bi-weekly steps after 30 days
  //       } else if (product['tenure_type'] == 'monthly' && i >= 12) {
  //         i += 2; // Add quarterly steps after 1 year
  //       }
  //     }
  //   }
  //
  //   return options;
  // }

  /// Modified calculate interest method
  Future<bool> calculateInterest({
    required String productId,
    required double depositAmount,
    required int desiredTenure,
    }) async {
    try {
      _isCalculating = true;
      _calculatorError = '';
      notifyListeners();

      // Get the product details first if not already loaded
      if (_selectedProduct == null || _selectedProduct!['id'] != productId) {
        await getProductDetails(productId);
      }

      if (_selectedProduct == null) {
        throw Exception('Product details not available');
      }

      final body = {
        "deposit_amount": depositAmount,
        "product_id": productId,
        "desired_maturity_tenure": desiredTenure.toString(),
      };

      debugPrint("🔹 Calculator Request Body: $body");

      final response = await ApiService.postRequest(
        '/fixed-deposit-mgt/fixed-deposit-products/interest/calculator',
        body,
      );

      debugPrint("🔹 Calculator API Response: $response");

      if (response['status'] == true) {
        _calculatorResult = response['data'];
        _calculatorError = '';
        notifyListeners();
        return true;
      } else {
        _calculatorError = response['message'] ?? 'Failed to calculate interest';
        _calculatorResult = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Interest Calculator Error: $e");
      _calculatorError = 'An error occurred while calculating interest';
      _calculatorResult = null;
      notifyListeners();
      return false;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  // Helper method to get tenure type display text
  // Add these methods to your FixedDepositController class

  /// Generate tenure options based on min and max periods
  List<int> getTenureOptions(Map<String, dynamic> product) {
    final minPeriod = product['tenure_min_period'] as int? ?? 1;
    final maxPeriod = product['tenure_max_period'] as int? ?? 12;
    final tenureType = product['tenure_type'] as String? ?? 'months';

    // Validate that max is greater than or equal to min
    if (maxPeriod < minPeriod) {
      return [minPeriod]; // Return only min if max is invalid
    }

    List<int> options = [];

    // Generate options based on tenure type
    if (tenureType.toLowerCase() == 'days') {
      // For days, use appropriate intervals based on the range
      int step = _getDayStep(minPeriod, maxPeriod);

      for (int i = minPeriod; i <= maxPeriod; i += step) {
        options.add(i);
      }

      // Always include the max period if it's not already included
      if (options.last != maxPeriod) {
        options.add(maxPeriod);
      }
    } else if (tenureType.toLowerCase() == 'weeks') {
      // For weeks, increment by 1 week
      for (int i = minPeriod; i <= maxPeriod; i++) {
        options.add(i);
      }
    } else {
      // For months or years, increment by 1
      for (int i = minPeriod; i <= maxPeriod; i++) {
        options.add(i);
      }
    }

    return options;
  }

  /// Helper method to determine appropriate step for days
  int _getDayStep(int minPeriod, int maxPeriod) {
    int range = maxPeriod - minPeriod;

    if (range <= 30) {
      return 1; // Daily intervals for periods up to 30 days
    } else if (range <= 90) {
      return 7; // Weekly intervals for periods up to 90 days
    } else if (range <= 365) {
      return 30; // Monthly intervals for periods up to 1 year
    } else {
      return 90; // Quarterly intervals for longer periods
    }
  }

  /// Get display text for tenure type
  String getTenureTypeDisplay(String? tenureType) {
    if (tenureType == null) return 'Months';

    switch (tenureType.toLowerCase()) {
      case 'days':
      case 'day':
        return 'Days';
      case 'weeks':
      case 'week':
        return 'Weeks';
      case 'months':
      case 'month':
        return 'Months';
      case 'years':
      case 'year':
        return 'Years';
      default:
        return 'Months';
    }
  }

  /// Alternative simple method that returns all values between min and max
  List<int> getTenureOptionsSimple(Map<String, dynamic> product) {
    final minPeriod = product['tenure_min_period'] as int? ?? 1;
    final maxPeriod = product['tenure_max_period'] as int? ?? 12;

    // Validate range
    if (maxPeriod < minPeriod) {
      return [minPeriod];
    }

    return List.generate(
        maxPeriod - minPeriod + 1,
            (index) => minPeriod + index
    );
  }

  /// Validate if a tenure value is within the allowed range
  bool isValidTenure(Map<String, dynamic> product, int tenure) {
    final minPeriod = product['tenure_min_period'] as int? ?? 1;
    final maxPeriod = product['tenure_max_period'] as int? ?? 12;

    return tenure >= minPeriod && tenure <= maxPeriod;
  }

  void clearCalculatorResult() {
    _calculatorResult = null;
    _calculatorError = '';
    _isCalculating = false;
    notifyListeners();
  }

  // Add method to create fixed deposit contract
  Future<bool> createFixedDepositContract({
    required String productId,
    required double depositAmount,
    required int desiredTenure,
    required InterestPayoutDuration preferredPayout,
    required bool autoRollover,
  }) async {
    try {
      _isCreatingContract = true;
      _contractError = '';
      _createdContract = null;
      notifyListeners();

      final body = {
        "product_id": productId,
        "deposit_amount": depositAmount,
        "desired_maturity_tenure": desiredTenure.toString(),
        "preferred_interest_payout_duration": preferredPayout.name,
        "auto_rollover_on_maturity": autoRollover,
      };

      debugPrint("🔹 Creating Fixed Deposit Contract: $body");

      final response = await ApiService.postRequest(
        '/fixed-deposit-mgt/fixed-deposit-contracts',
        body,
      );

      debugPrint("🔹 Contract Creation Response: $response");

      if (response['status'] == true) {
        _createdContract = response['data'];
        _contractError = '';
        notifyListeners();
        return true;
      } else {
        _contractError = response['message'] ?? 'Failed to create fixed deposit contract';
        _createdContract = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Contract Creation Error: $e");
      _contractError = 'An error occurred while creating the contract';
      _createdContract = null;
      notifyListeners();
      return false;
    } finally {
      _isCreatingContract = false;
      notifyListeners();
    }
  }

  // Add helper method to get payout duration display text
  String getPayoutDurationDisplay(InterestPayoutDuration duration) {
    return duration.displayName;
  }

  // Add method to clear contract data
  void clearContractData() {
    _createdContract = null;
    _contractError = '';
    _isCreatingContract = false;
    notifyListeners();
  }

  // Add method to fetch contracts
  Future<void> getFixedDepositContracts() async {
    try {
      _isLoadingContracts = true;
      _contractsError = '';
      notifyListeners();

      final response = await ApiService.getRequest('/fixed-deposit-mgt/fixed-deposit-contracts');

      if (response['status'] == true) {
        _fixedDepositContracts = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _contractsError = '';
      } else {
        _contractsError = response['message'] ?? 'Failed to fetch contracts';
        _fixedDepositContracts = [];
      }
    } catch (e) {
      debugPrint("❌ Contracts Fetch Error: $e");
      _contractsError = 'An error occurred while fetching contracts';
      _fixedDepositContracts = [];
    } finally {
      _isLoadingContracts = false;
      notifyListeners();
    }
  }

  // Clear contracts data
  void clearContractsData() {
    _fixedDepositContracts = [];
    _isLoadingContracts = false;
    _contractsError = '';
    notifyListeners();
  }
}