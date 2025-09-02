import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:gobeller/utils/extension.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/reusable_helpers.dart';

class CurrencyController {
  // Add this helper method at the top of the class
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String appId = prefs.getString('appId') ?? '';
    
    return {
      'Accept': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
      'AppID': appId,
    };
  }

  // RETRIEVES USERS FX and CRYPTO CURRENCIES WALLETS
  static Future<Map<String, dynamic>> getUserWalletCollection() async {
    final headers = await _getHeaders();
    final response = await ApiService.getRequest(
      '/user/currency/balance',
      extraHeaders: headers
    );
    
    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return response['data'];
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Could not retrived user wallets.'};
    }
  }

  // RETRIEVES USERS FX CURRENCIES WALLETS
  static Future<Map<String, dynamic>> getUserFXWalletCollection({String currencyCode = ""}) async {
    final headers = await _getHeaders();
    String requestUrl = "/user/fx/currency/balance";
    if(currencyCode.isNotEmpty) {
      requestUrl += "/${currencyCode}";
    }
    
    final response = await ApiService.getRequest(
      requestUrl,
      extraHeaders: headers
    );

    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return {'status':'success', 'data':response['data']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Could not retrived user wallets.'};
    }
  }

  // RETRIEVES USERS CRYPTO CURRENCIES WALLETS
  static Future<Map<String, dynamic>> getUserCryptoWalletCollection({String currencyCode = ""}) async {
    final headers = await _getHeaders();
    String requestUrl = "/user/crypto/crypto/wallet-balance";
    if(currencyCode.isNotEmpty) {
      requestUrl += "/${currencyCode}";
    }

    final response = await ApiService.getRequest(
      requestUrl,
      extraHeaders: headers
    );
    
    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return {'status':'success', 'data':response['data']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Could not retrived user wallets.'};
    }
  }


  // RETIRVES ALL FX CURRENCIES SUPPORTED BY SYSTEM
  static Future<Map<String, dynamic>> getAllSupportedFXCurrencies() async {
    final headers = await _getHeaders();
    final response = await ApiService.getRequest(
      "/user/fx/currency",
      extraHeaders: headers
    );

    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return {'status':'success', 'data':response['data']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Could not retrieved supported currencies.'};
    }
  }


  // RETIRVES ALL CRYTO CURRENCIES SUPPORTED BY SYSTE
  static Future<Map<String, dynamic>> getAllSupportedCryptoCurrencies() async {
    final headers = await _getHeaders();
    final response = await ApiService.getRequest(
      "/user/crypto/crypto/currencies",
      extraHeaders: headers
    );
    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return {'status':'success', 'data':response['data']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Could not retrieved suported currencies.'};
    }
  }

  
  // HANDLE FX CURRENCY CREATION REQUEST TO SERVER
  static Future<Map<String, dynamic>> createNewFxAccount(String? currencyCode) async {

    // app level Validations
    if(currencyCode == null || currencyCode.isEmpty) {
      return {'status':'error', 'message':'Please select an FX currency'};
    }
    
    final headers = await _getHeaders();
    final response = await ApiService.postRequest(
      "/user/fx/create-wallet",
      {'currency': currencyCode},
      extraHeaders: headers
    );

    if(response.containsKey('status') && response['status']=='success' && response.containsKey('message')) {
      return {'status':'success', 'message':response['message']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Error creating a new FX wallet.'};
    }
  }


  // HANDLE CRYPTO CURRENCY CREATION REQUEST TO SERVER
  static Future<Map<String, dynamic>> createNewCryptoAccount(String? currencyCode) async {

    // app level Validations
    if(currencyCode == null || currencyCode.isEmpty) {
      return {'status':'error', 'message':'Please select a crypto currency'};
    }
    
    final headers = await _getHeaders();
    final response = await ApiService.postRequest(
      "/user/crypto/create/wallet",
      {'currency': currencyCode},
      extraHeaders: headers
    );

    if(response.containsKey('status') && response['status']=='success' && response.containsKey('message')) {
      return {'status':'success', 'message':response['message']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Error creating a new Crypto wallet.'};
    }
  }


  // HANDLE CRYPTO SWAP BALANCE EQUIVALENT EXCHANGE
  static Future<Map<String, dynamic>> getCryptoAmountExchange({
    required String fromCurrency,
    required String symbol,
    required String amount,
  }) async {

    String validationErrors = "";

    // app level Validations
    if(fromCurrency.isEmpty) {
      validationErrors += 'The selected wallet to be debited from is invalid.\n';
    }
    if(symbol.isEmpty) {
      validationErrors += 'The selected destination wallet to be credited is invalid.\n';
    }
    if (amount.isEmpty) {
      validationErrors += 'The processable Amount field is required.\n';
    }
    if (amount.isNotEmpty && double.parse(amount) <= 0) {
      validationErrors += 'The processable Amount must be greater than 0.\n';
    }

    // Final validation check
    if (validationErrors.isNotEmpty) {
      return {"status": "error", "message": validationErrors};
    }

    final headers = await _getHeaders();
    final response = await ApiService.postRequest(
      "/user/crypto/crypto/wallet/exchange",
      {
        'from_currency': fromCurrency,
        'symbol': symbol,
        'amount': amount,
      },
      extraHeaders: headers
    );

    if(response.containsKey('status') && response['status']=='success' && response.containsKey('data')) {
      return {'status':'success', 'data':response['data']};
    } else if(response.containsKey('status') && response['status']=='failed' && response.containsKey('error')) {
      return {'status':'error', 'message':response['error']};
    } else {
      return {'status':'error', 'message':'Error converting equivalent processable amount.'};
    }
  }


  /** VALIDATE THE INITIAL AND AFTER OF CRYPTO CURRENCY SWAP ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessCryptoSwapAttempt({
    required String fromWalletSymbol,
    required String destWalletSymbol,
    required String amount,
    bool isfinalSubmission = false,
    String transactionPin = "",
  }) async {
    String validationErrors = "";

    // App-level validations
    if (fromWalletSymbol.isEmpty) {
      validationErrors += 'The selected wallet to be debited from is invalid.\n';
    }
    if (destWalletSymbol.isEmpty) {
      validationErrors += 'The selected wallet to be credited is invalid.\n';
    }
    if (amount.isEmpty) {
      validationErrors += 'The processable Amount field is required.\n';
    }
    if (amount.isNotEmpty && double.parse(amount) <= 0) {
      validationErrors += 'The processable Amount must be greater than 0.\n';
    }

    // Final validation check
    if (validationErrors.isNotEmpty) {
      return {"status": "error", "message": validationErrors};
    }

    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {

      if (transactionPin.isEmpty) {
        return {"status": "error", "message": "The Transaction Pin is required."};
      }
      
      // Call the API via the ApiService class
      final response = await ApiService.postRequest("/user/crypto/wallet/currency-swap", {
        'from_currency': fromWalletSymbol,
        'destination_currency': destWalletSymbol,
        'amount': amount,
        'transaction_pin': transactionPin
      });

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message'], "data": response['data']??[]};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }
    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }

    return {"status": "error", "message": "Crypto swap attempt failed."};
  }
  
  
  /** VALIDATE THE INITIAL AND AFTER OF CRYPTO CURRENCY SEND ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessCryptoSendAttempt({
    required String fromWalletSymbol,
    required String destinationAddress,
    required String amount,
    bool isfinalSubmission = false,
    String transactionPin = "",
  }) async {
    String validationErrors = "";

    // App-level validations
    if (fromWalletSymbol.isEmpty) {
      validationErrors += 'The selected wallet to be debited from is invalid.\n';
    }
    if (destinationAddress.isEmpty) {
      validationErrors += 'The destination address to be credited is required.\n';
    }
    if (amount.isEmpty) {
      validationErrors += 'The processable Amount field is required.\n';
    }
    if (amount.isNotEmpty && double.parse(amount) <= 0) {
      validationErrors += 'The processable Amount must be greater than 0.\n';
    }

    // Final validation check
    if (validationErrors.isNotEmpty) {
      return {"status": "error", "message": validationErrors};
    }

    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {

      if (transactionPin.isEmpty) {
        return {"status": "error", "message": "The Transaction Pin is required."};
      }

      // Call the API via the ApiService class
      final response = await ApiService.postRequest("/user/crypto/withdrawal", {
        'from_wallet_symbol': fromWalletSymbol,
        'destination_address': destinationAddress,
        'amount': amount,
        'transaction_pin': transactionPin
      });

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message'], "data": response['data']??[]};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }
    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }

    return {"status": "error", "message": "Crypto send attempt failed."};
  }


  static Map<String, String> processWalletsExtraction(List<dynamic> wallets, String type) {
    Map<String, String> result = {};

    int index = 0;
    for (var wallet in wallets) {
      if (type == "crypto") {
        result["CRYPTO-${wallet["currency"]?["symbol"]??''}-${index}"] = "${wallet["currency"]?["symbol"]??'CRYPTO'}-${ReusableHelpers.shortenTextLength(wallet["address"], maxLength: 10)}";
      } else if (type == "fx") {
        result["FX-${wallet["currency"]?["symbol"]??''}-${index}"] = "${wallet["currency"]?["symbol"]??'FX'}-${ReusableHelpers.shortenTextLength(wallet["wallet_uuid"], maxLength: 10)}";
      } else if (type == "ngn") {
        result["NG-NGN-${index}"] = "NGN-${ReusableHelpers.shortenTextLength(wallet["account_number"], maxLength: 10)}";
      }
      index += 1; // incrementing counter 
    }
    return result;
  }



  static Map<String, String> extractCurrenciesKeyValuePairs(Map<String, dynamic> fetchedCurrencyWallets) {
    Map<String, String> ngnWallets = processWalletsExtraction((fetchedCurrencyWallets['ngn'] ?? []), 'ngn');
    Map<String, String> fxWallets = processWalletsExtraction((fetchedCurrencyWallets['fx'] ?? []), 'fx');
    Map<String, String> cryptoWallets = processWalletsExtraction((fetchedCurrencyWallets['crypto'] ?? []), 'crypto');

    return {...ngnWallets, ...fxWallets, ...cryptoWallets};
  }


  static Map<String, dynamic> filterCurrentDashboardWallet({
    String? currencyCode,
    Map<String, dynamic>? allWalletBalances
  }) {

    if(currencyCode != null && allWalletBalances != null) {
      List<String> currencyCodeSplit = currencyCode.split('-');
      if(currencyCodeSplit.length == 3) {
        final String currencyCategory = currencyCodeSplit[0];
        final String currencyCode = currencyCodeSplit[1];
        final int currencyIndex = int.parse(currencyCodeSplit[2]);

        // For NGN currencies
        if(currencyCategory == 'NG' && currencyCode == 'NGN') {
          final Map<String, dynamic> currencyCategoryData = allWalletBalances['ngn'][currencyIndex];
          return {
            "decimal_balance_digits": 2,
            "wallet_currency_symbol": "₦",
            "account_number": currencyCategoryData['account_number'],
            "available_balance": currencyCategoryData['available_balance'].toString()
          };
        }

        // For FX currencies
        if(currencyCategory == 'FX') {
          final Map<String, dynamic> currencyCategoryData = allWalletBalances['fx'][currencyIndex];
          return {
            "decimal_balance_digits": 2,
            "wallet_currency_symbol": currencyCategoryData["currency"]?["icon"] ?? "",
            "account_number": currencyCategoryData["wallet_uuid"],
            "available_balance": currencyCategoryData['available_balance'].toString()
          };
        }

        // For crypto currencies
        if(currencyCategory == 'CRYPTO') {
          final Map<String, dynamic> currencyCategoryData = allWalletBalances['crypto'][currencyIndex];
          return {
            "decimal_balance_digits": 10,
            "wallet_currency_symbol": currencyCategoryData["currency"]?["icon"] ?? "",
            "account_number": currencyCategoryData["address"],
            "available_balance": currencyCategoryData['available_balance'].toString()
          };
        }


      }
    }

    return {};
  }


}

