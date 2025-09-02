import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/controller/kyc_controller.dart';// Import the ProfileController
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // To decode the base64 image data
import 'dart:typed_data';  // For working with binary data
import 'package:flutter/services.dart';

import '../success/DASHBOARD_Y.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // List of all available ID Types
  final List<String> _allIdTypes = ['nin', 'bvn', 'passport-number'];

  // List of available ID Types that are not yet linked in KYC verifications
  List<String> _availableIdTypes = [];

  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? supportDetails;
  String? _selectedIdType;
  String? _selectedWalletIdentifier;
  bool isLoading = true;
  bool _loading = false; // Add this variable to track loading state
  bool _kycRequestLoading = false;

  bool _isCustomEnabled=false;
  final TextEditingController _idValueController = TextEditingController();
  final TextEditingController _transactionPinController = TextEditingController();
// Add this to your State class



  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadCustomEnabler();

    // Add listener for when screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            _loadCachedData();
          }
        });
        FocusScope.of(context).requestFocus(focusNode);
      }
    });
  }


  Future<void> _loadCustomEnabler() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        final menuItems = orgData['data']?['customized_app_displayable_menu_items'];

        setState(() {
          _isCustomEnabled = menuItems?['display-custom-feature-menu'] ?? false;

        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _isCustomEnabled = false;

        });
      }
    }
  }



  Future<void> _loadCachedData() async {
    setState(() => isLoading = true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? profileJson = prefs.getString('userProfileRaw');
    final String? supportJson = prefs.getString('customerSupportDetails');

    // If no cached data exists, fetch fresh data
    if (profileJson == null) {
      await _fetchFreshProfileData();
    } else {
      try {
        final Map<String, dynamic> parsed = json.decode(profileJson);
        final walletData = parsed["getPrimaryWallet"];
        final rawKyc = parsed["first_kyc_verification"];

        Map<String, dynamic>? firstKycVerification;
        if (rawKyc is Map) {
          firstKycVerification = Map<String, dynamic>.from(rawKyc);
        } else if (rawKyc is List && rawKyc.isNotEmpty && rawKyc[0] is Map) {
          firstKycVerification = Map<String, dynamic>.from(rawKyc[0]);
        }

        setState(() {
          userProfile = {
            'id': parsed["id"] ?? '',
            'full_name': parsed["full_name"] ?? '',
            'first_name': parsed["first_name"] ?? '',
            'email': parsed["email"] ?? '',
            'username': parsed["username"] ?? '',
            'telephone': parsed["telephone"] ?? '',
            'gender': parsed["gender"] ?? '',
            'date_of_birth': parsed["date_of_birth"] ?? '',
            'physical_address': parsed["physical_address"] ?? '',
            'should_send_sms': parsed["should_send_sms"] ?? false,
            'job_title': parsed["job_title"] ?? '',
            'profile_image_url': parsed["profile_image_url"],
            'status': parsed["status"]?["label"] ?? 'Unknown',
            'organization': parsed["organization"]?["full_name"] ?? 'Unknown Org',
            'wallet_balance': walletData?["balance"] ?? "0.00",
            'wallet_number': walletData?["wallet_number"] ?? "N/A",
            'wallet_currency': walletData?["currency"]?["code"] ?? "N/A",
            'bank_name': walletData?["bank"]?["name"] ?? "N/A",
            'has_wallet': walletData != null,
            'first_kyc_verification': firstKycVerification ?? {},
            'kyc_image_encoding': firstKycVerification?["imageEncoding"] ?? '',
          };
        });
      } catch (e) {
        debugPrint("❌ Error parsing cached profile: $e");
        await _fetchFreshProfileData();
      }
    }

    // If profile is still null after attempting to load from cache or fetch fresh,
    // make one final attempt to fetch profile data
    if (userProfile == null) {
      await _fetchFreshProfileData();
    }

    // Load support details
    if (supportJson == null) {
      await _fetchFreshSupportDetails();
    } else {
      try {
        final Map<String, dynamic> parsedSupport = json.decode(supportJson);
        setState(() {
          supportDetails = parsedSupport['data'];
        });
      } catch (e) {
        debugPrint("❌ Error parsing cached support details: $e");
        await _fetchFreshSupportDetails();
      }
    }

    // If support details are still null, make one final attempt
    if (supportDetails == null) {
      await _fetchFreshSupportDetails();
    }

    setState(() => isLoading = false);
  }

  // Add new method to fetch fresh profile data
  Future<void> _fetchFreshProfileData() async {
    try {
      final profileData = await ProfileController.fetchUserProfile();
      if (profileData != null) {
        final walletData = profileData["getPrimaryWallet"];
        final rawKyc = profileData["first_kyc_verification"];

        Map<String, dynamic>? firstKycVerification;
        if (rawKyc != null) {
          if (rawKyc is Map<String, dynamic>) {
            firstKycVerification = rawKyc;
          } else if (rawKyc is List && rawKyc.isNotEmpty) {
            // Safe conversion of first item if it exists
            try {
              firstKycVerification = Map<String, dynamic>.from(rawKyc[0]);
            } catch (e) {
              debugPrint("❌ Error converting KYC data: $e");
              firstKycVerification = {};
            }
          } else if (rawKyc is String) {
            // Handle string case - try to parse as JSON if needed
            try {
              final decoded = json.decode(rawKyc);
              if (decoded is Map<String, dynamic>) {
                firstKycVerification = decoded;
              }
            } catch (e) {
              debugPrint("❌ Error parsing KYC string: $e");
              firstKycVerification = {};
            }
          }
        }

        if (mounted) {
          setState(() {
            userProfile = {
              'id': profileData["id"]?.toString() ?? '',
              'full_name': profileData["full_name"]?.toString() ?? '',
              'first_name': profileData["first_name"]?.toString() ?? '',
              'email': profileData["email"]?.toString() ?? '',
              'username': profileData["username"]?.toString() ?? '',
              'telephone': profileData["telephone"]?.toString() ?? '',
              'gender': profileData["gender"]?.toString() ?? '',
              'date_of_birth': profileData["date_of_birth"]?.toString() ?? '',
              'physical_address': profileData["physical_address"]?.toString() ?? '',
              'should_send_sms': profileData["should_send_sms"] ?? false,
              'job_title': profileData["job_title"]?.toString() ?? '',
              'profile_image_url': profileData["profile_image_url"]?.toString(),
              'status': profileData["status"]?["label"]?.toString() ?? 'Unknown',
              'organization': profileData["organization"]?["full_name"]?.toString() ?? 'Unknown Org',
              'wallet_balance': walletData?["balance"]?.toString() ?? "0.00",
              'wallet_number': walletData?["wallet_number"]?.toString() ?? "N/A",
              'wallet_currency': walletData?["currency"]?["code"]?.toString() ?? "N/A",
              'bank_name': walletData?["bank"]?["name"]?.toString() ?? "N/A",
              'has_wallet': walletData != null,
              'first_kyc_verification': firstKycVerification ?? {},
              'kyc_image_encoding': firstKycVerification?["imageEncoding"]?.toString() ?? '',
            };
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching fresh profile data: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  // Add new method to fetch fresh support details
  Future<void> _fetchFreshSupportDetails() async {
    try {
      final supportData = await ProfileController.fetchCustomerSupportDetails();
      if (supportData != null) {
        setState(() {
          supportDetails = supportData['data'];
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching fresh support details: $e");
    }
  }

  ImageProvider _getGenderBasedImage(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return const AssetImage('assets/male.png');
      case 'female':
        return const AssetImage('assets/female.png');
      default:
        return const AssetImage('assets/default_profile.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('My Profile'),
        automaticallyImplyLeading: false, // This removes the back button
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await _fetchFreshProfileData();
              await _fetchFreshSupportDetails();
            },
            child: userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Could not load profile data'),
                      ElevatedButton(
                        onPressed: _loadCachedData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView( // Wrapping the entire content in SingleChildScrollView
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Image & Name
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: userProfile!['first_kyc_verification'] != null &&
                                        userProfile!['first_kyc_verification']['imageEncoding'] != null &&
                                        userProfile!['first_kyc_verification']['imageEncoding'].isNotEmpty
                                        ? MemoryImage(
                                        base64Decode(userProfile!['first_kyc_verification']['imageEncoding']))
                                        : userProfile!['profile_image_url'] != null &&
                                        userProfile!['profile_image_url'].isNotEmpty
                                        ? NetworkImage(userProfile!['profile_image_url'])
                                        : _getGenderBasedImage(userProfile!['gender']),
                                    backgroundColor: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  // Name
                                  Text(
                                    userProfile!['full_name'] ?? "N/A",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Email
                                  Text(
                                    userProfile!['email'] ?? "N/A",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _kycSettingsSection(),
                            const SizedBox(height: 10),
                            // 🟢 Personal Information Section
                            _buildProfileSection("Personal Information", [
                              _buildProfileItem(Icons.person, "Username", userProfile!['username'] ?? "N/A"),
                              _buildProfileItem(Icons.male, "Gender", userProfile!['gender'] ?? "N/A"),
                              _buildProfileItem(Icons.calendar_month, "Date of Birth", userProfile!['date_of_birth'] ?? "N/A"),
                              _buildProfileItem(Icons.home, "Address", userProfile!['physical_address'] ?? "N/A"),

                              /*
                              _buildProfileItem(
                                Icons.chat_bubble,
                                "SMS enabled",
                                userProfile!['should_send_sms'] == true
                                    ? "Enabled"
                                    : userProfile!['should_send_sms'] == false
                                    ? "Disabled"
                                    : "N/A",
                                valueColor: userProfile!['should_send_sms'] == true
                                    ? Colors.green
                                    : userProfile!['should_send_sms'] == false
                                    ? Colors.red
                                    : Colors.grey,
                              ),

                               */
                              _buildProfileItem(Icons.verified, "Account Status", userProfile!['status']),
                            ]),


                            const SizedBox(height: 10),

                            // 🆘 Customer Support Details Section
                            if (supportDetails != null)
                              _buildProfileSection("Customer Support Details", [
                                _buildProfileItem(Icons.business, "Organization", supportDetails!['organization_full_name'] ?? "N/A"),
                            //    _buildProfileItem(Icons.info_outline, "Short Name", supportDetails!['organization_short_name'] ?? "N/A"),
                                _buildProfileItem(Icons.description, "Description", supportDetails!['organization_description'] ?? "N/A"),
                                _buildProfileItem(Icons.language, "Website", supportDetails!['public_existing_website'] ?? "N/A"),

                                if(_isCustomEnabled)
                                    _buildProfileItem(Icons.dialpad, "USSD Code",
                                        supportDetails!['public_ussd_substring'] ??
                                            "N/A"),


                                _buildProfileItem(Icons.email, "Support Email", supportDetails!['official_email'] ?? "N/A"),
                                _buildProfileItem(Icons.phone, "Support Phone", supportDetails!['official_telephone'] ?? "N/A"),
                                if (supportDetails!['support_hours'] != null)
                                  _buildProfileItem(Icons.access_time, "Support Hours", supportDetails!['support_hours']),
                                if (supportDetails!['live_chat_url'] != null)
                                  _buildProfileItem(Icons.chat, "Live Chat", supportDetails!['live_chat_url']),
                                if (supportDetails!['faq_url'] != null)
                                  _buildProfileItem(Icons.help, "FAQ", supportDetails!['faq_url']),
                                if (supportDetails!['address'] != null) ...[
                                  _buildProfileItem(Icons.location_on, "Address", supportDetails!['address']['physical_address'] ?? "N/A"),
                                  _buildProfileItem(Icons.public, "Country", supportDetails!['address']['country'] ?? "N/A"),
                                ],
                                // Social Media Links (if available)
                                if (supportDetails!['social_media'] != null) ...[
                                  if (supportDetails!['social_media']['twitter'] != null)
                                    _buildProfileItem(Icons.alternate_email, "Twitter", supportDetails!['social_media']['twitter']),
                                  if (supportDetails!['social_media']['facebook'] != null)
                                    _buildProfileItem(Icons.facebook, "Facebook", supportDetails!['social_media']['facebook']),
                                  if (supportDetails!['social_media']['instagram'] != null)
                                    _buildProfileItem(Icons.camera_alt, "Instagram", supportDetails!['social_media']['instagram']),
                                ],
                            ]),

                            const SizedBox(height: 10),
                            const SizedBox(height: 30),
                            // 🛠️ Change Settings Section (Change Password & Change PIN)
                            _buildSettingsSection(),
                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 3,
                              ),
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text(
                                "Logout",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              onPressed: () async {
                                final SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.remove('auth_token');
                                await WalletDataCache.clearCache();
                                // Clear stored auth token
                                // Navigate back to the login screen and remove previous routes
                                if (!mounted) return;
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
    );
  }

  // 🏷️ Profile Section Widget (for grouping)
  Widget _buildProfileSection(String title, List<Widget> items) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            Column(children: items), // Ensure children fit properly
          ],
        ),
      ),
    );
  }

  // 📌 Individual Profile Item Widget
  Widget _buildProfileItem(
      IconData icon,
      String label,
      String value, {
        Color valueColor = Colors.black87, // default color
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 14, color: valueColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }


  // 🛠️ Settings Section: Change Password and Change PIN
  Widget _buildSettingsSection() {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: KycVerificationController.fetchKycVerifications(),
      builder: (context, snapshot) {
        final kycData = snapshot.data ?? [];

        // Extract all completed document types in uppercase
        final completedTypes = kycData
            .map((e) => (e['documentType'] as String).toUpperCase())
            .toSet();

        final bool isKycComplete = completedTypes.containsAll({'BVN', 'NIN'});

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordDialog,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                ListTile(
                  leading: const Icon(Icons.pin, color: Colors.blue),
                  title: const Text('Change PIN', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kycSettingsSection() {
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: _loadKycData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final kycData = snapshot.data ?? [];

        // Extract all completed document types in uppercase
        final completedTypes = kycData
            .map((e) => (e['documentType'] as String?)?.toUpperCase())
            .whereType<String>()
            .toSet();

        final bool isKycComplete = completedTypes.containsAll({'BVN', 'NIN'});

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KYC Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Divider(),
                Stack(
                  children: [
                    ListTile(
                      leading: Icon(
                        isKycComplete ? Icons.check_circle : Icons.link,
                        color: isKycComplete ? Colors.green : Colors.blue,
                      ),
                      title: Text(
                        isKycComplete ? 'KYC Completed' : 'Link KYC',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: _kycRequestLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.chevron_right),
                      onTap: isKycComplete
                          ? null
                          : () async {
                        if (!mounted) return;
                        setState(() {
                          _kycRequestLoading = true;
                        });

                        final profileData = await ProfileController.fetchUserProfile();
                        final walletsData = await ProfileController.fetchWallets();

                        if (!mounted) return;
                        setState(() {
                          _kycRequestLoading = false;
                        });

                        if (profileData != null) {
                          // Check if wallets exist
                          List<Map<String, dynamic>> walletList = [];
                          bool hasWallet = false;

                          if (walletsData?['data'] is List) {
                            walletList = List<Map<String, dynamic>>.from(walletsData['data']);
                            hasWallet = walletList.isNotEmpty;
                          }

                          _showLinkKycDialog(
                            Map<String, dynamic>.from(profileData),
                            walletList,
                            hasWallet,
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to load profile data')),
                          );
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLinkKycDialog(Map<String, dynamic> profileData, List<Map<String, dynamic>> walletList, bool hasWallet) async {
    final response = await KycVerificationController.fetchKycVerifications();
    final kycVerifications = response;

    final List<String> allIdTypes = ['nin', 'bvn', 'passport-number'];
    List<String> availableIdTypes = [];

    if (kycVerifications == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to retrieve KYC verifications')),
      );
      return;
    }

    // Show all types if empty or null data
    if (kycVerifications.isEmpty) {
      availableIdTypes = allIdTypes;
    } else {
      final List<String> usedTypes = kycVerifications
          .map((e) => (e['documentType'] as String).toUpperCase())
          .toList();

      if (usedTypes.contains('NIN') && usedTypes.contains('BVN')) {
        availableIdTypes = ['passport-number'];
      } else {
        availableIdTypes = allIdTypes
            .where((id) => !usedTypes.contains(id.toUpperCase()))
            .toList();
      }
    }

    // Ensure _selectedIdType is a valid option, otherwise reset to null
    if (!availableIdTypes.contains(_selectedIdType)) {
      _selectedIdType = null;
    }

    // Get user ID from profile data
    final userId = profileData['id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    // Reset form controllers
    _idValueController.clear();
    _transactionPinController.clear();
    _selectedIdType = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Link KYC Identity ID",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ID Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedIdType,
                        decoration: const InputDecoration(
                          labelText: 'ID Type',
                          border: OutlineInputBorder(),
                        ),
                        items: availableIdTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedIdType = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // ID Value Field
                      TextField(
                        controller: _idValueController,
                        decoration: const InputDecoration(
                          labelText: 'ID Value',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Transaction PIN Field
                      TextField(
                        controller: _transactionPinController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction PIN',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _loading
                              ? null
                              : () async {
                            if (_selectedIdType == null ||
                                _idValueController.text.isEmpty ||
                                _transactionPinController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in all fields')),
                              );
                              return;
                            }

                            if (_transactionPinController.text.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction PIN must be 4 digits')),
                              );
                              return;
                            }

                            setState(() {
                              _loading = true;
                            });

                            try {
                              final result = await KycVerificationController.verifyKycWithUserId(
                                userId: userId,
                                idType: _selectedIdType!,
                                idValue: _idValueController.text,
                                transactionPin: _transactionPinController.text,
                              );

                              if (!mounted) return;

                              if (result != null) {
                                // Clear form fields
                                _idValueController.clear();
                                _transactionPinController.clear();
                                _selectedIdType = null;

                                Navigator.of(context).pop(); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('KYC verification successful')),
                                );
                                // Refresh the profile page
                                _loadCachedData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('KYC verification failed')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _loading = false;
                                });
                              }
                            }
                          },
                          child: _loading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ); // Added this closing parenthesis and semicolon
  }

  // Load KYC data with fallback to cache
  Future<List<Map<String, dynamic>>?> _loadKycData() async {
    try {
      // First try to get cached data
      final cachedData = await _loadCachedKycData();
      if (cachedData != null && cachedData.isNotEmpty) {
        return cachedData;
      }

      // If no cached data, fetch fresh data
      final response = await KycVerificationController.fetchKycVerifications();
      if (response != null) {
        // Cache the new data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_kyc_data', json.encode(response));
        return response;
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error loading KYC data: $e");
      return [];
    }
  }

  // Helper method for cached KYC data
  Future<List<Map<String, dynamic>>?> _loadCachedKycData() async {
    final prefs = await SharedPreferences.getInstance();
    final kycString = prefs.getString('cached_kyc_data');

    if (kycString != null) {
      try {
        final decoded = json.decode(kycString);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error decoding cached KYC data: $e');
      }
    }
    return [];
  }

  // Show Link KYC Dialog
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  // Show Change Password Dialog
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController newPasswordConfirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Title
                  Center(
                    child: Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Password
                  _buildPasswordField(
                    label: 'Current Password',
                    controller: currentPasswordController,
                    obscureText: true,
                  ),

                  // New Password
                  _buildPasswordField(
                    label: 'New Password',
                    controller: newPasswordController,
                    obscureText: true,
                  ),

                  // Confirm New Password
                  _buildPasswordField(
                    label: 'Confirm New Password',
                    controller: newPasswordConfirmationController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Change Button
                      ElevatedButton(
                        onPressed: () async {
                          String currentPassword = currentPasswordController.text;
                          String newPassword = newPasswordController.text;
                          String newPasswordConfirmation = newPasswordConfirmationController.text;

                          if (currentPassword.isEmpty || newPassword.isEmpty || newPasswordConfirmation.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          if (newPassword != newPasswordConfirmation) {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (BuildContext context2) {
                                return AlertDialog(
                                  title: Text('Something went wrong'),
                                  content: Text("Passwords do not match"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context2).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          String result = await ProfileController.changePassword(
                            currentPassword,
                            newPassword,
                            newPasswordConfirmation,
                          );

                          if (result == "Password changed successfully") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password changed successfully")),
                            );

                            // Redirect after successful change
                            Future.delayed(const Duration(seconds: 2), () {
                              // Clear session
                              SharedPreferences.getInstance().then((prefs) {
                                prefs.remove('auth_token');
                              });

                              // Redirect to login page
                              if (!mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            });
                          } else {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (BuildContext context2) {
                                return AlertDialog(
                                  title: Text('Something went wrong'),
                                  content: Text(result),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context2).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }

                         // Navigator.of(context).pop(); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,  // Set the text color to white
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for Password Fields
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  // Show Change PIN Dialog
  void _showChangePinDialog() {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Change Transaction PIN",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current PIN
                  _buildPasswordField(
                    label: 'Current PIN',
                    controller: currentPinController,
                    obscureText: true,
                  ),

                  // New PIN
                  _buildPasswordField(
                    label: 'New PIN',
                    controller: newPinController,
                    obscureText: true,
                  ),

                  // Confirm New PIN
                  _buildPasswordField(
                    label: 'Confirm New PIN',
                    controller: confirmPinController,
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Change Button
                      ElevatedButton(
                        onPressed: () async {
                          String currentPin = currentPinController.text;
                          String newPin = newPinController.text;
                          String confirmPin = confirmPinController.text;

                          if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          if (newPin != confirmPin) {
                            Navigator.of(context).pop();

                            showDialog(
                              context: context,
                              builder: (BuildContext context2) {
                                return AlertDialog(
                                  title: Text('Something went wrong'),
                                  content: Text("Pins do not match"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context2).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          String result = await ProfileController.changeTransactionPin(
                            currentPin,
                            newPin,
                            confirmPin
                          );

                          if (result == "Transaction PIN changed successfully") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Transaction PIN changed successfully")),
                            );

                            // Optionally clear session or navigate based on requirements
                          } else {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (BuildContext context2) {
                                return AlertDialog(
                                  title: Text('Something went wrong'),
                                  content: Text("Passwords do not match"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context2).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                          }

                       //   Navigator.of(context).pop(); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}