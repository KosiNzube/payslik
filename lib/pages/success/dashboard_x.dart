import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/quick_actions_list.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/success/widget/bottom_nav_bar.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>?> _userProfileFuture;

  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;

  String? _logoUrl;
  String _welcomeTitle = "Dashboard";
  String _welcomeDescription = "We are here to help you achieve your goals.";

  List<Map<String, dynamic>> _ads = [];

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

        if (mounted) {
          setState(() {
            _ads = adsList;
          });
        }
      } else {
        debugPrint("📭 No ads found in profile data.");
      }
    } else {
      debugPrint("⚠️ userProfileRaw not found in SharedPreferences.");
    }
  }


  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    // Logic to log out the user (e.g., clear user session, navigate to login)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        Widget bodyContent;
        String appBarTitle = '';
        String abbrevation = '';


        if (snapshot.connectionState == ConnectionState.waiting) {
          bodyContent = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {

            PersistentNavBarNavigator .pushNewScreen(
              context,
              screen: LoginPage(),
              withNavBar: false,
            );



          });
          bodyContent = const Center(child: Text("Redirecting to login..."));
          appBarTitle = '';
          abbrevation = '';


        } else {
          var userProfile = snapshot.data!;
          String fullName = userProfile["first_name"] ?? "User";
          String accountNumber = userProfile["wallet_number"] ?? "";
          String balance = userProfile["wallet_balance"]?.toString() ?? "0";
          String bankName = userProfile["bank_name"] ?? "N/A";
          String bankCode = userProfile["bank_code"] ?? "N/A";
          String wallet_number = userProfile["wallet_number"] ?? "N/A";
          String wallet_currency = userProfile["wallet_currency"] ?? "N/A";
          String symbol = userProfile["symbol"] ?? "N/A";



          bool hasWallet = balance.isNotEmpty &&
              balance != "0.00" &&
              accountNumber.isNotEmpty &&
              accountNumber != "N/A" &&
              bankName.isNotEmpty &&
              bankName != "N/A";

          appBarTitle = 'Hi, $fullName';
          abbrevation= fullName.length >= 2 ? fullName.substring(0, 2) : fullName;

          bodyContent = SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  UserInfoCard(
                    username: fullName,
                    accountNumber: accountNumber,
                    balance: balance,
                    wallet_number:wallet_number,
                    wallet_currency:wallet_currency,
                    symbol:symbol,
                    bankName: bankName,
                    bankCode:bankCode,
                    hasWallet: hasWallet,
                  ),




                  const SizedBox(height: 24),
                  const QuickActionsList(),
                  const SizedBox(height: 24),
                  const TransactionList(),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar:AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title:  Text(
              appBarTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2D5A),
              ),
            ),
            centerTitle: false,
            actions: [
              abbrevation.length>0?  InkWell(
                onTap:(){
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: RouteSettings(name: '/profile'),
                    screen: ProfilePage(),
                    withNavBar: true,
                  );
                },

                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE5FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:  Center(
                    child: Text(
                      abbrevation,
                      style: TextStyle(
                        color: Color(0xFF8A56AC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ):Container(),
            ],
            // Match system status bar height
            toolbarHeight: 60,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),

          body: bodyContent,
        );
      },
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
  final PageController _controller = PageController(viewportFraction: 1.0);  // Full-width PageView
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
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
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 250,  // Increased height for full-width display
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
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      Expanded( // NEW: ensures no overflow if text height increases
                        child: Text(
                          ad['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == index ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
