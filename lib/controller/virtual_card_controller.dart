import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VirtualCardController {

  // Add helper method to get headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String appId = prefs.getString('appId') ?? '';
    
    return {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Accept': 'application/json',
      'AppID': appId,
    };
  }

  /** VALIDATE THE INITIAL AND AFTER VIRTUAL CARD CREATION ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessVCardCreationAttempt({
    bool isfinalSubmission = false,
    String transactionPin = "",
  }) async {

    String validationErrors = "";

    // final validation check
    if(validationErrors.isNotEmpty) {
      return {'status':'error', 'message':validationErrors};
    }
      
    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {

      if (transactionPin.isEmpty) {
        return {"status": "error", "message": "The Transaction Pin is required."};
      }

      final headers = await _getHeaders();
      final response = await ApiService.postRequest(
        "/user/vcards/creasste-card",
        {'transaction_pin': transactionPin},
        extraHeaders: headers
      );

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message']};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }

    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }
    return {"status": "error", "message": "Virtual Card creation attempt failed."};
  }


  /** VALIDATE THE INITIAL AND AFTER VIRTUAL CARD STATUS UPDATE ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessVCardStatusUpdateAttempt({
    required String status,
    required String accountId,
    bool isfinalSubmission = false,
    String transactionPin = "",
  }) async {

    String validationErrors = "";

    // app level Validations
    if(status.isEmpty) {
      validationErrors += 'The vCard Status is invalid.\n';
    }
    if(accountId.isEmpty) {
      validationErrors += 'The Account ID is invalid.\n';
    }

    // final validation check
    if(validationErrors.isNotEmpty) {
      return {'status':'error', 'message':validationErrors};
    }
      
    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {
      if (transactionPin.isEmpty) {
        return {"status": "error", "message": "The Transaction Pin is required."};
      }

      final headers = await _getHeaders();
      final response = await ApiService.postRequest(
        "/user/vcards/block-unblock",
        {
          'status': status,
          'account_id': accountId,
          'transaction_pin': transactionPin
        },
        extraHeaders: headers
      );

      print("response: ${response}");

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message']};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }

    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }
    return {"status": "error", "message": "Virtual Card status update attempt failed."};
  }


  /** VALIDATE THE INITIAL AND AFTER VIRTUAL CARD FUNDING ATTEMPT **/
  static Future<Map<String, dynamic>> validateAndProcessVCardFundingAttempt({
    required String amount,
    required String accountId,
    bool isfinalSubmission = false,
    String transactionPin = "",
  }) async {

    String validationErrors = "";

    // app level Validations
    if(amount.isEmpty) {
      validationErrors += 'The Amount field is required.\n';
    }
    if(accountId.isEmpty) {
      validationErrors += 'The Account ID is invalid.\n';
    }

    // final validation check
    if(validationErrors.isNotEmpty) {
      return {'status':'error', 'message':validationErrors};
    }
      
    // If it's the final submission, validate the transaction pin
    if (isfinalSubmission) {
      if (transactionPin.isEmpty) {
        return {"status": "error", "message": "The Transaction Pin is required."};
      }

      final headers = await _getHeaders();
      final response = await ApiService.postRequest(
        "/user/vcards/fund",
        {
          'amount': amount,
          'account_id': accountId,
          'transaction_pin': transactionPin
        },
        extraHeaders: headers
      );

      print("response: ${response}");

      if (response.containsKey('status')) {
        if (response['status'] == 'success' && response.containsKey('message')) {
          return {"status": "success", "message": response['message']};
        } else if (response['status'] == 'failed' && response.containsKey('error')) {
          return {"status": "error", "message": response['error']};
        }
      }

    } else {
      if (validationErrors.isEmpty) {
        return {"status": "validated"};
      }      
    }
    return {"status": "error", "message": "Virtual Card funding attempt failed."};
  }



  /** ATTEMPT TO GET USER VIRTUAL CARD DETAILS **/
  static Future<Map<String, dynamic>> getVCardDetails() async {

    final headers = await _getHeaders();
    final response = await ApiService.getRequest(
      "/user/vcards/card-details",
      extraHeaders: headers
    );
    
    print("getVCardDetails: ${response}");

    if (response.containsKey('status')) {
      if (response['status'] == 'success' && response.containsKey('message') && response.containsKey('data')) {
        return {"status": "success", "message": response['message'], "data": response['data']??[]};
      } else if (response['status'] == 'failed' && response.containsKey('error')) {
        return {"status": "error", "message": response['error']};
      }
    }

    return {"status": "error", "message": "Failed to Retrieve Virtual Card Details."};
  }


  /** ATTEMPT TO GET THE USD TO NGN CONVERSION AMOUNT **/
  static Future<Map<String, dynamic>> getUSDToNGNAmountConversion({
    required double amountInUSD,
  }) async {

    final headers = await _getHeaders();
    final response = await ApiService.getRequest(
      "/user/vcards/rate?amount=${amountInUSD.toString()}",
      extraHeaders: headers
    );
    
    if (response.containsKey('status')) {
      if (response['status'] == 'success' && response.containsKey('message') && response.containsKey('data')) {
        return {"status": "success", "message": response['message'], "data": response['data']??[]};
      } else if (response['status'] == 'failed' && response.containsKey('error')) {
        return {"status": "error", "message": response['error']};
      }
    }
    return {"status": "error", "message": "Failed to get Exchange rate conversion."};
  }

}

