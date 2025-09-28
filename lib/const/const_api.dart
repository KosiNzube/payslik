import 'package:shared_preferences/shared_preferences.dart';

class ConstApi {
 // static const String baseUrl = 'https://app.gobeller.cc';
  static const String baseUrl = 'https://paysorta.matrixbanking.co';
  static const String basePath = '/api/v1';

  /// Dynamically get headers with AppID from SharedPreferences
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString('appId') ?? '';

    return {
      'AppID': appId,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}
