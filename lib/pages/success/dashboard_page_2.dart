import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>?> _userProfileFuture;

  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  bool _showBanner = false;

  String? _logoUrl;
  String _welcomeTitle = "Dashboard";
  String _welcomeDescription = "We are here to help you achieve your goals.";

  List<Map<String, dynamic>> _ads = [];
  Map<String, dynamic> _menuItems = {};

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
    _userProfileFuture = ProfileController.fetchUserProfile().then((profile) {
      _loadAdsFromPrefs();
      return profile;
    });
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final tertiaryColorHex = data['customized-app-tertiary-color'];
      final logoUrl = data['customized-app-logo-url'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _tertiaryColor = tertiaryColorHex != null
            ? Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')))
            : Colors.grey[200];
        _logoUrl = logoUrl;
      });
    }


    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};

      _menuItems = {
        ...?orgData['data']?['customized_app_displayable_menu_items'],
        // "display-corporate-account-menu": true,
        // "display-loan-menu": true,
        // "display-fx-menu": true,
      };

      setState(() {
        _welcomeTitle = "Welcome to ${data['short_name']} ";
        _welcomeDescription = data['description'] ?? _welcomeDescription;
      });
    }
  }

  Future<void> _loadAdsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('userProfileRaw');

    if (rawJson != null) {
      final profileData = json.decode(rawJson);
      final adsMap = profileData['ads'] as Map<String, dynamic>?;

      if (adsMap != null) {
        final adsList = adsMap.entries.map((entry) {
          final ad = entry.value;
          final bannerUrl = ad['banner_url'];

          debugPrint("🖼️ Loaded ad banner_url: $bannerUrl");

          return {
            'subject': ad['subject'],
            'content': ad['content'],
            'banner_url': bannerUrl,
            'content_redirect_url': ad['content_redirect_url'],
          };
        }).toList();

        // Check for banner display flag
        final bannerEnabled = _menuItems['display-banner'] ?? false;

        if (mounted) {
          setState(() {
            _ads = adsList;
            _showBanner = bannerEnabled;
          });
        }
      } else {
        debugPrint("📭 No ads found in profile data.");
      }
    } else {
      debugPrint("⚠️ userProfileRaw not found in SharedPreferences.");
    }
  }

  void _logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _logout2() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tertiaryColor ?? Colors.grey[200],
      appBar: AppBar(
        title: Text(_welcomeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BaseLayout(initialIndex: 4),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            final error = snapshot.error.toString();
            if (error.contains('401') || error.contains('unauthorized')) {
              // Only redirect to login for auth errors
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              });
            }
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24.0),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Error loading profile",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We're unable to retrieve your profile. Please log out and sign in again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 5,


                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _logout2();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _secondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Log out",style: TextStyle(color: Colors.white),),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _userProfileFuture = ProfileController.fetchUserProfile().then((profile) {
                                _loadAdsFromPrefs();
                                return profile;
                              });
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,

                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Refresh",style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            );
          }

          var userProfile = snapshot.data!;
          String fullName = userProfile["first_name"] ?? "User";
          String accountNumber = userProfile["wallet_number"] ?? "";
          String balance = userProfile["wallet_balance"]?.toString() ?? "0";
          String bankName = userProfile["bank_name"] ?? "N/A";

          bool hasWallet = balance.isNotEmpty &&
              balance != "0.00" &&
              accountNumber.isNotEmpty &&
              accountNumber != "N/A" &&
              bankName.isNotEmpty &&
              bankName != "N/A";

          return Center(
            child: Container(
              margin: const EdgeInsets.all(24.0),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,

                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Error loading profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We're unable to retrieve your profile. Please log out and sign in again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5,


                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _logout2();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Log out",style: TextStyle(color: Colors.white),),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _userProfileFuture = ProfileController.fetchUserProfile().then((profile) {
                              _loadAdsFromPrefs();
                              return profile;
                            });
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,

                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Refresh",style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          );
          },
      ),
    );
  }
}

class AdCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> ads;

  const AdCarousel({super.key, required this.ads});

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    if (widget.ads.isNotEmpty) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_controller.hasClients && widget.ads.isNotEmpty) {
        int nextPage = (_currentIndex + 1) % widget.ads.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    if (widget.ads.isNotEmpty) {
      _timer.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no ads, return an empty widget with no height
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate adaptive heights based on screen width
        final double screenWidth = constraints.maxWidth;
        final double imageHeight = screenWidth * 0.4; // 40% of width for image
        final double contentHeight = 80.0; // Fixed height for text content
        final double totalHeight = imageHeight + contentHeight;

        return Column(
          mainAxisSize: MainAxisSize.min, // Only take up needed space
          children: [
            SizedBox(
              height: totalHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.ads.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final ad = widget.ads[index];
                  return GestureDetector(
                    onTap: () {
                      final url = ad['content_redirect_url'];
                      debugPrint("🔗 Redirect to: $url");
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ad['banner_url'],
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  SizedBox(
                                    height: imageHeight,
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ad['subject'] ?? 'Ad Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ad['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Only show indicators if there are multiple ads
            if (widget.ads.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.ads.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentIndex == index ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.blueAccent
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}