import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller/WalletController.dart';

final List<Color> walletColors = [
  // First color will be your primary color, others are variations
  const Color(0xFF6C5CE7), // Purple
  const Color(0xFF00B894), // Green
  const Color(0xFFE17055), // Orange
  const Color(0xFF0984E3), // Blue
  const Color(0xFFE84393), // Pink
  const Color(0xFF00CEC9), // Teal
  const Color(0xFFFD79A8), // Rose
  const Color(0xFF6C5CE7), // Purple (repeat for more wallets)
];

class DashboardPageMain extends StatefulWidget {
  const DashboardPageMain({super.key});

  @override
  State<DashboardPageMain> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPageMain> {
  late Future<Map<String, dynamic>?> _userProfileFuture;
  int _currentCardIndex = 0;
  int _selectedIndex = 0;
  bool _isBalanceHidden = true;
  bool _alreadyOpen = false;

  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  String _currentBalance="---";
  String _currentName="---";
  String _currentWalletNumber="---";
  String? _currentBankName="---";
  bool isWalletsLoading = false;
  List<Map<String, dynamic>> wallets = [];
  bool hasError = false;

  bool _currentHasWallet=false;
  String _currentCurrencySymbol="---";
  String? _logoUrl;
  String errorMessage = "We are unable to retrieve your profile. Please log out and sign in again.";
  PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;
  final Color _defaultPrimaryColor = const Color(0xFF2BBBA4);
  final Color _defaultSecondaryColor = const Color(0xFFFF9800);
  final Color _defaultTertiaryColor = const Color(0xFFF5F5F5);
  String _welcomeTitle = "DASHBOARD";
  String _welcomeDescription = "We are here to help you achieve your goals.";
  Map<String, dynamic> _menuItems = {};
  bool _showBanner = false;
  List<Map<String, dynamic>> _ads = [];
  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];
          final tertiaryColorHex = data['customized-app-tertiary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : null; // Changed to null instead of default

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : _defaultSecondaryColor;

          _tertiaryColor = tertiaryColorHex != null
              ? Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')))
              : _defaultTertiaryColor;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {
        // If there's an error parsing, use default colors
        setState(() {
          _primaryColor = null; // Changed to null instead of default
          _secondaryColor = _defaultSecondaryColor;
          _tertiaryColor = _defaultTertiaryColor;
        });
      }
    }
  }

  void _updateLocalData(Map<String, dynamic> profile) {

    _currentName = "${profile['first_name']} ${profile['last_name']}";

    _currentBalance = profile['wallet_balance'].toString();
    _currentWalletNumber = profile['wallet_number'];
    _currentBankName = profile['bank_name']??'N/A';
    _currentHasWallet = profile['has_wallet'];
    _currentCurrencySymbol = profile['getPrimaryWallet']?['currency']?['symbol'] ?? '₦';


  }




  Future<void> _loadWallets() async {
    if (!mounted) return;

    setState(() => isWalletsLoading = true);

    try {
      final walletData = await WalletController.fetchWallets();

      debugPrint("\n\n\n🧾🧾🧾🧾🧾🧾🧾🧾🧾🧾 Full wallet data: ${walletData.toString()}\n\n############################################################################375756756565667");


      if (!mounted) return;

      // Check if we got valid data
      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];

        if (data is List) {
          final processedWallets = data.map((wallet) {
            return {
              "type": wallet["ownership_type"] ?? "Normal wallet",
              "name": wallet["ownership_label"]?.toString() ?? "Wallet", // Use ownership_label instead
              "wallet_number": wallet["wallet_number"] ?? "N/A",
              "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
              "currency": wallet["currency"]?["symbol"] ?? "₦",
              "bank_name": wallet["bank"] is Map && wallet["bank"]?["name"] != null
                  ? wallet["bank"]["name"]
                  : wallet["bank"] is List
                  ? wallet["ownership_label"]?.toString()
                  : wallet["ownership_label"]?.toString() ?? "---",
              "bank_code": "N/A", // Hardcode since bank data is null

            };
          }).toList();

          setState(() {
            wallets = List<Map<String, dynamic>>.from(processedWallets.reversed);
            hasError = false;
          });

          debugPrint("✅ Successfully loaded ${wallets.length} wallets");
        } else {
          debugPrint("⚠️ Data is not a list: ${data.runtimeType}");
          setState(() {
            wallets = [];
            hasError = false; // Don't show error for empty list
          });
        }
      } else {
        debugPrint("⚠️ No wallet data received or data key missing");
        setState(() {
          wallets = [];
          hasError = false; // Don't show error for empty response
        });
      }


    } catch (e) {
      if (!mounted) return;

      debugPrint("❌ Error loading wallets: $e");
      setState(() {
        hasError = true;
        wallets = [];
      });

      // Show user-friendly error message
      if (context.mounted) {
        _refreshWallets();

      }
    } finally {
      if (mounted) {
        setState(() => isWalletsLoading = false);
      }
    }
  }


  Future<void> _refreshWallets() async {
    await _loadWallets();
  }


  Future<void> _loadAds() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');
    final userProfileRaw = prefs.getString('userProfileRaw');

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      setState(() {
        _menuItems = {
          ...?orgData['data']?['customized_app_displayable_menu_items'],

        };
      });
    }

    if (userProfileRaw != null) {
      final profileData = json.decode(userProfileRaw);
      final adsMap = profileData['ads'] as Map<String, dynamic>?;

      if (adsMap != null) {
        final adsList = adsMap.entries.map((entry) {
          final ad = entry.value;
          return {
            'subject': ad['subject'],
            'content': ad['content'],
            'banner_url': ad['banner_url'],
            'content_redirect_url': ad['content_redirect_url'],
          };
        }).toList();

        setState(() {
          _ads = List<Map<String, dynamic>>.from(adsList);
          _showBanner = _menuItems['display-banner'] ?? false;
        });
      }
    }

    setState(() {});
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
        _welcomeDescription = data['description'] ?? _welcomeDescription;
      });
    }
  }

  Future<void> _refreshProfile() async {
    if (!_alreadyOpen) return;

    final profile = await ProfileController.fetchUserProfile();

    if (profile != null) {
      _updateLocalData(profile);
      _loadWallets();
    }

    setState(() {
      _userProfileFuture = Future.value(profile);
    });
  }


  Future<void> _refreshProfileX() async {
    final profile = await ProfileController.fetchUserProfile(); // Wait for profile

    await _loadPrimaryColorAndLogo(); // Wait
    await _loadAppSettings();
    await _loadWallets();

   // _loadAds();// Wait

    if (profile != null) {
      _updateLocalData(profile);

      if (_currentName != "---") {
        setState(() {
          _alreadyOpen = true;
        });
      }
    }

    setState(() {
      _userProfileFuture = Future.value(profile); // Optional if using FutureBuilder
    });
  }


  Timer? _refreshTimer;


  @override
  void initState() {
    super.initState();
    _userProfileFuture =  ProfileController.fetchUserProfile().then((profile) async {
      await _loadPrimaryColorAndLogo();
      await _loadAppSettings();
      await _loadWallets();

    //  _loadAds();

      if (profile != null) {
        _updateLocalData(profile);
        setState(() {
          _welcomeTitle = "HI, "+ "${profile['last_name']}".toUpperCase();

        });

        if(_currentName=="---"){

        }else {
          setState(() {
            _alreadyOpen = true;
          });
        }
      }
      return profile;
    });


    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        _refreshProfile();
      }else{

      }
    });
  }



  @override
  void dispose() {
    _refreshTimer?.cancel();

    _pageController.dispose();

    super.dispose();
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

  Widget _buildWalletCards() {

    return SizedBox(
      height: 280, // Adjust height as needed
      child: PageView.builder(
        padEnds: false, // Add this line
        controller: _pageController,

        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          final wallet = wallets[index];

          // Use primary color for first wallet, then cycle through other colors
          final cardColor = index == 0
              ? _primaryColor
              : walletColors[index % walletColors.length];

          return _buildCard(
            wallet['name'] ?? 'N/A', // wallet type (e.g., "Normal wallet")
            wallet['wallet_number'] ?? 'N/A', // wallet account number
            wallet['balance'].toString(), // wallet balance
            wallet['bank_name'] ?? 'Unknown Bank', // bank name
            true, // All fetched wallets are created wallets
            wallet['currency'] ?? '₦', // currency symbol
            cardColor,
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators() {
    if (wallets.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          wallets.length,
              (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentPage // Now uses _currentPage instead of 0
                  ? _primaryColor ?? Colors.blue
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildCard(String name, String cardNumber, String balance, String bankName, bool hasWallet, String currencySymbol, Color? cardColor) {
    String formattedBalance = NumberFormat("#,##0.00").format(double.tryParse(balance) ?? 0.00);

    // Use the passed color or fallback to primary color
    final effectiveColor = cardColor ?? _primaryColor;

    // Only show the card if we have a color
    if (effectiveColor == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveColor,
            effectiveColor.withOpacity(0.8),
            effectiveColor.withOpacity(0.9),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Available Balance',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Row(
                        children: [
                          if (!hasWallet)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minSize: 0,
                                onPressed: () => Navigator.pushNamed(context, Routes.wallet),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Create Wallet",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.wallet_outlined,
                                      size: 14,
                                      color: CupertinoColors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (hasWallet)...[
                            GestureDetector(
                              onTap: (){
                                showAccountDetailsModal(
                                  context,
                                  accountName: name,
                                  accountNumber: cardNumber,
                                );
                              },

                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 16,
                                child: Icon(CupertinoIcons.chevron_down_circle_fill, color: effectiveColor, size: 20),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _isBalanceHidden ? "••••••" : "$currencySymbol $formattedBalance",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _isBalanceHidden = !_isBalanceHidden;
                            });
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Details Section
            Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Number',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              cardNumber.replaceAllMapped(
                                RegExp(r'.{4}'),
                                    (match) => '${match.group(0)} ',
                              ),
                              style: GoogleFonts.sourceCodePro(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: cardNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text("Account number copied!"),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          bankName,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGraph() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Chart',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildChipFilter('Day'),
                    SizedBox(width:2),
                    _buildChipFilter('Week'),
                    SizedBox(width:2),
                    _buildChipFilter('Month'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(2.6, 2),
                      const FlSpot(4.9, 5),
                      const FlSpot(6.8, 3.1),
                      const FlSpot(8, 4),
                      const FlSpot(9.5, 3),
                      const FlSpot(11, 4),
                    ],
                    isCurved: true,
                    color: _secondaryColor ?? _defaultSecondaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (_secondaryColor ?? _defaultSecondaryColor).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFilter(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1D1D1F),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button

        title: Text(_welcomeTitle,style: GoogleFonts.poppins(fontSize: 18,fontWeight: FontWeight.w800),),
        actions: [
          IconButton(

            icon: const Icon(CupertinoIcons.layers_fill),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryColor ?? Colors.blue, // Use your brand color
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 60,
          onRefresh: _refreshProfile,

          child: FutureBuilder<Map<String, dynamic>?>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _alreadyOpen==true? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hasError?_buildCard(_currentName!, _currentWalletNumber!, _currentBalance!, _currentBankName!, _currentHasWallet!, _currentCurrencySymbol!,_primaryColor): _currentHasWallet!?_buildWalletCards(): _buildCard(_currentName!, _currentWalletNumber!, _currentBalance!, _currentBankName!, _currentHasWallet!, _currentCurrencySymbol!,_primaryColor),

                      _buildPageIndicators(), // Add this line

                      const SizedBox(height: 2),

                      const QuickActionsGrid(),
                    //  _buildGraph(),
                      const SizedBox(height: 5),
                      const TransactionList(),

                      /*
                      if (_showBanner && _ads.isNotEmpty) ...[
                        AdCarousel(ads: _ads),
                        const SizedBox(height: 16),
                      ],

                       */
                      const SizedBox(height: 16),


                    ],
                  ),
                ):Center(child:CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                // Get the error message from the response if available



                if (snapshot.error is Map) {
                  final errorResponse = snapshot.error as Map;

                  String x= errorResponse['message'];

                  if(x.contains("gobeller")||x.contains("FormatException")){
                    errorMessage = "We're unable to retrieve your profile. Please log out and sign in again.";

                  }else {
                    errorMessage = errorResponse['message'] ?? "We're unable to retrieve your profile. Please log out and sign in again.";

                  }




                } else {

                  String x= snapshot.error.toString();

                  if(x.contains("gobeller")||x.contains("FormatException")){
                    errorMessage = "We're unable to retrieve your profile. Please log out and sign in again.";

                  }else {
                    errorMessage = snapshot.error.toString();

                  }




                }

                return _alreadyOpen==true? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hasError?_buildCard(_currentName!, _currentWalletNumber!, _currentBalance!, _currentBankName!, _currentHasWallet!, _currentCurrencySymbol!,_primaryColor): _currentHasWallet? _buildWalletCards() : _buildCard(_currentName!, _currentWalletNumber!, _currentBalance!, _currentBankName!, _currentHasWallet!, _currentCurrencySymbol!,_primaryColor),

                      _buildPageIndicators(), // Add this line

                      const SizedBox(height: 2),

                      const QuickActionsGrid(),
                   //   _buildGraph(),
                      const SizedBox(height: 5),
                      const TransactionList(),
                      /*
                      if (_showBanner && _ads.isNotEmpty) ...[
                        AdCarousel(ads: _ads),
                        const SizedBox(height: 16),
                      ],

                       */
                      const SizedBox(height: 16),


                    ],
                  ),
                ): Center(
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
                        Text(
                          errorMessage,
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
                                backgroundColor: _secondaryColor??Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Log out",style: TextStyle(color: Colors.white),),
                            ),

                            ElevatedButton(
                              onPressed: _refreshProfileX,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor??Colors.black,

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

              final userProfile = snapshot.data!;
              final name = "${userProfile['first_name']} ${userProfile['last_name']}";

              // Use current data if available, otherwise fallback to snapshot
              final cardNumber = _currentWalletNumber ?? userProfile['wallet_number'] ?? '---';
              final balance = _currentBalance ?? userProfile['wallet_balance']?.toString() ?? '0.00';
              final bankName = _currentBankName ?? userProfile['bank_name'] ?? '---';
              final hasWallet = _currentHasWallet ?? userProfile['has_wallet'] ?? true;
              final currencySymbol = _currentCurrencySymbol ?? userProfile['getPrimaryWallet']?['currency']?['symbol'] ?? '₦';


              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hasError?_buildCard(name, cardNumber, balance, bankName, hasWallet, currencySymbol,_primaryColor): hasWallet? _buildWalletCards(): _buildCard(name, cardNumber, balance, bankName, hasWallet, currencySymbol,_primaryColor),
                    _buildPageIndicators(), // Add this line

                    const SizedBox(height: 2),



                    const QuickActionsGrid(),
                //    _buildGraph(),
                    const SizedBox(height: 5),
                    const TransactionList(),
                    /*
                    if (_showBanner && _ads.isNotEmpty) ...[
                      AdCarousel(ads: _ads),
                      const SizedBox(height: 16),
                    ],

                     */
                    const SizedBox(height: 16),


                  ],
                ),
              );
            },
          ),
        ),
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
  final PageController _controller = PageController(viewportFraction: 0.9);
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
          duration: const Duration(milliseconds: 600),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 250,
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
                onTap: () async {
                  final url = ad['content_redirect_url'];
                  if (url != null && url.isNotEmpty) {
                    final Uri uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint("❌ Could not launch $url");
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Banner Image
                        Positioned.fill(
                          child: Image.network(
                            ad['banner_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[600],
                                  child: Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey[800]),
                                ),
                          ),
                        ),
                        // Gradient Overlay
                        // Content Text
                        Positioned(
                          bottom: 15,
                          left: 15,
                          right: 15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['subject'] ?? '',
                                style:  GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ad['content'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == index ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.blueAccent
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );

  }
}

class AccountDetailsModal extends StatelessWidget {
  final String accountName;
  final String accountNumber;

  const AccountDetailsModal({
    Key? key,
    required this.accountName,
    required this.accountNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Account Name Field
                _buildDetailRow(
                  label: 'Account name',
                  value: accountName,
                ),

                const SizedBox(height: 24),

                // Account Number Field
                _buildDetailRow(
                  label: 'Account number',
                  value: accountNumber,
                ),
              ],
            ),
          ),

          // Bottom padding
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper function to show the modal
void showAccountDetailsModal(
    BuildContext context, {
      required String accountName,
      required String accountNumber,
    }) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AccountDetailsModal(
      accountName: accountName,
      accountNumber: accountNumber,
    ),
  );
}