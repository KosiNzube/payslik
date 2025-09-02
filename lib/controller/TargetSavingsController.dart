import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';

class TargetSavingsController extends ChangeNotifier {
  // Product List State
  bool _isLoadingProducts = false;
  String _productsError = '';
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _productsPagination;

  // Product Details State
  bool _isLoadingProductDetails = false;
  String _productDetailsError = '';
  Map<String, dynamic>? _productDetails;

  // Schedule Calculator State
  bool _isCalculatingSchedule = false;
  String _scheduleError = '';
  Map<String, dynamic>? _scheduleResult;

  // Banks State
  bool _isLoadingBanks = false;
  String _banksError = '';
  List<Map<String, dynamic>> _banks = [];

  // Contracts State
  bool _isLoadingContracts = false;
  String _contractsError = '';
  List<Map<String, dynamic>> _contracts = [];
  Map<String, dynamic>? _contractsPagination;

  // Contract Details State
  bool _isLoadingContractDetails = false;
  String _contractDetailsError = '';
  Map<String, dynamic>? _contractDetails;

  // Application State
  bool _isApplying = false;
  String _applicationError = '';
  Map<String, dynamic>? _applicationResult;

  // Getters
  bool get isLoadingProducts => _isLoadingProducts;
  String get productsError => _productsError;
  List<Map<String, dynamic>> get products => _products;
  Map<String, dynamic>? get productsPagination => _productsPagination;

  bool get isLoadingProductDetails => _isLoadingProductDetails;
  String get productDetailsError => _productDetailsError;
  Map<String, dynamic>? get productDetails => _productDetails;

  bool get isCalculatingSchedule => _isCalculatingSchedule;
  String get scheduleError => _scheduleError;
  Map<String, dynamic>? get scheduleResult => _scheduleResult;

  bool get isLoadingBanks => _isLoadingBanks;
  String get banksError => _banksError;
  List<Map<String, dynamic>> get banks => _banks;

  bool get isLoadingContracts => _isLoadingContracts;
  String get contractsError => _contractsError;
  List<Map<String, dynamic>> get contracts => _contracts;
  Map<String, dynamic>? get contractsPagination => _contractsPagination;

  bool get isLoadingContractDetails => _isLoadingContractDetails;
  String get contractDetailsError => _contractDetailsError;
  Map<String, dynamic>? get contractDetails => _contractDetails;

  bool get isApplying => _isApplying;
  String get applicationError => _applicationError;
  Map<String, dynamic>? get applicationResult => _applicationResult;

  /// Fetch all target savings products with pagination
  Future<void> getProducts({int page = 1, int itemsPerPage = 20}) async {
    try {
      _isLoadingProducts = true;
      _productsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/target-saving-mgt/target-saving-products?page=$page&items_per_page=$itemsPerPage',
      );

      debugPrint('Target Savings Products Response: ${response['status']}');

      if (response['status'] == true) {
        _products = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
        _productsPagination = {
          'currentPage': response['data']['current_page'],
          'lastPage': response['data']['last_page'],
          'total': response['data']['total'],
          'perPage': response['data']['per_page'],
        };
        _productsError = '';
      } else {
        _productsError = response['message'] ?? 'Failed to fetch products';
        _products = [];
        _productsPagination = null;
      }
    } catch (e, stackTrace) {
      debugPrint('Target Savings Products Error: $e\n$stackTrace');
      _productsError = 'An error occurred while fetching products';
      _products = [];
      _productsPagination = null;
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Get target savings product details
  Future<bool> getProductDetails(String productId) async {
    try {
      _isLoadingProductDetails = true;
      _productDetailsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/target-saving-mgt/target-saving-products/$productId',
      );

      debugPrint('Product Details Response: ${response['status']}');

      if (response['status'] == true && response['data'] != null) {
        _productDetails = response['data'];
        _productDetailsError = '';
        return true;
      } else {
        _productDetailsError = response['message'] ?? 'Failed to fetch product details';
        _productDetails = null;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Product Details Error: $e\n$stackTrace');
      _productDetailsError = 'An error occurred while fetching product details';
      _productDetails = null;
      return false;
    } finally {
      _isLoadingProductDetails = false;
      notifyListeners();
    }
  }

  /// Calculate savings schedule
  Future<bool> calculateSchedule({
    required String savingsProductId,
    required double targetAmount,
    required String desiredLockPeriod,
  }) async {
    try {
      _isCalculatingSchedule = true;
      _scheduleError = '';
      _scheduleResult = null;
      notifyListeners();

      final response = await ApiService.postRequest(
        '/target-saving-mgt/target-saving-products/schedule/calculator',
        {
          'savings_product_id': savingsProductId,
          'target_amount': targetAmount,
          'desired_lock_period': desiredLockPeriod,
        },
      );

      debugPrint('Schedule Calculator Response: ${response['status']}');

      if (response['status'] == true && response['data'] != null) {
        _scheduleResult = response['data'];
        _scheduleError = '';
        return true;
      } else {
        _scheduleError = response['message'] ?? 'Failed to calculate schedule';
        _scheduleResult = null;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Schedule Calculator Error: $e\n$stackTrace');
      _scheduleError = 'An error occurred while calculating schedule';
      _scheduleResult = null;
      return false;
    } finally {
      _isCalculatingSchedule = false;
      notifyListeners();
    }
  }

  /// Get banks that support direct debit
  Future<bool> getBanks({int itemsPerPage = 15}) async {
    try {
      _isLoadingBanks = true;
      _banksError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/banks?items_per_page=$itemsPerPage&support_direct_debit_mandates=true',
      );

      debugPrint('Banks Response: ${response['status']}');

      if (response['status'] == true) {
        // Fix: Access the nested data array
        final responseData = response['data'];
        if (responseData != null && responseData['data'] != null) {
          _banks = List<Map<String, dynamic>>.from(responseData['data']);
        } else {
          _banks = [];
        }
        _banksError = '';
        return true;
      } else {
        _banksError = response['message'] ?? 'Failed to fetch banks';
        _banks = [];
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Banks Error: $e\n$stackTrace');
      _banksError = 'An error occurred while fetching banks';
      _banks = [];
      return false;
    } finally {
      _isLoadingBanks = false;
      notifyListeners();
    }
  }
  /// Apply for target savings
  Future<bool> applyForTargetSavings({
    required String savingsProductId,
    required double targetAmount,
    required String desiredLockPeriod,
    String? description,
    required String savingSourceChannel,
    String? walletId,
    String? bankId,
    String? bankAccountNumber,
    String? bankAccountName,
  }) async {
    try {
      _isApplying = true;
      _applicationError = '';
      _applicationResult = null;
      notifyListeners();

      final payload = {
        'savings_product_id': savingsProductId,
        'target_amount': targetAmount,
        'desired_lock_period': desiredLockPeriod,
        'saving_source_channel': savingSourceChannel,
        if (description != null) 'description': description,
        if (walletId != null) 'wallet_id': walletId,
        if (bankId != null) 'bank_id': bankId,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankAccountName != null) 'bank_account_name': bankAccountName,
      };

      final response = await ApiService.postRequest(
        '/target-saving-mgt/target-saving-contracts',
        payload,
      );

      debugPrint('Application Response: ${response['status']}');

      if (response['status'] == true && response['data'] != null) {
        _applicationResult = response['data'];
        _applicationError = '';
        return true;
      } else {
        _applicationError = response['message'] ?? 'Failed to submit application';
        _applicationResult = null;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Application Error: $e\n$stackTrace');
      _applicationError = 'An error occurred while submitting application';
      _applicationResult = null;
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Get target savings contracts with pagination
  Future<void> getContracts({int page = 1, int itemsPerPage = 20}) async {
    try {
      _isLoadingContracts = true;
      _contractsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/target-saving-mgt/target-saving-contracts?page=$page&items_per_page=$itemsPerPage',
      );

      debugPrint('Contracts Response: ${response['status']}');

      if (response['status'] == true) {
        _contracts = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
        _contractsPagination = {
          'currentPage': response['data']['current_page'],
          'lastPage': response['data']['last_page'],
          'total': response['data']['total'],
          'perPage': response['data']['per_page'],
        };
        _contractsError = '';
      } else {
        _contractsError = response['message'] ?? 'Failed to fetch contracts';
        _contracts = [];
        _contractsPagination = null;
      }
    } catch (e, stackTrace) {
      debugPrint('Contracts Error: $e\n$stackTrace');
      _contractsError = 'An error occurred while fetching contracts';
      _contracts = [];
      _contractsPagination = null;
    } finally {
      _isLoadingContracts = false;
      notifyListeners();
    }
  }

  /// Get target savings contract details
  Future<bool> getContractDetails(String contractId) async {
    try {
      _isLoadingContractDetails = true;
      _contractDetailsError = '';
      notifyListeners();

      final response = await ApiService.getRequest(
        '/target-saving-mgt/target-saving-contracts/$contractId',
      );

      debugPrint('Contract Details Response: ${response['status']}');

      if (response['status'] == true && response['data'] != null) {
        _contractDetails = response['data'];
        _contractDetailsError = '';
        return true;
      } else {
        _contractDetailsError = response['message'] ?? 'Failed to fetch contract details';
        _contractDetails = null;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Contract Details Error: $e\n$stackTrace');
      _contractDetailsError = 'An error occurred while fetching contract details';
      _contractDetails = null;
      return false;
    } finally {
      _isLoadingContractDetails = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clearData() {
    _isLoadingProducts = false;
    _productsError = '';
    _products = [];
    _productsPagination = null;

    _isLoadingProductDetails = false;
    _productDetailsError = '';
    _productDetails = null;

    _isCalculatingSchedule = false;
    _scheduleError = '';
    _scheduleResult = null;

    _isLoadingBanks = false;
    _banksError = '';
    _banks = [];

    _isLoadingContracts = false;
    _contractsError = '';
    _contracts = [];
    _contractsPagination = null;

    _isLoadingContractDetails = false;
    _contractDetailsError = '';
    _contractDetails = null;

    _isApplying = false;
    _applicationError = '';
    _applicationResult = null;

    notifyListeners();
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

  @override
  void dispose() {
    clearData();
    super.dispose();
  }
}