// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:gobeller/utils/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class WalletInfoController with ChangeNotifier {
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;
//
//   Map<String, dynamic> _walletInfo = {};
//   Map<String, dynamic> get walletInfo => _walletInfo;
//
//   String _errorMessage = '';
//   String get errorMessage => _errorMessage;
//
//   // Fetch detailed wallet information from the API
//   Future<void> fetchWalletInfo() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final SharedPreferences prefs = await SharedPreferences.getInstance();
//       final String? token = prefs.getString('auth_token');
//
//       if (token == null) {
//         _errorMessage = "❌ No authentication token found. Please login again.";
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }
//
//       final extraHeaders = {
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await ApiService.getRequest(
//         "/customers/wallets",
//         extraHeaders: extraHeaders,
//       );
//
//       debugPrint("🔹 Wallet Info API Response: $response");
//
//       if (response["status"] == true) {
//         List<dynamic> walletList = response["data"]["data"];
//
//         if (walletList.isNotEmpty) {
//           var wallet = walletList[0]; // Assuming the first wallet is the primary one
//
//           _walletInfo = {
//             'id': wallet['id'],
//             'wallet_number': wallet['wallet_number'],
//             'balance': wallet['balance'],
//             'currency': wallet['currency']?['code'] ?? 'N/A',
//             'symbol': wallet['currency']?['symbol'] ?? '',
//             'status_label': wallet['status']?['label'] ?? 'Unknown',
//             'bank_name': wallet['bank']?['name'] ?? 'No Bank Linked',
//             'created_at': wallet['created_at'],
//           };
//           _errorMessage = ''; // Reset any previous error
//         } else {
//           _walletInfo = {}; // No wallet found, clear wallet data
//           _errorMessage = 'ℹ️ No wallet info available.';
//         }
//       } else {
//         _errorMessage = "❌ Error fetching wallet info: ${response["message"]}";
//         _walletInfo = {}; // Reset wallet info if error occurs
//       }
//     } catch (e) {
//       _errorMessage = "❌ Wallet Info API Exception: $e";
//       _walletInfo = {}; // Reset wallet info on exception
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
