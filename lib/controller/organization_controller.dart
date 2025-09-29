import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class OrganizationController extends ChangeNotifier {
  Map<String, dynamic>? organizationData;
  Map<String, dynamic>? appSettingsData;
  Map<String, dynamic>? supportDetails;

  bool isLoading = false;

  String? appId;

  OrganizationController();

  /// Fetch Organization Data and save to SharedPreferences if it's different from the cached response
  Future<void> fetchOrganizationData() async {
    isLoading = true;
    notifyListeners();

    const String url = 'https://app.gobeller.com/api/v1/organizations/0053';

   // const String url = 'https://paysorta.matrixbanking.co/api/v1/organizations/0053';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final fullResponse = jsonDecode(response.body);

        debugPrint("✅ Full Org Response: ${jsonEncode(fullResponse)}");

        final prefs = await SharedPreferences.getInstance();

        // Always extract App ID even if data is unchanged
        appId = fullResponse?['data']?['id'];
        if (appId != null) {
          await prefs.setString('appId', appId!);
        }

        // Only update SharedPreferences if the data has changed
        if (!_isEqual(organizationData, fullResponse)) {
          organizationData = fullResponse;
          await prefs.setString('organizationData', jsonEncode(organizationData));

          // Proceed to fetch settings only if data has changed
          await fetchAppSettings();
        }
      } else {
        debugPrint("❌ Failed to load organization. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching organization: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Fetch App Settings and save to SharedPreferences if it's different from the cached response
  Future<void> fetchAppSettings() async {
    if (appId == null) {
      debugPrint("❌ AppID is null. Cannot fetch settings.");
      return;
    }

    isLoading = true;
    notifyListeners();

    const String url = 'https://app.gobeller.cc/api/v1/customized-app-api/public-app/settings';


  //  const String url = 'https://paysorta.matrixbanking.co/api/v1/customized-app-api/public-app/settings';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'AppID': appId!,
        },
      );

      if (response.statusCode == 200) {
        final newAppSettingsData = jsonDecode(response.body);
        debugPrint("✅ App Settings Data: ${jsonEncode(newAppSettingsData)}");

        if (!_isEqual(appSettingsData, newAppSettingsData)) {
          appSettingsData = newAppSettingsData;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appSettingsData', jsonEncode(appSettingsData));

          String? iconUrl = appSettingsData?['data']['iconUrl'];

          if (iconUrl != null) {
            await downloadAndSaveIcon(iconUrl);
          }
        }
      } else {
        debugPrint("❌ Failed to load settings. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching app settings: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// Download and save the icon locally
  Future<void> downloadAndSaveIcon(String iconUrl) async {
    try {
      final response = await http.get(Uri.parse(iconUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/app_icon.png';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        debugPrint("✅ Icon saved to: $filePath");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appIconPath', filePath);

        setAppIcon(filePath);
      } else {
        debugPrint("❌ Failed to download icon. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error downloading icon: $e");
    }
  }

  /// Set the app icon path to be used in the UI
  Future<void> setAppIcon(String filePath) async {
    notifyListeners(); // You might add logic here if needed
  }

  /// Fetch support details
  Future<void> fetchSupportDetails() async {
    if (appId == null) {
      debugPrint("❌ AppID is null. Cannot fetch support details.");
      return;
    }

    final String url = 'https://app.gobeller.cc/api/v1/organizations/customer-support-details/$appId';

  //  final String url = 'https://paysorta.matrixbanking.co/api/v1/organizations/customer-support-details/$appId';

    try {
      final response = await http.get(Uri.parse(url));

      debugPrint("🔍 Support Details Raw Response Status: ${response.statusCode}");
      debugPrint("🔍 Support Details Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final fullSupportResponse = jsonDecode(response.body);

        supportDetails = fullSupportResponse;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerSupportDetails', jsonEncode(fullSupportResponse));

        debugPrint("✅ Support details saved to SharedPreferences: ${jsonEncode(fullSupportResponse)}");

        if (fullSupportResponse['data'] != null) {
          final data = fullSupportResponse['data'];
          debugPrint("📋 Support Details Breakdown:");
          debugPrint("   - Organization: ${data['organization_full_name'] ?? 'N/A'}");
          debugPrint("   - Email: ${data['official_email'] ?? 'N/A'}");
          debugPrint("   - Phone: ${data['official_telephone'] ?? 'N/A'}");
          debugPrint("   - Website: ${data['public_existing_website'] ?? 'N/A'}");
          debugPrint("   - Address: ${data['address']?['physical_address'] ?? 'N/A'}");
          debugPrint("   - Country: ${data['address']?['country'] ?? 'N/A'}");
        }

        notifyListeners();
      } else {
        debugPrint("❌ Failed to load support details. Status: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching support details: $e");
      debugPrint("❌ Stack trace: ${StackTrace.current}");
    }
  }

  /// Load cached data from SharedPreferences (optional)
  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final orgJson = prefs.getString('organizationData');
    final settingsJson = prefs.getString('appSettingsData');
    final supportJson = prefs.getString('customerSupportDetails');
    final iconPath = prefs.getString('appIconPath');
    final cachedAppId = prefs.getString('appId');

    if (orgJson != null) {
      organizationData = jsonDecode(orgJson);
      debugPrint("📱 Loaded cached organization data");
    }

    if (settingsJson != null) {
      appSettingsData = jsonDecode(settingsJson);
      debugPrint("📱 Loaded cached app settings data");
    }

    if (supportJson != null) {
      supportDetails = jsonDecode(supportJson);
      debugPrint("📱 Loaded cached support details: ${jsonEncode(supportDetails)}");
    }

    if (iconPath != null) {
      setAppIcon(iconPath);
      debugPrint("📱 Loaded cached icon path: $iconPath");
    }

    if (cachedAppId != null) {
      appId = cachedAppId;
      debugPrint("📱 Loaded cached AppID: $appId");
    }

    notifyListeners();
  }

  /// Helper function to compare two JSON objects (Maps) for equality
  bool _isEqual(Map<String, dynamic>? oldData, Map<String, dynamic>? newData) {
    if (oldData == null || newData == null) return false;
    return jsonEncode(oldData) == jsonEncode(newData);
  }
}
