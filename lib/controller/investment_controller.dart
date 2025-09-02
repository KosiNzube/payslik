import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';

class InvestmentController extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _investmentProducts = [];
  Map<String, dynamic>? _selectedProduct;

  // Add new state variables
  bool _isLoadingDetails = false;
  String _detailsError = '';
  Map<String, dynamic>? _productDetails;

  // Add calculator state variables
  bool _isCalculating = false;
  String _calculationError = '';
  Map<String, dynamic>? _calculationResult;

  // Add new state variables for investment application
  bool _isApplying = false;
  String _applicationError = '';
  Map<String, dynamic>? _applicationResult;

  // Update state variables
  bool _isLoadingHistory = false;
  String _historyError = '';
  List<Map<String, dynamic>> _investmentHistory = [];
  Map<String, dynamic>? _historyPagination; // Add this line

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get investmentProducts => _investmentProducts;
  Map<String, dynamic>? get selectedProduct => _selectedProduct;

  // Add new getters
  bool get isLoadingDetails => _isLoadingDetails;
  String get detailsError => _detailsError;
  Map<String, dynamic>? get productDetails => _productDetails;

  // Add calculator getters
  bool get isCalculating => _isCalculating;
  String get calculationError => _calculationError;
  Map<String, dynamic>? get calculationResult => _calculationResult;

  // Add new getters for investment application
  bool get isApplying => _isApplying;
  String get applicationError => _applicationError;
  Map<String, dynamic>? get applicationResult => _applicationResult;

  // Add these getters after the existing ones
  bool get isLoadingHistory => _isLoadingHistory;
  String get historyError => _historyError;
  List<Map<String, dynamic>> get investmentHistory => _investmentHistory;
  Map<String, dynamic>? get historyPagination => _historyPagination;  // Add this line

  /// Fetch all investment products
  Future<void> getInvestmentProducts() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final response = await ApiService.getRequest('/investment-mgt/investment-products');

      // Debug logging
      debugPrint('\n🔹 Investment Products Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('└─ Products Count: ${(response['data'] as List?)?.length ?? 0}\n');

      if (response['status'] == true) {
        _investmentProducts = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _errorMessage = '';
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch investment products';
        _investmentProducts = [];
      }
    } catch (e, stackTrace) {
      debugPrint('\n❌ Investment Products Error:');
      debugPrint('├─ Error: $e');
      debugPrint('└─ Stack Trace: $stackTrace\n');

      _errorMessage = 'An error occurred while fetching investment products';
      _investmentProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh investment products
  Future<void> refreshProducts() async {
    await getInvestmentProducts();
  }

  /// Select a product
  void selectProduct(Map<String, dynamic> product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Get tenure type display text
  String getTenureTypeDisplay(String? type) {
    if (type == null) return 'Period';
    
    switch (type.toLowerCase()) {
      case 'daily':
        return 'Days';
      case 'weekly':
        return 'Weeks';
      case 'monthly':
        return 'Months';
      case 'yearly':
        return 'Years';
      default:
        return type.toUpperCase();
    }
  }

  /// Format currency for display
  String formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    try {
      return double.parse(amount.toString()).toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  /// Clear all data
  void clearData() {
    _isLoading = false;
    _errorMessage = '';
    _investmentProducts = [];
    _selectedProduct = null;
    // Add these lines to clear history data
    _isLoadingHistory = false;
    _historyError = '';
    _investmentHistory = [];
    _historyPagination = null; // Add this line
    notifyListeners();
  }

  /// Get investment product details
  Future<bool> getProductDetails(String productId) async {
    try {
      _isLoadingDetails = true;
      _detailsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/investment-mgt/investment-products/$productId',
      );

      // Debug logging
      debugPrint('\n🔹 Investment Product Details Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('└─ Product ID: $productId\n');

      if (response['status'] == true && response['data'] != null) {
        _productDetails = response['data'];
        _detailsError = '';
        notifyListeners();
        return true;
      } else {
        _detailsError = response['message'] ?? 'Failed to fetch product details';
        _productDetails = null;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('\n❌ Investment Product Details Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Product ID: $productId');
      debugPrint('└─ Stack Trace: $stackTrace\n');

      _detailsError = 'An error occurred while fetching product details';
      _productDetails = null;
      notifyListeners();
      return false;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  /// Calculate investment returns
  Future<bool> calculateInvestment({
    required String productId,
    required double investmentAmount,
    required String desiredMaturityTenure,
  }) async {
    try {
      _isCalculating = true;
      _calculationError = '';
      _calculationResult = null;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/investment-mgt/investment-products/interest/calculator',
        {
          'product_id': productId,
          'investment_amount': investmentAmount,
          'desired_maturity_tenure': desiredMaturityTenure,
        },
      );

      // Debug logging
      debugPrint('\n🔹 Investment Calculator Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Product ID: $productId');
      debugPrint('├─ Amount: $investmentAmount');
      debugPrint('└─ Tenure: $desiredMaturityTenure\n');

      if (response['status'] == true && response['data'] != null) {
        _calculationResult = response['data'];
        _calculationError = '';
        notifyListeners();
        return true;
      } else {
        _calculationError = response['message'] ?? 'Failed to calculate investment returns';
        _calculationResult = null;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('\n❌ Investment Calculator Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Product ID: $productId');
      debugPrint('├─ Amount: $investmentAmount');
      debugPrint('├─ Tenure: $desiredMaturityTenure');
      debugPrint('└─ Stack Trace: $stackTrace\n');

      _calculationError = 'An error occurred while calculating returns';
      _calculationResult = null;
      notifyListeners();
      return false;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// Apply for investment
  Future<bool> applyForInvestment({
    required String productId,
    required double investmentAmount,
    required String desiredMaturityTenure,
    required String preferredInterestPayoutDuration,
    required bool autoRolloverOnMaturity,
  }) async {
    try {
      _isApplying = true;
      _applicationError = '';
      _applicationResult = null;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/investment-mgt/investment-contracts',
        {
          'product_id': productId,
          'investment_amount': investmentAmount,
          'desired_maturity_tenure': desiredMaturityTenure,
          'preferred_interest_payout_duration': preferredInterestPayoutDuration,
          'auto_rollover_on_maturity': autoRolloverOnMaturity,
        },
      );

      // Debug logging
      debugPrint('\n🔹 Investment Application Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Product ID: $productId');
      debugPrint('├─ Amount: $investmentAmount');
      debugPrint('├─ Tenure: $desiredMaturityTenure');
      debugPrint('├─ Payout Duration: $preferredInterestPayoutDuration');
      debugPrint('└─ Auto Rollover: $autoRolloverOnMaturity\n');

      if (response['status'] == true && response['data'] != null) {
        _applicationResult = response['data'];
        _applicationError = '';
        notifyListeners();
        return true;
      } else {
        _applicationError = response['message'] ?? 'Failed to submit investment application';
        _applicationResult = null;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('\n❌ Investment Application Error:');
      debugPrint('├─ Error: $e');
      debugPrint('├─ Product ID: $productId');
      debugPrint('├─ Amount: $investmentAmount');
      debugPrint('├─ Tenure: $desiredMaturityTenure');
      debugPrint('└─ Stack Trace: $stackTrace\n');

      _applicationError = 'An error occurred while submitting investment application';
      _applicationResult = null;
      notifyListeners();
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Clear application data
  void clearApplication() {
    _isApplying = false;
    _applicationError = '';
    _applicationResult = null;
    notifyListeners();
  }

  /// Clear calculation data
  void clearCalculation() {
    _isCalculating = false;
    _calculationError = '';
    _calculationResult = null;
    notifyListeners();
  }

  // Add this new method before the dispose() method
  /// Fetch investment history with pagination
  Future<bool> getInvestmentHistory({int page = 1}) async {
    try {
      _isLoadingHistory = true;
      _historyError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/investment-mgt/investment-contracts?page=$page'
    );

      // Debug logging
      debugPrint('\n🔹 Investment History Response:');
      debugPrint('├─ Status: ${response['status']}');
      debugPrint('├─ Message: ${response['message']}');
      debugPrint('├─ Current Page: ${response['data']?['current_page']}');
      debugPrint('├─ Total Items: ${response['data']?['total']}');
      debugPrint('└─ Items on Page: ${(response['data']?['data'] as List?)?.length ?? 0}\n');

      if (response['status'] == true && response['data'] != null) {
        if (page == 1) {
          _investmentHistory = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
        } else {
          _investmentHistory.addAll(
            List<Map<String, dynamic>>.from(response['data']['data'] ?? [])
          );
        }

        // Store pagination info
        _historyPagination = {
          'currentPage': response['data']['current_page'],
          'lastPage': response['data']['last_page'],
          'total': response['data']['total'],
          'perPage': response['data']['per_page'],
          'hasMore': response['data']['next_page_url'] != null,
        };

        _historyError = '';
        notifyListeners();
        return true;
      } else {
        _historyError = response['message'] ?? 'Failed to fetch investment history';
        _investmentHistory = [];
        _historyPagination = null;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('\n❌ Investment History Error:');
      debugPrint('├─ Error: $e');
      debugPrint('└─ Stack Trace: $stackTrace\n');

      _historyError = 'An error occurred while fetching investment history';
      _investmentHistory = [];
      _historyPagination = null;
      notifyListeners();
      return false;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    clearApplication();
    clearCalculation();
    super.dispose();
  }

  // Helper method to get payout duration options
  List<Map<String, String>> getPayoutDurationOptions() {
    return [
      {'value': 'immediately', 'label': 'Immediately'},
      {'value': 'per_tenure', 'label': 'Per Tenure'},
      {'value': 'on_maturity', 'label': 'On Maturity'},
    ];
  }

  /// Format date from API
  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// Format money amount with currency symbol
  String formatAmount(dynamic amount, {String symbol = '₦'}) {
    if (amount == null) return '${symbol}0.00';
    try {
      final number = double.parse(amount.toString());
      final formatted = NumberFormat('#,##0.00').format(number);
      return '$symbol$formatted';
    } catch (e) {
      return '${symbol}0.00';
    }
  }
}