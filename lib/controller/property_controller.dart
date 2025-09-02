import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class PropertyController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> get properties => _filteredProperties;
  Map<String, Map<String, dynamic>> _propertyDetailsCache = {};

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  bool _isSubscriptionLoading = false;
  bool get isSubscriptionLoading => _isSubscriptionLoading;

  // Filtered list shown in UI, initially same as _properties
  List<Map<String, dynamic>> _filteredProperties = [];

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  // Cache for category details
  final Map<String, Map<String, dynamic>> _categoryCache = {};

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

  /// Fetches paginated property list from API
  Future<void> fetchProperties({int page = 1}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/properties?page=$page";
      
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      debugPrint("🏘️ Properties API Full Response: $response");

      if (response['status'] == true) {
        final responseData = response['data'];

        if (responseData is List) {
          // Direct list of properties — use it directly
          if (page == 1) {
            _properties = responseData.cast<Map<String, dynamic>>();
          } else {
            _properties.addAll(responseData.cast<Map<String, dynamic>>());
          }
          _currentPage = 1;
          _totalPages = 1;
        } else if (responseData is Map<String, dynamic>) {
          // Paginated response with nested 'data'
          final dynamic propertyList = responseData['data'];

          if (propertyList is List) {
            if (page == 1) {
              _properties = propertyList.cast<Map<String, dynamic>>();
            } else {
              _properties.addAll(propertyList.cast<Map<String, dynamic>>());
            }

            _currentPage = responseData['current_page'] ?? 1;
            _totalPages = responseData['last_page'] ?? 1;
          } else {
            _properties = [];
            _currentPage = 1;
            _totalPages = 1;
          }
        } else {
          debugPrint("⚠️ Unexpected response format: $responseData");
          _properties = [];
          _currentPage = 1;
          _totalPages = 1;
        }
      } else {
        debugPrint("❌ API responded with status=false: ${response['message']}");
        _properties = [];
        _currentPage = 1;
        _totalPages = 1;
      }
    } catch (e) {
      debugPrint("❌ Error fetching properties: $e");
      _properties = [];
      _currentPage = 1;
      _totalPages = 1;
    } finally {
      // Apply filtering after fetch:
      _applyCategoryFilter();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches property categories with optimized caching
  Future<void> fetchPropertyCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categories.isNotEmpty) {
      return;
    }

    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/property-categories";
      
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      print('fetchPropertyCategories');
      print(headers);
      print(response);
      debugPrint("📂 Property Categories API Response Status: ${response['status']}");

      if (response['status'] == true && response['data'] != null) {
        final responseData = response['data'];
        
        // Handle direct list response
        if (responseData is List) {
          // Convert and filter visible categories only
          _categories = responseData
              .where((category) => category is Map<String, dynamic> && category['is_visible'] == true)
              .map((category) => category as Map<String, dynamic>)
              .toList()
            ..sort((a, b) => (a['label'] ?? '').compareTo(b['label'] ?? ''));

          // Update category cache
          for (var category in _categories) {
            if (category['id'] != null) {
              _categoryCache[category['id'].toString()] = category;
            }
          }

          debugPrint("📂 Successfully loaded ${_categories.length} categories");
          debugPrint("📂 Categories: ${_categories.map((c) => c['label']).toList()}");
        } else {
          debugPrint("⚠️ Response data is not a List: ${responseData.runtimeType}");
          _categories = [];
        }
      } else {
        debugPrint("❌ Categories API error: ${response['message']}");
        _categories = [];
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching categories: $e");
      debugPrint("Stack trace: $stackTrace");
      _categories = [];
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Get category details by ID (with caching)
  Map<String, dynamic>? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    return _categoryCache[categoryId];
  }

  /// Filter properties by category with optimized performance
  void filterPropertiesByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyCategoryFilter();
    notifyListeners();
  }

  /// Apply category filter with improved performance
  void _applyCategoryFilter() {
    if (_selectedCategoryId == null) {
      _filteredProperties = List.from(_properties);
    } else {
      _filteredProperties = _properties.where((property) {
        final propertyCategory = property['property_category_id']?.toString();
        return propertyCategory == _selectedCategoryId;
      }).toList();
    }
  }

  /// Clear category filter
  void clearCategoryFilter() {
    _selectedCategoryId = null;
    _filteredProperties = List.from(_properties);
    notifyListeners();
  }

  /// Check if a category is currently selected
  bool isCategorySelected(String? categoryId) {
    return _selectedCategoryId == categoryId;
  }

  Future<Map<String, dynamic>?> fetchPropertyDetails(String propertyId) async {
    if (_propertyDetailsCache.containsKey(propertyId)) {
      return _propertyDetailsCache[propertyId];
    }

    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/properties/$propertyId";
      
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      debugPrint("🏡 Property Details Response: $response");

      if (response['status'] == true && response['data'] is Map<String, dynamic>) {
        final propertyData = response['data'] as Map<String, dynamic>;
        _propertyDetailsCache[propertyId] = propertyData;
        return propertyData;
      } else {
        debugPrint("❌ Property details fetch failed: ${response['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching property details: $e");
      return null;
    }
  }

  /// Initiate property subscription
  Future<Map<String, dynamic>> initiateSubscriptionRequest({
    required String propertyId,
    required int quantity,
    required String desiredPaymentStartDate,
    required int desiredPaymentDurationInterval,
    required String preferredPaymentOption,
    String? bankId,
    String? bankAccountNumber,
    String? bankAccountName,
    String? walletId,
  }) async {
    _isSubscriptionLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/property-subscriptions/initiate/request";
      
      final Map<String, dynamic> body = {
        "property_id": propertyId,
        "quantity": quantity,
        "desired_payment_start_date": desiredPaymentStartDate,
        "desired_payment_duration_interval": desiredPaymentDurationInterval,
        "preferred_payment_option": preferredPaymentOption,
        if (preferredPaymentOption == "bank" || preferredPaymentOption == "direct-debit") ...{
          "bank_id": bankId,
          "bank_account_number": bankAccountNumber,
          if (bankAccountName != null) "bank_account_name": bankAccountName,
        },
        if (preferredPaymentOption == "wallet") "wallet_id": walletId,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🟡 Initiate Subscription Response: $response");

      return response;
    } catch (e) {
      debugPrint("❌ Error initiating subscription: $e");
      return {
        "status": false,
        "message": "Failed to initiate subscription: $e"
      };
    } finally {
      _isSubscriptionLoading = false;
      notifyListeners();
    }
  }

  /// Finalize the subscription process
  Future<Map<String, dynamic>> processSubscriptionRequest({
    required String propertyId,
    required int quantity,
    required String desiredPaymentStartDate,
    required int desiredPaymentDurationInterval,
    required String preferredPaymentOption,
    String? bankId,
    String? bankAccountNumber,
    String? bankAccountName,
    String? walletId,
    String? bankName,
    String? walletName,
  }) async {
    _isSubscriptionLoading = true;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/property-subscriptions/process/request";
      
      final Map<String, dynamic> body = {
        "property_id": propertyId,
        "quantity": quantity,
        "desired_payment_start_date": desiredPaymentStartDate,
        "desired_payment_duration_interval": desiredPaymentDurationInterval,
        "preferred_payment_option": preferredPaymentOption,
        if (preferredPaymentOption == "bank" || preferredPaymentOption == "direct-debit") ...{
          "bank_id": bankId,
          "bank_account_number": bankAccountNumber,
          if (bankAccountName != null) "bank_account_name": bankAccountName,
          if (bankName != null) "bank_name": bankName,
        },
        if (preferredPaymentOption == "wallet") ...{
          "wallet_id": walletId,
          if (walletName != null) "wallet_name": walletName,
        },
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🟢 Process Subscription Response: $response");

      return response;
    } catch (e) {
      debugPrint("❌ Error processing subscription: $e");
      return {
        "status": false,
        "message": "Failed to process subscription: $e"
      };
    } finally {
      _isSubscriptionLoading = false;
      notifyListeners();
    }
  }

  /// Fetch subscription history for a specific property
  Future<Map<String, dynamic>?> fetchPropertySubscriptionHistory(String subscriptionId) async {
    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/property-subscriptions/$subscriptionId";
      
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      
      debugPrint("\n📜 Property Subscription Details:");
      debugPrint("Status: ${response['status']}");
      debugPrint("Message: ${response['message']}");

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        // Print main subscription details
        debugPrint("\nSubscription Info:");
        debugPrint("ID: ${data['id']}");
        debugPrint("Property: ${data['name_referenced']}");
        debugPrint("Quantity: ${data['quantity']} ${data['uom']}");
        debugPrint("Status: ${data['status']?['label'] ?? 'Unknown'}");
        
        // Print financial details
        final currency = data['currency']?['symbol'] ?? '₦';
        debugPrint("\nFinancial Details:");
        debugPrint("Expected Amount: $currency${data['expected_amount']}");
        debugPrint("Paid Amount: $currency${data['paid_amount']}");
        debugPrint("Balance: $currency${data['balance_amount']}");
        debugPrint("Interest Rate: ${data['interest_referenced']}%");
        
        // Print payment details
        debugPrint("\nPayment Schedule:");
        debugPrint("Payment Method: ${data['preferred_payment_option']}");
        debugPrint("Payment Cycle: ${data['payment_cycle_referenced']}");
        debugPrint("Start Date: ${data['start_date']}");
        debugPrint("First Payment: ${data['first_payment_date']}");
        debugPrint("Next Payment: ${data['next_payment_date']}");
        debugPrint("End Date: ${data['actual_end_date']}");
        debugPrint("Extended End Date: ${data['extended_end_date']}");
        
        // Print property details if available
        if (data['property'] != null) {
          debugPrint("\nProperty Details:");
          debugPrint("Property Name: ${data['property']['name']}");
          debugPrint("Category: ${data['property']?['property_category']?['label'] ?? 'Unknown'}");
          debugPrint("Description: ${data['property']['description']}");
        }
        
        return data;
      }
      
      // If we reach here, there was an error in the response
      debugPrint("\n❌ Error: ${response['message']}");
      return null;
    } catch (e) {
      debugPrint("\n❌ Error fetching subscription history: $e");
      return null;
    }
  }

  /// 🔍 Get property name by ID
  String? getPropertyNameById(String id) {
    try {
      final property = _properties.firstWhere(
            (element) => element["id"] == id,
        orElse: () => <String, dynamic>{},
      );
      return property["name"] ?? "Unknown";
    } catch (e) {
      debugPrint("❌ Error getting property name: $e");
      return null;
    }
  }

  /// Check if next page is available
  bool get hasNextPage => _currentPage < _totalPages;

  /// Load next page (if exists)
  Future<bool> loadNextPage() async {
    if (!hasNextPage) return false;
    await fetchProperties(page: _currentPage + 1);
    return true;
  }

  /// Fetch all property subscriptions
  Future<List<Map<String, dynamic>>> fetchAllPropertySubscriptions() async {
    try {
      final headers = await _getHeaders();
      final endpoint = "/properties-mgt/property-subscriptions";
      
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      
      debugPrint("\n📜 All Property Subscriptions:");
      debugPrint("Status: ${response['status']}");
      debugPrint("Message: ${response['message']}");

      if (response['status'] == true && response['data'] != null) {
        final List<Map<String, dynamic>> subscriptions = [];
        
        if (response['data'] is List) {
          subscriptions.addAll(List<Map<String, dynamic>>.from(response['data']));
        } else if (response['data'] is Map && response['data']['data'] is List) {
          // Handle paginated response
          subscriptions.addAll(List<Map<String, dynamic>>.from(response['data']['data']));
        }

        debugPrint("Found ${subscriptions.length} subscriptions");
        return subscriptions;
      }
      
      return [];
    } catch (e) {
      debugPrint("\n❌ Error fetching property subscriptions: $e");
      return [];
    }
  }
}
