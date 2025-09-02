import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserController {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    debugPrint("🔐 [UserController] Retrieved token: $token");
    return token;
  }
}

// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:gobeller/utils/api_service.dart';
//
// class UserController {
//   // Instance of Secure Storage
//   static final _secureStorage = FlutterSecureStorage();
//
//   // Handle user login
//   static Future<String> attemptAuthentication(String username, String password) async {
//     try {
//       final response = await ApiService.postRequest("/login", {
//         "username": username,
//         "password": password,
//       });
//
//       debugPrint("🔹 Login API Response: $response");
//
//       if (response["status"] == true) {
//         final String token = response["data"]["token"];
//         final SharedPreferences prefs = await SharedPreferences.getInstance();
//
//         // Remove existing token before saving new one
//         await prefs.remove('auth_token');
//         await prefs.setString('auth_token', token);
//
//         // Also store the token securely
//         await _secureStorage.write(key: 'auth_token', value: token);
//
//         // Remove and replace user data
//         await prefs.remove('user');
//         final String userData = json.encode(response["data"]["profile"]);
//         await prefs.setString('user', userData);
//
//         return "Successfully logged in";
//       } else {
//         final message = response["message"]?.toString().toLowerCase() ?? "";
//
//         if (message.contains("422")) {
//           return "Invalid username or password. Please try again.";
//         } else if (message.contains("invalid") || message.contains("unauthorized")) {
//           return "Incorrect credentials. Double-check your info and try again.";
//         } else {
//           return response["message"] ?? "Login failed. Please try again.";
//         }
//       }
//     } on FormatException {
//       return "Unexpected response format. Please try again later.";
//     } on Exception catch (e) {
//       debugPrint("❌ Login API Error: $e");
//
//       final error = e.toString().toLowerCase();
//
//       if (error.contains("socketexception") || error.contains("failed host lookup")) {
//         return "Unable to connect to our servers. Please check your internet connection and try again.";
//       } else if (error.contains("clientexception")) {
//         return "Could not reach the server. It might be down or unreachable right now.";
//       } else {
//         return "Something went wrong. Please try again shortly.";
//       }
//     }
//   }
//
//   // Logout user
//   static Future<bool> logoutAuthenticatedUser() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.clear();  // Clear all stored data including the token
//     await _secureStorage.delete(key: 'auth_token'); // Remove token from Secure Storage
//     return true;
//   }
//
//   // Get user data from local storage
//   static Future<Map<String, dynamic>> getUserData() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? userData = prefs.getString('user');
//     return userData != null ? json.decode(userData) : {};
//   }
//
//   // Get user's full name
//   static Future<String> getFullName() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('first_name') ?? "User";
//   }
//
//   // Get token from local storage (SharedPreferences and Secure Storage)
//   static Future<String?> getToken() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? token = prefs.getString('auth_token');  // Retrieve the token from SharedPreferences
//
//     // Print the token if it's found in SharedPreferences
//     if (token != null) {
//       debugPrint("🔑 Token from SharedPreferences: $token");
//       return token;
//     }
//
//     // If token is not in SharedPreferences, check in Secure Storage
//     final secureToken = await _secureStorage.read(key: 'auth_token');
//
//     // Print the token if it's found in Secure Storage
//     if (secureToken != null) {
//       debugPrint("🔑 Token from Secure Storage: $secureToken");
//       return secureToken;
//     }
//
//     return null; // If no token is found
//   }
// }
