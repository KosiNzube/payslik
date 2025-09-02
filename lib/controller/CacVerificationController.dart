import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:http/http.dart' as http; // Add this if not already
import 'package:path/path.dart'; // For basename()
import 'package:mime/mime.dart'; // For content-type detection
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacVerificationController with ChangeNotifier {
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  Map<String, dynamic>? _companyDetails;
  Map<String, dynamic>? get companyDetails => _companyDetails;

  Map<String, dynamic>? _ninData;
  Map<String, dynamic>? get ninData => _ninData;

  String _verificationMessage = '';
  String get verificationMessage => _verificationMessage;

  List<dynamic>? _wallets;
  List<dynamic>? get wallets => _wallets;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Fetch Wallet Transactions
  Future<void> fetchWalletTransactions({required String walletNumber}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final appId = prefs.getString('appId') ?? '';

      if (token == null) {
        debugPrint("❌ No auth token.");
        _isLoading = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'AppID': appId,
      };

      final response = await ApiService.getRequest(
        "/customers/wallet-transactions?page=1&items_per_page=15&wallet_number_or_uuid=$walletNumber",
        extraHeaders: headers,
      );

      if (response["status"] == true) {
        _transactions = List<Map<String, dynamic>>.from(
          response["data"]["transactions"]["data"] ?? [],
        );
      } else {
        debugPrint("⚠️ Transaction fetch failed: ${response["message"]}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching transactions: $e");
    }

    _isLoading = false;
    notifyListeners();
  }



  /// Verify CAC Number
  Future<void> verifyCacNumber({
    required String corporateIdType,
    required String corporateIdNumber,
    required BuildContext context,
  }) async {
    _isVerifying = true;
    _companyDetails = null;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? appId = prefs.getString('appId'); // <-- Get AppID

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final String endpoint = "/verify/cac-number";
      final Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (appId != null) "AppID": appId, // <-- Add AppID to headers if present
      };

      final Map<String, dynamic> body = {
        "corporate-id-type": corporateIdType,
        "corporate-id-number": corporateIdNumber,
      };

      debugPrint("📤 Sending CAC Verification Request: ${jsonEncode(body)}");

      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers);
      debugPrint("🔹 CAC Verification API Response: $response");

      if (response["status"] == true) {
        _companyDetails = response["data"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ CAC Verified: ${_companyDetails?['company_name'] ?? 'Company'}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${response['message']}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Verification failed: $e"), backgroundColor: Colors.red),
      );
    }

    _isVerifying = false;
    notifyListeners();
  }

  /// Verify NIN, BVN, or Passport Number
  Future<void> verifyId(String idNumber, String idType) async {
    _isVerifying = true;
    _ninData = null;
    _verificationMessage = '';
    notifyListeners();

    try {
      String endpoint = '';

      if (idType == 'nin') {
        endpoint = "/verify/nin/$idNumber";
      } else if (idType == 'bvn') {
        endpoint = "/verify/bvn/$idNumber";
      } else if (idType == 'passport-number') {
        endpoint = "/verify/passport-number/$idNumber";
      } else {
        _verificationMessage = "⚠️ Invalid ID type selected.";
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.getRequest(endpoint);
      debugPrint("🔹 ID Verification API Response: $response");

      if (response["status"] == true && response["data"] != null) {
        _ninData = response["data"];
        _verificationMessage = "$idType Verified Successfully!";
      } else {
        _verificationMessage = response["message"] ?? "⚠️ Verification failed.";
      }
    } on SocketException catch (_) {
      _verificationMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      _verificationMessage = "❌ Error verifying ID. Please try again.";
      debugPrint("❌ ID Verification API Error: $e");
    }

    _isVerifying = false;
    notifyListeners();
  }



  Future<bool> registerCorporateBusiness({
    required String corporateBusinessIdValue,
    required String natureOfCorporateBusiness,
    required String corporateBusinessTinNumber,
    required String corporateOwnerIdType,
    required String corporateOwnerIdValue,
    required File businessCertificate,
    required File cacMoaDocument,
    required File cacStatusReport,
    required File recentPassportPhotograph,
    required File governmentIssuedId,
    required File proofOfAddress,
    required BuildContext context,
    required String corporateIdValue,
    required String corporateBusinessIdType,
  }) async {
    _isVerifying = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String appId = prefs.getString('appId') ?? '';

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Authentication required. Please log in again.")),
        );
        _isVerifying = false;
        notifyListeners();
        return false;  // Return false if no token
      }

      final uri = Uri.parse("https://app.gobeller.cc/api/v1/customers/wallets/create/corporate-business");

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'AppID': appId,
        })
        ..fields['corporate_business_id_type'] = corporateBusinessIdType
        ..fields['corporate_business_id_value'] = corporateBusinessIdValue
        ..fields['nature_of_corporate_business'] = natureOfCorporateBusiness
        ..fields['corporate_business_tin_number'] = corporateBusinessTinNumber
        ..fields['corporate_owner_id_type'] = corporateOwnerIdType
        ..fields['corporate_owner_id_value'] = corporateOwnerIdValue
        ..files.add(await http.MultipartFile.fromPath(
            'business_certificate_upload', businessCertificate.path,
            contentType: _detectMimeType(businessCertificate.path)))
        ..files.add(await http.MultipartFile.fromPath(
            'cac_moa_document_upload', cacMoaDocument.path,
            contentType: _detectMimeType(cacMoaDocument.path)))
        ..files.add(await http.MultipartFile.fromPath(
            'cac_status_report_upload', cacStatusReport.path,
            contentType: _detectMimeType(cacStatusReport.path)))
        ..files.add(await http.MultipartFile.fromPath(
            'recent_passport_photograph_upload', recentPassportPhotograph.path,
            contentType: _detectMimeType(recentPassportPhotograph.path)))
        ..files.add(await http.MultipartFile.fromPath(
            'recent_valid_government_issued_id_upload', governmentIssuedId.path,
            contentType: _detectMimeType(governmentIssuedId.path)))
        ..files.add(await http.MultipartFile.fromPath(
            'proof_of_address_upload', proofOfAddress.path,
            contentType: _detectMimeType(proofOfAddress.path)));

      // 🟡 Log what's being sent
      print('--- Logging Form Data ---');
      request.fields.forEach((key, value) {
        print('Field: $key = $value');
      });

      print('--- Logging File Uploads ---');
      for (var file in request.files) {
        print('File field: ${file.field}, filename: ${file.filename}, contentType: ${file.contentType}');
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final decoded = jsonDecode(resBody);

      if (response.statusCode == 200 && decoded["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Corporate business registered successfully.")),
        );
        _isVerifying = false;
        notifyListeners();
        return true;  // Success
      } else {
        print("❌ Registration failed: ${decoded["message"] ?? "Unknown error"}");
        print("Response body: $resBody");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ ${decoded["message"] ?? "Registration failed."}"),
            backgroundColor: Colors.red,
          ),
        );
        _isVerifying = false;
        notifyListeners();
        return false;  // Failure
      }
    } catch (e) {
      print("❌ Error during registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error during registration: $e"), backgroundColor: Colors.red),
      );
      _isVerifying = false;
      notifyListeners();
      return false;  // Failure on exception
    }
  }


  /// Fetch Wallets
  Future<void> fetchWallets({int retryCount = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint("❌ No authentication token found. Please login again.");
        _wallets = [];
        notifyListeners();
        return;
      }

      final extraHeaders = {
        'Authorization': 'Bearer $token',
      };

      final response = await ApiService.getRequest(
        "/customers/wallets",
        extraHeaders: extraHeaders,
      );

      debugPrint("🔹 Raw Wallets API Response: $response");

      if (response["status"] == true) {
        dynamic data = response["data"];

        // Decode JSON string if needed
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            debugPrint("❌ Failed to decode wallet data: $e");
            _wallets = [];
            notifyListeners();
            return;
          }
        }

        if (data is List) {
          // ✅ Filter for corporate wallets
          final filtered = data.where((wallet) =>
          wallet is Map && wallet["ownership_type"] == "corporate-wallet"
          ).toList();

          debugPrint("✅ Filtered corporate wallets: ${filtered.length} found.");
          _wallets = filtered;

        } else if (data is Map && data.containsKey("data") && data["data"] is List) {
          final innerList = data["data"];
          final filtered = innerList.where((wallet) =>
          wallet is Map && wallet["ownership_type"] == "corporate-wallet"
          ).toList();

          debugPrint("✅ Filtered corporate wallets (nested): ${filtered.length} found.");
          _wallets = filtered;

        } else {
          debugPrint("❌ Unexpected data format: $data");
          _wallets = [];
        }

        notifyListeners();
        return;

      } else {
        debugPrint("❌ API Error: ${response["message"]}");

        if (response["status_code"] == 401 && retryCount < 3) {
          debugPrint("🔁 401 Unauthorized - Retrying (${retryCount + 1}/3)...");
          return fetchWallets(retryCount: retryCount + 1);
        }

        _wallets = [];
        notifyListeners();
      }

    } catch (e) {
      debugPrint("❌ Wallets API Exception: $e");

      if (e.toString().contains('401') && retryCount < 3) {
        debugPrint("🔁 401 Unauthorized in exception - Retrying (${retryCount + 1}/3)...");
        return fetchWallets(retryCount: retryCount + 1);
      }

      _wallets = [];
      notifyListeners();
    }
  }



  /// Helper method to detect MIME type
  MediaType _detectMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    final split = mimeType?.split('/') ?? ['application', 'octet-stream'];
    return MediaType(split[0], split[1]);
  }

}
