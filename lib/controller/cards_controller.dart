import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/api_service.dart';

class VirtualCardController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _virtualCards = [];
  List<Map<String, dynamic>> get virtualCards => _virtualCards;

  List<Map<String, dynamic>> _sourceWallets = [];
  List<Map<String, dynamic>> get sourceWallets => _sourceWallets;

  String _transactionMessage = "";
  String get transactionMessage => _transactionMessage;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Store card details by card ID with last fetch timestamp
  final Map<String, Map<String, dynamic>> _cardDetails = {};
  Map<String, Map<String, dynamic>> get cardDetails => _cardDetails;

  // Cache duration for card details (5 minutes)
  static const cardDetailsCacheDuration = Duration(minutes: 5);

  Map<String, dynamic>? getCardById(String cardId) {
    final cardInfo = _cardDetails[cardId];
    if (cardInfo == null) return null;

    // Check if cache is expired
    final lastFetched = DateTime.parse(cardInfo['_lastFetched'] ?? '2000-01-01');
    if (DateTime.now().difference(lastFetched) > cardDetailsCacheDuration) {
      // Cache expired, fetch fresh data
      fetchCardBalanceDetails(cardId);
      return null;
    }

    return cardInfo;
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchVirtualCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        _virtualCards = [];
        return;
      }

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const endpoint = "/card-mgt/cards/virtual/list?page=1&items_per_page=20";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      print('fetchVirtualCards/ card_controller/');
      print(response);
      debugPrint("🔹fetchVirtualCards/ card_controller/ Virtual Cards API Response: $response");

      if (response["status"] == true &&
          response["data"] != null &&
          response["data"]["data"] != null) {
        _virtualCards = List<Map<String, dynamic>>.from(response["data"]["data"]);

        // Fetch balance for the first card automatically
        if (_virtualCards.isNotEmpty) {
          fetchCardBalanceDetails(_virtualCards.first['id']);
        }
      } else {
        debugPrint("⚠️ Failed to fetch virtual cards: ${response["message"]}");
        _virtualCards = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching virtual cards: $e");
      _virtualCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCardBalanceDetails(String cardId) async {
    if (cardId.isEmpty) {
      throw Exception("Card ID cannot be empty");
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        throw Exception("No auth token found");
      }

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      final endpoint = "/card-mgt/cards/virtual/$cardId/balance";
      Map<String, dynamic> response;

      try {
        response = await ApiService.getRequest(endpoint, extraHeaders: headers);
      } catch (e) {
        if (e.toString().contains('403') || e.toString().contains('401')) {
          debugPrint("🔄 Authentication error, attempting to refresh token...");
          
          // Try to refresh the token
          final bool tokenRefreshed = await _refreshToken();
          
          if (tokenRefreshed) {
            // Get the new token
            final String? newToken = prefs.getString('auth_token');
            if (newToken == null) throw Exception("Token refresh failed");
            
            // Update headers with new token
            headers["Authorization"] = "Bearer $newToken";
            
            // Retry the request with new token
            await Future.delayed(const Duration(milliseconds: 500));
            response = await ApiService.getRequest(endpoint, extraHeaders: headers);
          } else {
            throw Exception("Token refresh failed");
          }
        } else {
          rethrow;
        }
      }

      debugPrint("💳 Card Balance Response for $cardId: $response");

      if (response["status"] == true && response["data"] != null) {
        final data = response["data"];
        double rawBalance = double.tryParse(data["balance"].toString()) ?? 0.0;
        double actualBalance = rawBalance / 100;

        _cardDetails[cardId] = {
          "id": data["id"],
          "name": data["name"],
          "card_number": data["card_number"],
          "masked_pan": data["masked_pan"],
          "expiry": data["expiry"],
          "cvv": data["cvv"],
          "status": data["status"],
          "type": data["type"],
          "issuer": data["issuer"],
          "currency": data["currency"],
          "balance": actualBalance.toStringAsFixed(2),
          "balance_updated_at": data["balance_updated_at"],
          "auto_approve": data["auto_approve"],
          "address": data["address"],
          "created_at": data["created_at"],
          "updated_at": data["updated_at"],
          "is_amount_locked": data["is_amount_locked"],
          "_lastFetched": DateTime.now().toIso8601String(),
        };

        notifyListeners();
      } else {
        final errorMsg = response["message"] ?? "Failed to fetch card details";
        debugPrint("⚠️ Card balance fetch failed: $errorMsg");
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Error fetching card details: $e");
      throw Exception("Failed to fetch card details: $e");
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? refreshToken = prefs.getString('refresh_token');
      final String appId = prefs.getString('appId') ?? '';

      if (refreshToken == null) {
        return false;
      }

      final headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $refreshToken",
        "AppID": appId,
      };

      const endpoint = "/auth/refresh-token";
      final response = await ApiService.postRequest(endpoint, {}, extraHeaders: headers);

      if (response["status"] == true && response["data"]?["token"] != null) {
        // Save the new token
        await prefs.setString('auth_token', response["data"]["token"]);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error refreshing token: $e");
      return false;
    }
  }

  Future<String> createVirtualCard({required String cardPin, required BuildContext context}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/card-mgt/cards/virtual/create";
      final Map<String, dynamic> body = {
        "transaction_pin": cardPin,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🆕 Create Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh list after creation
        return "Virtual card created successfully.";
      } else {
        // Always prefer backend's message
        final errorMessage = response["message"] ?? "Failed to create card.";
        return errorMessage;
      }
    } catch (e) {
      debugPrint("❌ Error creating virtual card: $e");
      return "An error occurred while creating the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch wallets associated with the user
  Future<void> fetchWallets() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token found.");
        return;
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
      };

      const String endpoint = "/customers/wallets";
      final response = await ApiService.getRequest(endpoint, extraHeaders: headers);

      debugPrint("🔹 Wallets API Response: $response");

      if (response["status"] == true && response["data"] != null && response["data"]["data"] != null) {
        _sourceWallets = List<Map<String, dynamic>>.from(response["data"]["data"]);
        debugPrint("✅ Wallets fetched successfully.");
      } else {
        debugPrint("⚠️ Failed to fetch wallets: ${response["message"]}");
        _sourceWallets = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching wallets: $e");
      _sourceWallets = [];
    } finally {
      notifyListeners();
    }
  }

  /// Toggles virtual card lock status (block/unblock)
  Future<String> toggleCardLockStatus(String cardId, bool isCurrentlyLocked) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      // Check if the card is currently locked or not based on the response
      bool isCardBlocked = false;

      // Fetch the list of virtual cards and check the status of the selected card
      for (var card in _virtualCards) {
        if (card['id'] == cardId) {
          isCardBlocked = card['is_amount_locked'] ?? false; // Check if the card is locked
          break;
        }
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      final String endpoint = isCardBlocked
          ? "/card-mgt/cards/$cardId/unblock"  // If it's blocked, unblock it
          : "/card-mgt/cards/$cardId/block";   // If it's not blocked, block it

      final response = await ApiService.patchRequest(endpoint, {}, extraHeaders: headers);

      debugPrint("🔄 Toggle Lock Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards(); // Refresh after toggle
        return isCardBlocked ? "Card has been unfrozen." : "Card has been frozen.";
      } else {
        return response["message"] ?? "Failed to update card status.";
      }
    } catch (e) {
      debugPrint("❌ Error toggling lock status: $e");
      return "An error occurred while updating card status.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds funds to a virtual card using a source wallet and payment channel
  Future<String> addFundsToCard({
    required String cardId,
    required double amount,
    required String walletId, // wallet_number
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      // Safely fetch wallet by wallet_number
      Map<String, dynamic> wallet;
      try {
        wallet = _sourceWallets.firstWhere(
              (wallet) => wallet["wallet_number"] == walletId,
        );
      } catch (e) {
        debugPrint("❌ Wallet not found: $e");
        return "Selected wallet not found.";
      }

      final String paymentChannel = wallet["payment_method"] ?? "stripe";
      final String currency = wallet["currency"]?["code"] ?? "NGN";

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      final String endpoint = "/card-mgt/cards/virtual/$cardId/funding";
      final Map<String, dynamic> body = {
        "amount": amount.toString(),
        "currency": currency,
        "payment_channel": paymentChannel,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("💰 Fund Card Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards();
        return "Funds added successfully.";
      } else {
        return response["message"] ?? "Failed to add funds.";
      }
    } catch (e) {
      debugPrint("❌ Error adding funds: $e");
      return "An error occurred while funding the card.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> initiateCardFunding({
    required String sourceWalletNumberOrUuid,
    required double fundingAmount,
    required String virtualCardId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return {"status": false, "message": "Authentication token missing."};
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      const String endpoint = "/card-mgt/cards/virtual/funding/initiate";
      final Map<String, dynamic> body = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "funding_amount": fundingAmount.toString(),
        "virtual_card_id": virtualCardId,
      };

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🚀 Initiate Funding Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards();
      }
      return response;
    } catch (e) {
      debugPrint("❌ Error initiating funding: $e");
      return {"status": false, "message": "An error occurred while initiating funding."};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> processCardFunding({
    required String sourceWalletNumberOrUuid,
    required double fundingAmount,
    required String virtualCardId,
    required String transactionPin, // 👈 NEW
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        return "Authentication token missing.";
      }

      final Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "AppID": appId,
        "Content-Type": "application/json",
      };

      const String endpoint = "/card-mgt/cards/virtual/funding/process";
      final Map<String, dynamic> body = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "funding_amount": fundingAmount.toString(),
        "virtual_card_id": virtualCardId,
        "transaction_pin": transactionPin, // 👈 ADDED
      };

      // Print the body being sent to the server for debugging
      debugPrint("🔒 Sending request to $endpoint with body: $body");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      debugPrint("🏦 Process Funding Response: $response");

      if (response["status"] == true) {
        await fetchVirtualCards();
        return response["message"] ?? "Funding processed successfully.";
      } else {
        return response["message"] ?? "Failed to process funding.";
      }
    } catch (e) {
      debugPrint("❌ Error processing funding: $e");
      return "An error occurred while processing funding.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
