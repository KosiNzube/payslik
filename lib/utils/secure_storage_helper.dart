import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure SharedPreferences is initialized
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> storeItem({required String key, required String value}) async {
    try {
      final prefs = await _instance;
      await prefs.setString(key, value);
      print("Value saved successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<String?> retrieveItem({required String key}) async {
    try {
      final prefs = await _instance;
      return prefs.getString(key);
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> deleteItem({required String key}) async {
    try {
      final prefs = await _instance;
      await prefs.remove(key);
      print("Item with key '$key' deleted successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await _instance;
      await prefs.clear();
      print("All items cleared successfully");
    } catch (e) {
      print(e);
    }
  }

  // Additional helper methods for different data types
  static Future<void> storeBool({required String key, required bool value}) async {
    try {
      final prefs = await _instance;
      await prefs.setBool(key, value);
      print("Boolean value saved successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<bool?> retrieveBool({required String key}) async {
    try {
      final prefs = await _instance;
      return prefs.getBool(key);
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> storeInt({required String key, required int value}) async {
    try {
      final prefs = await _instance;
      await prefs.setInt(key, value);
      print("Integer value saved successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<int?> retrieveInt({required String key}) async {
    try {
      final prefs = await _instance;
      return prefs.getInt(key);
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> storeDouble({required String key, required double value}) async {
    try {
      final prefs = await _instance;
      await prefs.setDouble(key, value);
      print("Double value saved successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<double?> retrieveDouble({required String key}) async {
    try {
      final prefs = await _instance;
      return prefs.getDouble(key);
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> storeStringList({required String key, required List<String> value}) async {
    try {
      final prefs = await _instance;
      await prefs.setStringList(key, value);
      print("String list saved successfully");
    } catch (e) {
      print(e);
    }
  }

  static Future<List<String>?> retrieveStringList({required String key}) async {
    try {
      final prefs = await _instance;
      return prefs.getStringList(key);
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Helper method to store objects as JSON
  static Future<void> storeObject({required String key, required Map<String, dynamic> value}) async {
    try {
      final jsonString = jsonEncode(value);
      await storeItem(key: key, value: jsonString);
    } catch (e) {
      print(e);
    }
  }

  // Helper method to retrieve objects from JSON
  static Future<Map<String, dynamic>?> retrieveObject({required String key}) async {
    try {
      final jsonString = await retrieveItem(key: key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}