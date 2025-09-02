import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/WalletController.dart';
import '../pages/success/DASHBOARD_Y.dart';

enum WalletMode { all, crypto, fiat }

class GeneralWalletProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = "";
  Map<String, dynamic>? _selectedWallet;
  int _currentWalletIndex = 0;
  bool _hasCachedWallets = false;
  WalletMode _currentMode = WalletMode.all;
  bool _hasCachedCryptoWallets = false;
  bool _hasCachedFiatWallets = false;

  // Getters
  List<Map<String, dynamic>> get wallets => List.unmodifiable(_wallets);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get selectedWallet => _selectedWallet;
  int get currentWalletIndex => _currentWalletIndex;
  bool get hasCachedWallets => _hasCachedWallets;
  WalletMode get currentMode => _currentMode;
  bool get hasCachedCryptoWallets => _hasCachedCryptoWallets;
  bool get hasCachedFiatWallets => _hasCachedFiatWallets;

  // Mode checks
  bool get isCryptoMode => _currentMode == WalletMode.crypto;
  bool get isFiatMode => _currentMode == WalletMode.fiat;
  bool get isAllWalletsMode => _currentMode == WalletMode.all;

  // Check if user has wallets
  bool get hasWallets => _wallets.isNotEmpty;

  // Get only crypto wallets from current wallet list
  List<Map<String, dynamic>> get cryptoWallets {
    return _wallets.where((wallet) =>
    wallet["currency_type"]?.toString().toLowerCase() == "crypto"
    ).toList();
  }

  // Get only fiat wallets from current wallet list
  List<Map<String, dynamic>> get fiatWallets {
    return _wallets.where((wallet) =>
    wallet["currency_type"]?.toString().toLowerCase() == "fiat"
    ).toList();
  }

  // Check if user has crypto wallets
  bool get hasCryptoWallets => cryptoWallets.isNotEmpty;

  // Check if user has fiat wallets
  bool get hasFiatWallets => fiatWallets.isNotEmpty;

  // Get crypto wallets count
  int get cryptoWalletsCount => cryptoWallets.length;

  // Get fiat wallets count
  int get fiatWalletsCount => fiatWallets.length;

  // Get current wallet balance
  String get currentBalance {
    if (_selectedWallet == null) return "0.00";
    final balance = _selectedWallet!["balance"] ?? 0.0;
    return balance.toStringAsFixed(2);
  }

  // Get current wallet currency
  String get currentCurrency {
    if (_selectedWallet == null) return "₦";
    return _selectedWallet!["currency"] ?? "₦";
  }

  String get currentCurrencyID {
    if (_selectedWallet == null) return "";
    return _selectedWallet!["currency_id"] ?? "";
  }

  // Get current wallet name
  String get currentWalletName {
    if (_selectedWallet == null) return "No Wallet";
    return _selectedWallet!["name"] ?? "Unnamed Wallet";
  }

  // Get current wallet number
  String get currentWalletNumber {
    if (_selectedWallet == null) return "---";
    return _selectedWallet!["wallet_number"] ?? "---";
  }

  // Get current bank name
  String get currentBankName {
    if (_selectedWallet == null) return "---";
    return _selectedWallet!["bank_name"] ?? "---";
  }

  // Get current currency code
  String get currentCurrencyCode {
    if (_selectedWallet == null) return "NGN";
    return _selectedWallet!["currency_code"] ?? "NGN";
  }

  // Get current currency name
  String get currentCurrencyName {
    if (_selectedWallet == null) return "Nigerian Naira";
    return _selectedWallet!["currency_name"] ?? "Nigerian Naira";
  }

  // Get current wallet type
  String get currentWalletType {
    if (_selectedWallet == null) return "Normal wallet";
    return _selectedWallet!["type"] ?? "Normal wallet";
  }

  // Get wallets by currency type
  List<Map<String, dynamic>> getWalletsByCurrency(String currencyCode) {
    return _wallets.where((wallet) =>
    wallet["currency_code"]?.toString().toUpperCase() == currencyCode.toUpperCase()
    ).toList();
  }

  // Get total balance for a specific currency
  double getTotalBalanceForCurrency(String currencyCode) {
    return getWalletsByCurrency(currencyCode)
        .fold(0.0, (sum, wallet) => sum + (wallet["balance"] ?? 0.0));
  }

  // Get total crypto balance (in primary crypto currency or USD equivalent)
  double get totalCryptoBalance {
    return cryptoWallets.fold(0.0, (sum, wallet) => sum + (wallet["balance"] ?? 0.0));
  }

  // Get total fiat balance (in primary fiat currency)
  double get totalFiatBalance {
    return fiatWallets.fold(0.0, (sum, wallet) => sum + (wallet["balance"] ?? 0.0));
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(bool hasError, [String message = ""]) {
    if (_hasError != hasError || _errorMessage != message) {
      _hasError = hasError;
      _errorMessage = message;
      notifyListeners();
    }
  }

  void _setWallets(List<Map<String, dynamic>> wallets, {bool fromCache = false}) {
    _wallets = List.from(wallets);

    if (fromCache) {
      switch (_currentMode) {
        case WalletMode.crypto:
          _hasCachedCryptoWallets = wallets.isNotEmpty;
          break;
        case WalletMode.fiat:
          _hasCachedFiatWallets = wallets.isNotEmpty;
          break;
        case WalletMode.all:
          _hasCachedWallets = wallets.isNotEmpty;
          break;
      }
    }

    // Maintain selected wallet if it still exists
    if (_selectedWallet != null) {
      final selectedWalletNumber = _selectedWallet!["wallet_number"];
      final newIndex = _wallets.indexWhere(
              (wallet) => wallet["wallet_number"] == selectedWalletNumber
      );

      if (newIndex != -1) {
        _selectedWallet = _wallets[newIndex];
        _currentWalletIndex = newIndex;
      } else if (wallets.isNotEmpty) {
        // If selected wallet no longer exists, select first one
        _selectedWallet = wallets.first;
        _currentWalletIndex = 0;
      } else {
        _selectedWallet = null;
        _currentWalletIndex = 0;
      }
    } else if (wallets.isNotEmpty) {
      _selectedWallet = wallets.first;
      _currentWalletIndex = 0;
    }

    notifyListeners();
  }

  // Load wallets from cache first, then from API
  Future<void> loadWallets({bool forceRefresh = false}) async {
    _setError(false);
    _currentMode = WalletMode.all; // Set to general mode

    try {
      if (!forceRefresh) {
        // First try to load from cache
        await _loadCachedWallets();
      }

      // Then load fresh data from API
      await _loadWalletsFromAPI();

    } catch (e) {
      debugPrint("❌ Error in loadWallets: $e");
      if (_wallets.isEmpty) {
        _setError(true, "Failed to load wallets. Please check your connection and try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load only crypto wallets
  Future<void> loadCryptoWallets({bool forceRefresh = false}) async {
   // _setLoading(true);
    _setError(false);
    _currentMode = WalletMode.crypto; // Set crypto mode flag

    try {
      if (!forceRefresh) {
        // First try to load from cache and filter crypto wallets
        await _loadCachedCryptoWallets();
      }

      // Then load fresh crypto data from API
      await _loadCryptoWalletsFromAPI();

    } catch (e) {
      debugPrint("❌ Error in loadCryptoWallets: $e");
      if (_wallets.isEmpty) {
        _setError(true, "Failed to load crypto wallets. Please check your connection and try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load only fiat wallets
  Future<void> loadFiatWallets({bool forceRefresh = false}) async {
  //  _setLoading(true);
    _setError(false);
    _currentMode = WalletMode.fiat; // Set fiat mode flag

    try {
      if (!forceRefresh) {
        // First try to load from cache and filter fiat wallets
        await _loadCachedFiatWallets();
      }

      // Then load fresh fiat data from API
      await _loadFiatWalletsFromAPI();

    } catch (e) {
      debugPrint("❌ Error in loadFiatWallets: $e");
      if (_wallets.isEmpty) {
        _setError(true, "Failed to load fiat wallets. Please check your connection and try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load cached wallets
  Future<void> _loadCachedWallets() async {
    try {
      final cachedData = await WalletDataCache.getCachedData();
      debugPrint("🟢 Raw cached data: $cachedData");

      if (cachedData != null && cachedData.isNotEmpty) {
        final processedWallets = _processWalletData(cachedData);
        _setWallets(processedWallets, fromCache: true);
        debugPrint("✅ Loaded ${processedWallets.length} cached wallets");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load cached wallets: $e");
    }
  }

  // Load cached wallets and filter for crypto
  Future<void> _loadCachedCryptoWallets() async {
    try {
      final cachedData = await WalletDataCache.getCachedData();
      debugPrint("🟢 Raw cached data for crypto: $cachedData");

      if (cachedData != null && cachedData.isNotEmpty) {
        final processedWallets = _processWalletData(cachedData);
        // Filter only crypto wallets from cache
        final cryptoWalletsOnly = processedWallets.where((wallet) =>
        wallet["currency_type"]?.toString().toLowerCase() == "crypto"
        ).toList();

        _setWallets(cryptoWalletsOnly, fromCache: true);
        debugPrint("✅ Loaded ${cryptoWalletsOnly.length} cached crypto wallets");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load cached crypto wallets: $e");
    }
  }

  // Load cached wallets and filter for fiat
  Future<void> _loadCachedFiatWallets() async {
    try {
      final cachedData = await WalletDataCache.getCachedData();
      debugPrint("🟢 Raw cached data for fiat: $cachedData");

      if (cachedData != null && cachedData.isNotEmpty) {
        final processedWallets = _processWalletData(cachedData);
        // Filter only fiat wallets from cache
        final fiatWalletsOnly = processedWallets.where((wallet) =>
        wallet["currency_type"]?.toString().toLowerCase() == "fiat"
        ).toList();

        _setWallets(fiatWalletsOnly, fromCache: true);
        debugPrint("✅ Loaded ${fiatWalletsOnly.length} cached fiat wallets");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load cached fiat wallets: $e");
    }
  }

  // Load wallets from API
  Future<void> _loadWalletsFromAPI() async {
    try {
      final walletData = await WalletController.fetchWalletsALL();
      debugPrint("🧾 Full wallet data: ${walletData.toString()}");

      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];
        debugPrint("✅ what i want\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+data.toString()+"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

        // Cache the data
        await WalletDataCache.cacheRawData(data);
        debugPrint("✅ Cached raw wallet data");

        if (data is List && data.isNotEmpty) {
          final processedWallets = _processWalletData(data);
          _setWallets(processedWallets);
          _setError(false); // Clear any previous errors
          debugPrint("✅ Successfully loaded ${processedWallets.length} wallets from API");
        } else {
          debugPrint("⚠️ Data is empty or not a list");
          if (!_hasCachedWallets) { // Only clear if we don't have cached data
            _setWallets([]);
          }
        }
      } else {
        debugPrint("⚠️ No wallet data received or data key missing");
        if (!_hasCachedWallets) { // Only clear if we don't have cached data
          _setWallets([]);
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading wallets from API: $e");
      // Don't clear existing wallets if API fails, keep cached data
      if (_wallets.isEmpty) {
        _setError(true, "Unable to load wallets. Please check your connection and try again.");
      }
      rethrow;
    }
  }

  // Load crypto wallets from API
  Future<void> _loadCryptoWalletsFromAPI() async {
    try {
      final walletData = await WalletController.fetchCryptoWallets();
      debugPrint("🧾 Full crypto wallet data: ${walletData.toString()}");

      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];

        debugPrint("✅ what i want\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+data.toString()+"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

        // Cache the crypto data in the same general cache
        await WalletDataCache.cacheRawData(data);
        debugPrint("✅ Cached crypto wallet data");

        if (data is List && data.isNotEmpty) {
          final processedWallets = _processWalletData(data);
          _setWallets(processedWallets);
          _setError(false); // Clear any previous errors
          debugPrint("✅ Successfully loaded ${processedWallets.length} crypto wallets from API");
        } else {
          debugPrint("⚠️ Crypto data is empty or not a list");
          if (!_hasCachedCryptoWallets) {
            _setWallets([]);
          }
        }
      } else {
        debugPrint("⚠️ No crypto wallet data received or data key missing");
        if (!_hasCachedCryptoWallets) {
          _setWallets([]);
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading crypto wallets from API: $e");
      if (_wallets.isEmpty) {
        _setError(true, "Unable to load crypto wallets. Please check your connection and try again.");
      }
      rethrow;
    }
  }

  // Load fiat wallets from API
  Future<void> _loadFiatWalletsFromAPI() async {
    try {
      final walletData = await WalletController.fetchWallets();
      debugPrint("🧾 Full fiat wallet data: ${walletData.toString()}");

      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];

        // Cache the fiat data in the same general cache
        await WalletDataCache.cacheRawData(data);
        debugPrint("✅ Cached fiat wallet data");

        if (data is List && data.isNotEmpty) {
          final processedWallets = _processWalletData(data);
          _setWallets(processedWallets);
          _setError(false); // Clear any previous errors
          debugPrint("✅ Successfully loaded ${processedWallets.length} fiat wallets from API");
        } else {
          debugPrint("⚠️ Fiat data is empty or not a list");
          if (!_hasCachedFiatWallets) {
            _setWallets([]);
          }
        }
      } else {
        debugPrint("⚠️ No fiat wallet data received or data key missing");
        if (!_hasCachedFiatWallets) {
          _setWallets([]);
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading fiat wallets from API: $e");
      if (_wallets.isEmpty) {
        _setError(true, "Unable to load fiat wallets. Please check your connection and try again.");
      }
      rethrow;
    }
  }

  // Process wallet data (same logic as your original methods)
  List<Map<String, dynamic>> _processWalletData(List<dynamic> data) {
    return data.map((wallet) {
      String network = "Unknown";
      String walletAddress = "N/A";
      String label = "Unnamed Wallet";
      String walletStatus = "Unknown";
      String createdAt = "";

      final metadata = wallet["provider_metadata"];
      try {
        final meta = metadata is String ? json.decode(metadata) : metadata;
        if (meta is Map<String, dynamic>) {
          network = meta["network"]?.toString() ?? "Unknown";
          walletAddress = meta["code"]?.toString() ?? "N/A";
          label = meta["label"]?.toString() ?? "Unnamed Wallet";
          if (label.isEmpty) {
            label = wallet["ownership_label"]?.toString()?.trim() ?? "Unnamed Wallet";
          }
          walletStatus = meta["status"]?.toString() ?? "Unknown";
          createdAt = meta["created_at"]?.toString() ?? "";
        }
      } catch (e) {
        debugPrint("⚠️ Failed to parse provider_metadata: $e");
      }

      return {
        "type": wallet["ownership_type"] ?? "Normal wallet",
        "currency_name": wallet["currency"] is Map && wallet["currency"]?["name"] != null
            ? wallet["currency"]["name"]
            : "Unknown Currency",
        "currency_type": wallet["currency"] is Map && wallet["currency"]?["type"] != null
            ? wallet["currency"]["type"]
            : "Unknown Type",
        "name": wallet["ownership_label"]?.toString() ?? "Wallet",
        "wallet_number": wallet["wallet_number"] ?? "N/A",
        "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
        "currency": wallet["currency"]?["symbol"] ?? "₦",
        "bank_name": wallet["bank"] is Map && wallet["bank"]?["name"] != null
            ? wallet["bank"]["name"]
            : "Unknown Bank",
        "bank_code": "N/A",
        "currency_code": wallet["currency"] is Map && wallet["currency"]?["code"] != null
            ? wallet["currency"]["code"]
            : "NGN",
        "currency_id": wallet["currency"] is Map && wallet["currency"]?["id"] != null
            ? wallet["currency"]["id"]
            : "",
        "currency_network": network,
        "label": label,
        "status": walletStatus,
        "created_at": createdAt,
        "wallet_address": walletAddress,
      };
    }).toList().reversed.toList();
  }

  // Switch between different wallet modes
  Future<void> switchToAllWallets() async {
    if (_currentMode != WalletMode.all) {
      await loadWallets(); // Load all wallets
    }
  }

  Future<void> switchToCryptoWallets() async {
    if (_currentMode != WalletMode.crypto) {
      await loadCryptoWallets(); // Load only crypto wallets
    }
  }

  Future<void> switchToFiatWallets() async {
    if (_currentMode != WalletMode.fiat) {
      await loadFiatWallets(); // Load only fiat wallets
    }
  }

  // Select a specific wallet
  void selectWallet(int index) {
    if (index >= 0 && index < _wallets.length && index != _currentWalletIndex) {
      _selectedWallet = _wallets[index];
      _currentWalletIndex = index;
      notifyListeners();
    }
  }

  // Select wallet by wallet object
  void selectWalletByData(Map<String, dynamic> wallet) {
    final index = _wallets.indexWhere((w) => w["wallet_number"] == wallet["wallet_number"]);
    if (index != -1) {
      selectWallet(index);
    }
  }

  // Select wallet by wallet number
  void selectWalletByNumber(String walletNumber) {
    final index = _wallets.indexWhere((wallet) => wallet["wallet_number"] == walletNumber);
    if (index != -1) {
      selectWallet(index);
    }
  }

  // Refresh wallets (force reload from API based on current mode)
  Future<void> refreshWallets() async {
    switch (_currentMode) {
      case WalletMode.all:
        await loadWallets(forceRefresh: true);
        break;
      case WalletMode.crypto:
        await loadCryptoWallets(forceRefresh: true);
        break;
      case WalletMode.fiat:
        await loadFiatWallets(forceRefresh: true);
        break;
    }
  }

  // Specific refresh methods
  Future<void> refreshCryptoWallets() async {
    await loadCryptoWallets(forceRefresh: true);
  }

  Future<void> refreshFiatWallets() async {
    await loadFiatWallets(forceRefresh: true);
  }

  Future<void> refreshAllWallets() async {
    await loadWallets(forceRefresh: true);
  }

  // Clear all data (useful for logout)
  void clearWallets() {
    _wallets = [];
    _selectedWallet = null;
    _currentWalletIndex = 0;
    _hasError = false;
    _errorMessage = "";
    _isLoading = false;
    _hasCachedWallets = false;
    _currentMode = WalletMode.all; // Reset to all mode
    _hasCachedCryptoWallets = false; // Reset crypto cache flag
    _hasCachedFiatWallets = false; // Reset fiat cache flag
    notifyListeners();
  }

  // Add a new wallet to the list (useful after creating a wallet)
  void addWallet(Map<String, dynamic> wallet) {
    _wallets.add(wallet);
    if (_selectedWallet == null) {
      _selectedWallet = wallet;
      _currentWalletIndex = _wallets.length - 1;
    }
    notifyListeners();
  }

  // Update a wallet's balance (useful after transactions)
  bool updateWalletBalance(String walletNumber, double newBalance) {
    final index = _wallets.indexWhere((wallet) => wallet["wallet_number"] == walletNumber);
    if (index != -1) {
      _wallets[index]["balance"] = newBalance;
      if (_selectedWallet?["wallet_number"] == walletNumber) {
        _selectedWallet = Map.from(_selectedWallet!);
        _selectedWallet!["balance"] = newBalance;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // Remove a wallet from the list
  bool removeWallet(String walletNumber) {
    final index = _wallets.indexWhere((wallet) => wallet["wallet_number"] == walletNumber);
    if (index != -1) {
      _wallets.removeAt(index);

      // If removed wallet was selected, select a new one
      if (_selectedWallet?["wallet_number"] == walletNumber) {
        if (_wallets.isNotEmpty) {
          if (index < _wallets.length) {
            _selectedWallet = _wallets[index];
            _currentWalletIndex = index;
          } else {
            _selectedWallet = _wallets.last;
            _currentWalletIndex = _wallets.length - 1;
          }
        } else {
          _selectedWallet = null;
          _currentWalletIndex = 0;
        }
      } else if (_currentWalletIndex > index) {
        // Adjust current index if it's affected by removal
        _currentWalletIndex--;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  // Update wallet status
  bool updateWalletStatus(String walletNumber, String newStatus) {
    final index = _wallets.indexWhere((wallet) => wallet["wallet_number"] == walletNumber);
    if (index != -1) {
      _wallets[index]["status"] = newStatus;
      if (_selectedWallet?["wallet_number"] == walletNumber) {
        _selectedWallet = Map.from(_selectedWallet!);
        _selectedWallet!["status"] = newStatus;
      }
      notifyListeners();
      return true;
    }
    return false;
  }
}