// // import 'dart:convert';
// // import 'dart:io'; // 👈 Needed for catching SocketException
// // import 'package:flutter/material.dart';
// // import 'package:gobeller/utils/api_service.dart';
// // import 'package:http/http.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class NinVerificationController with ChangeNotifier {
// //   bool _isVerifying = false;
// //   bool get isVerifying => _isVerifying;
// //
// //   bool _isSubmitting = false;
// //   bool get isSubmitting => _isSubmitting;
// //
// //   Map<String, dynamic>? _ninData;
// //   Map<String, dynamic>? get ninData => _ninData;
// //
// //   String _verificationMessage = "";
// //   String get verificationMessage => _verificationMessage;
// //
// //   String _submissionMessage = "";
// //   String get submissionMessage => _submissionMessage;
// //
// //   /// Verifies NIN, BVN or Passport and fetches user details
// //   Future<void> verifyId(String idNumber, String idType) async {
// //     _isVerifying = true;
// //     _ninData = null;
// //     _verificationMessage = '';
// //     notifyListeners();
// //
// //     try {
// //       String endpoint = '';
// //
// //       if (idType == 'nin') {
// //         endpoint = "/verify/nin/$idNumber";
// //       } else if (idType == 'bvn') {
// //         endpoint = "/verify/bvn/$idNumber";
// //       } else if (idType == 'passport-number') {
// //         endpoint = "/verify/passport-number/$idNumber";
// //       } else {
// //         _verificationMessage = "⚠️ Invalid ID type selected.";
// //         _isVerifying = false;
// //         notifyListeners();
// //         return;
// //       }
// //
// //       final response = await ApiService.getRequest(endpoint);
// //       debugPrint("🔹 ID Verification API Response: $response");
// //
// //       if (response["status"] == true && response["data"] != null) {
// //         _ninData = response["data"];
// //         _verificationMessage = "$idType Verified Successfully!";
// //       } else {
// //         _verificationMessage = response["message"] ?? "⚠️ Verification failed.";
// //       }
// //     } on SocketException catch (_) {
// //       _verificationMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
// //     } catch (e) {
// //       _verificationMessage = "❌ Error verifying ID. Please try again.";
// //       debugPrint("❌ ID Verification API Error: $e");
// //     }
// //
// //     _isVerifying = false;
// //     notifyListeners();
// //   }
// //
// //   /// Submits the registration data with KYC
// //   Future<Map<String, dynamic>> submitRegistration({
// //     required String idType,
// //     required String idNumber,
// //     required String firstName,
// //     required String middleName,
// //     required String lastName,
// //     required String email,
// //     required String username,
// //     required String telephone,
// //     required String gender,
// //     required String password,
// //     required int transactionPin,
// //     required String dateOfBirth,
// //     }) async {
// //     _isSubmitting = true;
// //     _submissionMessage = '';
// //     notifyListeners();
// //
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final String appId = prefs.getString('appId') ?? '';
// //
// //       if (appId.isEmpty) {
// //         return {
// //           'success': false,
// //           'message': '⚙️ App configuration missing. Please restart the app.'
// //         };
// //       }
// //
// //       // Prepare the registration request body
// //       final Map<String, dynamic> body = {
// //         "id_type": idType,
// //         "id_value": idNumber.toString(),
// //         "first_name": firstName,
// //         "middle_name": middleName,
// //         "last_name": lastName,
// //         "email": email,
// //         "username": username,
// //         "telephone": telephone,
// //         "gender": gender,
// //         "password": password,
// //         "transaction_pin": transactionPin.toString(),
// //         "date_of_birth": dateOfBirth,
// //       };
// //
// //       debugPrint("📤 Submitting Registration Payload:");
// //       body.forEach((key, value) => debugPrint("   $key: $value"));
// //
// //       // Setup headers
// //       final headers = {
// //         'Accept': 'application/json',
// //         'Content-Type': 'application/json',
// //         'AppID': appId,
// //       };
// //
// //       // ⚡ Add timeout to request
// //       final response = await ApiService.postRequest(
// //         '/customers-api/registrations/with-kyc',
// //         body,
// //         extraHeaders: headers,
// //       ).timeout(const Duration(seconds: 10));
// //
// //       final bool status = response['status'] == true;
// //       final String message = (response['message'] ?? '').toString().trim();
// //
// //       if (status) {
// //         _submissionMessage = "✅ Registration successful! Please check your email to verify your account.";
// //
// //         if (response.containsKey('data')) {
// //           final userData = response['data'];
// //           await prefs.setString('userData', json.encode(userData));
// //           await prefs.setBool('isLoggedIn', false); // Ensure the user isn't logged in after registration
// //         }
// //
// //         if (response.containsKey('app_settings')) {
// //           await prefs.setString('appSettingsData', json.encode(response['app_settings']));
// //         }
// //
// //         if (response.containsKey('organization')) {
// //           await prefs.setString('organizationData', json.encode(response['organization']));
// //         }
// //
// //         return {'success': true, 'message': _submissionMessage};
// //       } else {
// //         String friendlyMessage = '⚠️ Registration failed.';
// //
// //         if (message.isNotEmpty) {
// //           friendlyMessage = message;
// //         } else if (response.containsKey('errors')) {
// //           final errors = response['errors'] as Map<String, dynamic>;
// //           final errorMessages = errors.entries
// //               .map((entry) => entry.value is List
// //               ? (entry.value as List).join(', ')
// //               : entry.value.toString())
// //               .join('\n');
// //
// //           friendlyMessage = errorMessages.isNotEmpty
// //               ? "⚠️ $errorMessages"
// //               : '⚠️ Registration failed.';
// //         }
// //
// //         return {'success': false, 'message': friendlyMessage};
// //       }
// //
// //     } on SocketException {
// //       return {
// //         'success': false,
// //         'message': '📶 No internet connection. Please check your network and try again.'
// //       };
// //     }  on ClientException {
// //       return {
// //         'success': false,
// //         'message': '🌐 Unable to connect to the server. Please try again later.'
// //       };
// //     } catch (e) {
// //       final error = e.toString().toLowerCase();
// //       if (error.contains("socketexception") || error.contains("failed host lookup")) {
// //         return {
// //           'success': false,
// //           'message': '📡 Network error. Please check your internet connection.'
// //         };
// //       }
// //
// //       return {
// //         'success': false,
// //         'message': '❌ Something went wrong. Please try again shortly.'
// //       };
// //     } finally {
// //       _isSubmitting = false;
// //       notifyListeners();
// //     }
// //   }
// //
// //
// //   /// Clears verification data
// //   void clearVerification() {
// //     _ninData = null;
// //     _verificationMessage = "";
// //     notifyListeners();
// //   }
// // }
//
//
// import 'dart:convert';
// import 'dart:io'; // 👈 Needed for catching SocketException
// import 'package:flutter/material.dart';
// import 'package:gobeller/utils/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class NinVerificationController with ChangeNotifier {
//   bool _isVerifying = false;
//   bool get isVerifying => _isVerifying;
//
//   bool _isSubmitting = false;
//   bool get isSubmitting => _isSubmitting;
//
//   Map<String, dynamic>? _ninData;
//   Map<String, dynamic>? get ninData => _ninData;
//
//   String _verificationMessage = "";
//   String get verificationMessage => _verificationMessage;
//
//   String _submissionMessage = "";
//   String get submissionMessage => _submissionMessage;
//
//   /// Verifies NIN, BVN or Passport and fetches user details
//   Future<void> verifyId(String idNumber, String idType) async {
//     _isVerifying = true;
//     _ninData = null;
//     _verificationMessage = '';
//     notifyListeners();
//
//     try {
//       String endpoint = '';
//
//       if (idType == 'nin') {
//         endpoint = "/verify/nin/$idNumber";
//       } else if (idType == 'bvn') {
//         endpoint = "/verify/bvn/$idNumber";
//       } else if (idType == 'passport-number') {
//         endpoint = "/verify/passport-number/$idNumber";
//       } else {
//         _verificationMessage = "⚠️ Invalid ID type selected.";
//         _isVerifying = false;
//         notifyListeners();
//         return;
//       }
//
//       final response = await ApiService.getRequest(endpoint);
//       debugPrint("🔹 ID Verification API Response: $response");
//
//       if (response["status"] == true && response["data"] != null) {
//         _ninData = response["data"];
//         _verificationMessage = "$idType Verified Successfully!";
//       } else {
//         _verificationMessage = response["message"] ?? "⚠️ Verification failed.";
//       }
//     } on SocketException catch (_) {
//       _verificationMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
//     } catch (e) {
//       _verificationMessage = "❌ Error verifying ID. Please try again.";
//       debugPrint("❌ ID Verification API Error: $e");
//     }
//
//     _isVerifying = false;
//     notifyListeners();
//   }
//
//   /// Submits the registration data with KYC
//   Future<void> submitRegistration({
//     required String idType,
//     required String idNumber,
//     required String firstName,
//     required String middleName,
//     required String lastName,
//     required String email,
//     required String username,
//     required String telephone,
//     required String address,
//     required String gender,
//     required String password,
//     required int transactionPin,
//     required String dateOfBirth,
//   }) async {
//     _isSubmitting = true;
//     _submissionMessage = '';
//     notifyListeners();
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final String appId = prefs.getString('appId') ?? '';
//       if (appId.isEmpty) {
//         _submissionMessage = '⚙️ App configuration missing. Please restart the app.';
//         _isSubmitting = false;
//         notifyListeners();
//         return;
//       }
//
//       final Map<String, dynamic> body = {
//         "id_type": idType,
//         "id_value": idNumber,
//         "first_name": firstName,
//         "middle_name": middleName,
//         "last_name": lastName,
//         "email": email,
//         "username": username,
//         "telephone": telephone,
//         "physical_address": address,
//         "gender": gender,
//         "password": password,
//         "transaction_pin": transactionPin.toString(),
//         "date_of_birth": dateOfBirth,
//       };
//
//       debugPrint("📤 Submitting Registration Payload:");
//       body.forEach((key, value) => debugPrint("   $key: $value"));
//
//       final headers = {
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//         'AppID': appId,
//       };
//
//       final response = await ApiService.postRequest(
//         '/customers-api/registrations/with-kyc',
//         body,
//         extraHeaders: headers,
//       );
//
//       debugPrint("🔹 Registration API Response: $response");
//
//       if (response["status"] == true) {
//         _submissionMessage = "✅ Registration successful! Please check your email to verify your account.";
//
//         if (response.containsKey('data')) {
//           final userData = response['data'];
//           await prefs.setString('userData', json.encode(userData));
//           await prefs.setBool('isLoggedIn', false);
//         }
//
//         if (response.containsKey('token')) {
//           await prefs.setString('authToken', response['token']);
//         }
//
//         if (response.containsKey('app_settings')) {
//           await prefs.setString('appSettingsData', json.encode(response['app_settings']));
//         }
//
//         if (response.containsKey('organization')) {
//           await prefs.setString('organizationData', json.encode(response['organization']));
//         }
//       } else {
//         if (response.containsKey('errors')) {
//           final errors = response['errors'] as Map<String, dynamic>;
//           final errorMessages = errors.entries
//               .map((entry) => entry.value is List
//               ? (entry.value as List).join(', ')
//               : entry.value.toString())
//               .join('\n');
//
//           _submissionMessage = errorMessages.isNotEmpty
//               ? "⚠️ $errorMessages"
//               : (response["message"] ?? "⚠️ Registration failed.");
//         } else {
//           _submissionMessage = response["message"] ?? "⚠️ Registration failed.";
//         }
//       }
//     } on SocketException catch (_) {
//       _submissionMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
//     } catch (e) {
//       _submissionMessage = "❌ Error submitting registration. Please try again.";
//       debugPrint("❌ Registration API Error: $e");
//     }
//
//     _isSubmitting = false;
//     notifyListeners();
//   }
//
//
//   /// Clears verification data
//   void clearVerification() {
//     _ninData = null;
//     _verificationMessage = "";
//     notifyListeners();
//   }
// }


import 'dart:convert';
import 'dart:io'; // 👈 Needed for catching SocketException
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NinVerificationController with ChangeNotifier {
  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Map<String, dynamic>? _ninData;
  Map<String, dynamic>? get ninData => _ninData;

  String _verificationMessage = "";
  String get verificationMessage => _verificationMessage;

  String _submissionMessage = "";
  String get submissionMessage => _submissionMessage;

  /// Verifies NIN, BVN or Passport and fetches user details
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

  /// Submits the registration data with KYC
  Future<void> submitRegistration({
    required String idType,
    required String idNumber,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String username,
    required String telephone,
    required String address,
    required String gender,
    required String password,
    required String referral,

    required int transactionPin,
    required String dateOfBirth,
    required bool should_create_virtual_wallet, required String telPrefix, required String countryId,  String? ledger_number,  String? pf_number,  String? ippis_number, required String identityCode,
  String? currency_code,
  }) async {
    _isSubmitting = true;
    _submissionMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        "id_type": idType,
        "id_value": idNumber.toString(),
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "email": email,
        "username": username,
        "telephone": telephone,
        "physical_address": address,
        "country_id": countryId,
        "tel_prefix": telPrefix,
        "gender": gender,
        "refcode":referral,



        "password": password,
        "transaction_pin": transactionPin.toString(),
        "date_of_birth": dateOfBirth,
        "should_create_virtual_wallet":should_create_virtual_wallet,

        if (ledger_number != null) "ledger_number": ledger_number,
        if (pf_number != null) "pf_number": pf_number,
        if (ippis_number != null) "ippis_number": ippis_number,

        if (identityCode == '0061') "virtual_wallet_type": "internal-account",
        if (identityCode == '0061') "virtual_wallet_currency_code": currency_code,


      };

      debugPrint("📤 Submitting Registration Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response = await ApiService.postRequest(
        '/customers-api/registrations/with-kyc',
        body,
      );

      debugPrint("🔹 Registration API Response: $response");

      if (response["status"] == true) {
        _submissionMessage = "✅ Registration successful! Please check your email to verify your account.";

        final prefs = await SharedPreferences.getInstance();

        if (response.containsKey('data')) {
          final userData = response['data'];
          await prefs.setString('userData', json.encode(userData));
          await prefs.setBool('isLoggedIn', false);
        }

        if (response.containsKey('token')) {
          await prefs.setString('authToken', response['token']);
        }

        if (response.containsKey('app_settings')) {
          await prefs.setString('appSettingsData', json.encode(response['app_settings']));
        }

        if (response.containsKey('organization')) {
          await prefs.setString('organizationData', json.encode(response['organization']));
        }
      } else {
        if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          _submissionMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : (response["message"] ?? "⚠️ Registration failed.");
        } else {
          _submissionMessage = response["message"] ?? "⚠️ Registration failed.";
        }
      }
    } on SocketException catch (_) {
      _submissionMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      _submissionMessage = "❌ Error submitting registration. Please try again.";
      debugPrint("❌ Registration API Error: $e");
    }

    _isSubmitting = false;
    notifyListeners();
  }

  /// Clears verification data
  void clearVerification() {
    _ninData = null;
    _verificationMessage = "";
    notifyListeners();
  }
}



class No_KYC_Controller with ChangeNotifier {


  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;



  String _submissionMessage = "";
  String get submissionMessage => _submissionMessage;


  /// Submits the registration data with no KYC
  Future<void> submitRegistration({

    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String username,
    required String telephone,
    required String address,
    required String gender,
    required String password,
    required String referral,
    required bool existing_account,
    String? currency_code,

    required int transactionPin,
    required String dateOfBirth,
    required bool should_create_virtual_wallet,
    required String azanumber,required String telPrefix, required String countryId, required String bvn, required String identityCode,
  }) async {
    _isSubmitting = true;
    _submissionMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> body;

      if(existing_account==true) {
        body = {

          "first_name": firstName,
          "middle_name": middleName,
          "last_name": lastName,
          "email": email,
          "username": username,
          "telephone": telephone,
          "country_id": countryId,
          "tel_prefix": telPrefix,
          "additional_ids": {
            "bvn": bvn,
          },
          "physical_address": address,
          "gender": gender,
          "refcode": referral,
          "id_type": "third-party-api-reference",
          "id_value": azanumber,
          "password": password,
          "transaction_pin": transactionPin.toString(),
          "date_of_birth": dateOfBirth,
          "should_create_virtual_wallet": should_create_virtual_wallet,
          if (identityCode == '0061') "virtual_wallet_type": "internal-account",
          if (identityCode == '0061') "virtual_wallet_currency_code": currency_code,
        };
      }else{
       body = {

          "first_name": firstName,
          "middle_name": middleName,
          "last_name": lastName,
          "email": email,
          "username": username,
          "telephone": telephone,
          "physical_address": address,
          "gender": gender,
          "refcode": referral,
         "country_id": countryId,
         "tel_prefix": telPrefix,
          "password": password,
          "transaction_pin": transactionPin.toString(),
          "date_of_birth": dateOfBirth,
          "should_create_virtual_wallet": should_create_virtual_wallet,
         if (identityCode == '0061') "virtual_wallet_type": "internal-account",
         if (identityCode == '0061') "virtual_wallet_currency_code": currency_code,
        };
      }

      debugPrint("📤 Submitting Registration Payload:");
      body.forEach((key, value) => debugPrint("   $key: $value"));

      final response =existing_account==true? await ApiService.postRequest(
        '/customers-api/registrations/with-kyc',
        body,
      ):await ApiService.postRequest(
        '/customers-api/registrations/without-kyc',
        body,
      );

      debugPrint("🔹 Registration API Response: $response");

      if (response["status"] == true) {
        _submissionMessage = "✅ Registration successful! Please check your email to verify your account.";

        final prefs = await SharedPreferences.getInstance();

        if (response.containsKey('data')) {
          final userData = response['data'];
          await prefs.setString('userData', json.encode(userData));
          await prefs.setBool('isLoggedIn', false);
        }

        if (response.containsKey('token')) {
          await prefs.setString('authToken', response['token']);
        }

        if (response.containsKey('app_settings')) {
          await prefs.setString('appSettingsData', json.encode(response['app_settings']));
        }

        if (response.containsKey('organization')) {
          await prefs.setString('organizationData', json.encode(response['organization']));
        }
      } else {
        if (response.containsKey('errors')) {
          final errors = response['errors'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((entry) => entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString())
              .join('\n');

          _submissionMessage = errorMessages.isNotEmpty
              ? "⚠️ $errorMessages"
              : (response["message"] ?? "⚠️ Registration failed.");
        } else {
          _submissionMessage = response["message"] ?? "⚠️ Registration failed.";
        }
      }
    } on SocketException catch (_) {
      _submissionMessage = "🚫 Unable to connect. Please check your internet connection and try again.";
    } catch (e) {
      _submissionMessage = "❌ Error submitting registration. Please try again.";
      debugPrint("❌ Registration API Error: $e");
    }

    _isSubmitting = false;
    notifyListeners();
  }

  /// Clears verification data
  void clearVerification() {
    notifyListeners();
  }
}
