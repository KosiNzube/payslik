
/*
import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gobeller/controller/profileControllers.dart';
import 'package:gobeller/pages/loan/loan.dart';
import 'package:gobeller/pages/quick_action/cable_tv_page.dart';
import 'package:gobeller/pages/quick_action/electric_meter_page.dart';
import 'package:gobeller/pages/success/widget/user_info_card.dart';
import 'package:gobeller/pages/success/widget/quick_actions_grid.dart';
import 'package:gobeller/pages/success/widget/transaction_list.dart';
import 'package:gobeller/pages/login/login_page.dart';
import 'package:gobeller/pages/wallet/screens/crypto_wallet_page.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/WalletController.dart';
import '../../newdesigns/quick_actions_list.dart';
import '../../newdesigns/swap_page_intent.dart';
import '../../newdesigns/wallet_to_bank_intent.dart';
import '../../newdesigns/wallet_to_wallet_intent.dart';
import '../quick_action/airtime.dart';
import '../quick_action/data_purchase_page.dart';
import '../quick_action/wallet_to_bank.dart';
import '../quick_action/wallet_to_wallet.dart';
import '../wallet/screens/CryptoWalletDetailPage.dart';
import '../wallet/screens/VirtualAccountRequestForm.dart';
import 'more_menu_page.dart';


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

class DashboardY extends StatefulWidget {
  const DashboardY({super.key});

  @override
  State<DashboardY> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardY> {
  late Future<Map<String, dynamic>?> _userProfileFuture;
  int _currentCardIndex = 0;
  int _selectedIndex = 0;
  bool _isBalanceHidden = true;
  bool _alreadyOpen = false;
  bool _alreadyloaded = false;
  int currentIndexWallet=0;

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
  Map<String, dynamic>? _selectedWallet; // currently selected wallet
  final ValueNotifier<double> _buttonScale = ValueNotifier(1.0);

  bool _currentHasWallet=false;
  String _currentCurrencySymbol="";
  String? _displayName;

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



  }

  void _showTransferOptions(BuildContext context, Map<String, dynamic> wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Transfer Option",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Wallet to Wallet Transfer option
              _TransferOptionTile(
                icon: Icons.wallet,
                title: "Wallet to Wallet",
                color: Colors.black54,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/transfer'),
                    screen: WalletToWalletTransferPageIntent(wallet: wallet),
                    withNavBar: true,
                  );
                },
              ),
              // Wallet to Bank Transfer option

              const SizedBox(height: 10),

              _TransferOptionTile(
                icon: Icons.double_arrow_rounded,
                title: "Wallet to Bank",
                color: Colors.black54,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/bank_transfer'),
                    screen:  WalletToBankTransferPageIntent(wallet: wallet,),
                    withNavBar: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCachedWallets() async {
    try {
      final cachedData = await WalletDataCache.getCachedData();
      debugPrint("🟢------------------- Raw cached data: $cachedData"+"🟢-------------------");

      if (cachedData != null && cachedData.isNotEmpty) {
        final processedWallets = cachedData.map((wallet) {
          // --- same parsing logic as _loadWallets2 ---
          String network = "Unknown";
          String walletAddress = "N/A";
          String label = "Unnamed Wallet";
          String walletStatus = "Unknown";
          String createdAt = "";

          final metadata = wallet["provider_metadata"];
          try {
            final meta = metadata is String ? json.decode(metadata) : metadata;
            if (meta is Map<String, dynamic>) {
              network = meta["network"]?.toString() ?? "Unknown";
              walletAddress = meta["code"]?.toString() ?? "N/A";
              label = meta["label"]?.toString() ?? "Unnamed Wallet";
              if (label.isEmpty) {
                label = wallet["ownership_label"]?.toString()?.trim() ?? "Unnamed Wallet";
              }
              walletStatus = meta["status"]?.toString() ?? "Unknown";
              createdAt = meta["created_at"]?.toString() ?? "";
            }
          } catch (e) {
            debugPrint("⚠️ Failed to parse provider_metadata: $e");
          }

          return {
            "type": wallet["ownership_type"] ?? "Normal wallet",
            "currency_name": wallet["currency"] is Map && wallet["currency"]?["name"] != null
                ? wallet["currency"]["name"]
                : wallet["currency"] is List,
            "currency_type": wallet["currency"] is Map && wallet["currency"]?["type"] != null
                ? wallet["currency"]["type"]
                : wallet["currency"] is List,
            "name": wallet["ownership_label"]?.toString() ?? "Wallet",
            "wallet_number": wallet["wallet_number"] ?? "N/A",
            "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
            "currency": wallet["currency"]?["symbol"] ?? "₦",
            "bank_name": wallet["bank"] is Map && wallet["bank"]?["name"] != null
                ? wallet["bank"]["name"]
                : wallet["bank"] is List
                ? "Unknown Bank"
                : "Unknown Bank" ?? "---",
            "bank_code": "N/A",
            "currency_code": wallet["currency"] is Map && wallet["currency"]?["code"] != null
                ? wallet["currency"]["code"]
                : wallet["currency"] is List,
            "currency_network": network,
            "label": label,
            "status": walletStatus,
            "created_at": createdAt,
            "wallet_address": walletAddress,
          };
        }).toList();

        if (!mounted) return;
        setState(() {
          wallets = List<Map<String, dynamic>>.from(processedWallets.reversed);
          _selectedWallet = wallets.isNotEmpty ? wallets.first : null;
          hasCachedWallets = true;
        });
        debugPrint("✅ Displayed cached wallets");
      } else {
        debugPrint("⚠️ No cached wallet data found");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load cached wallets: $e");
    }
  }

  Future<void> _loadWallets2() async {
    if (!mounted) return;

    setState(() => isWalletsLoading = true);

    try {
      final walletData = await WalletController.fetchWalletsALL();

      debugPrint("\n\n\n🧾🧾🧾🧾🧾🧾🧾🧾🧾🧾 Full wallet data: ${walletData.toString()}\n\n############################################################################375756756565667");


      if (!mounted) return;

      // Check if we got valid data
      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];
        await WalletDataCache.cacheRawData(data);
        debugPrint("✅ Cached raw wallet data");
        if (data is List) {
          final processedWallets = data.map((wallet) {

            String network = "Unknown";
            String walletAddress = "N/A";
            String label = "Unnamed Wallet";
            String walletStatus = "Unknown";
            String createdAt = "";

            final metadata = wallet["provider_metadata"];
            try {
              // Decode only if it's a string
              final meta = metadata is String ? json.decode(metadata) : metadata;

              if (meta is Map<String, dynamic>) {
                network = meta["network"]?.toString() ?? "Unknown";
                walletAddress = meta["code"]?.toString() ?? "N/A";
                label = meta["label"]?.toString() ?? "Unnamed Wallet";
                if (label == null || label.isEmpty) {
                  label = wallet["ownership_label"]?.toString()?.trim() ?? "Unnamed Wallet";
                }

                walletStatus = meta["status"]?.toString() ?? "Unknown";
                createdAt = meta["created_at"]?.toString() ?? "";
              }
            } catch (e) {
              debugPrint("⚠️ Failed to parse provider_metadata: $e");
            }

            return {
              "type": wallet["ownership_type"] ?? "Normal wallet",
              "currency_name": wallet["currency"] is Map && wallet["currency"]?["name"] != null
                  ? wallet["currency"]["name"]
                  : wallet["currency"] is List,
              "name": wallet["ownership_label"]?.toString() ?? "Wallet", // Use ownership_label instead
              "wallet_number": wallet["wallet_number"] ?? "N/A",
              "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
              "currency_type": wallet["currency"] is Map && wallet["currency"]?["type"] != null
                  ? wallet["currency"]["type"]
                  : wallet["currency"] is List,


              "currency": wallet["currency"]?["symbol"] ?? "₦",
              "bank_name": wallet["bank"] is Map && wallet["bank"]?["name"] != null
                  ? wallet["bank"]["name"]
                  : wallet["bank"] is List
                  ? "Unknown Bank"
                  : "Unknown Bank" ?? "---",
              "bank_code": "N/A", // Hardcode since bank data is null

              "currency_code": wallet["currency"] is Map && wallet["currency"]?["code"] != null
                  ? wallet["currency"]["code"]
                  : wallet["currency"] is List,// Hardcode since bank data is null

              "currency_network": network,
              "label": label,
              "status": walletStatus,
              "created_at": createdAt,
              "wallet_address": walletAddress,

            };
          }).toList();

          setState(() {
            wallets = List<Map<String, dynamic>>.from(processedWallets.reversed);
            hasError = false;
          });




          if (wallets.isNotEmpty) {

            setState(() {
              _selectedWallet = wallets[currentIndexWallet];
            });
          }




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

    } finally {
      if (mounted) {
        setState(() => isWalletsLoading = false);
      }
    }
  }

  Future<void> _loadWallets() async {
    if (!mounted) return;

    setState(() => isWalletsLoading = true);

    try {
      final walletData = await WalletController.fetchWalletsALL();

      debugPrint("\n\n\n🧾🧾🧾🧾🧾🧾🧾🧾🧾🧾 Full wallet data: ${walletData.toString()}\n\n############################################################################375756756565667");


      if (!mounted) return;

      // Check if we got valid data
      if (walletData.isNotEmpty && walletData.containsKey('data')) {
        final data = walletData['data'];

        await WalletDataCache.cacheRawData(data);
        debugPrint("✅ Cached raw wallet data");

        if (data is List) {
          final processedWallets = data.map((wallet) {



            String network = "Unknown";
            String walletAddress = "N/A";
            String label = "Unnamed Wallet";
            String walletStatus = "Unknown";
            String createdAt = "";

            final metadata = wallet["provider_metadata"];
            try {
              // Decode only if it's a string
              final meta = metadata is String ? json.decode(metadata) : metadata;

              if (meta is Map<String, dynamic>) {
                network = meta["network"]?.toString() ?? "Unknown";
                walletAddress = meta["code"]?.toString() ?? "N/A";
                label = meta["label"]?.toString() ?? "Unnamed Wallet";
                if (label == null || label.isEmpty) {
                  label = wallet["ownership_label"]?.toString()?.trim() ?? "Unnamed Wallet";
                }

                walletStatus = meta["status"]?.toString() ?? "Unknown";
                createdAt = meta["created_at"]?.toString() ?? "";
              }
            } catch (e) {
              debugPrint("⚠️ Failed to parse provider_metadata: $e");
            }


            return {
              "type": wallet["ownership_type"] ?? "Normal wallet",
              "currency_name": wallet["currency"] is Map && wallet["currency"]?["name"] != null
                  ? wallet["currency"]["name"]
                  : wallet["currency"] is List,// Hardcode since bank data is null

              "currency_type": wallet["currency"] is Map && wallet["currency"]?["type"] != null
                  ? wallet["currency"]["type"]
                  : wallet["currency"] is List,
              "name": wallet["ownership_label"]?.toString() ?? "Wallet", // Use ownership_label instead
              "wallet_number": wallet["wallet_number"] ?? "N/A",
              "balance": double.tryParse(wallet["balance"]?.toString() ?? "0.0") ?? 0.0,
              "currency": wallet["currency"]?["symbol"] ?? "₦",
              "bank_name": wallet["bank"] is Map && wallet["bank"]?["name"] != null
                  ? wallet["bank"]["name"]
                  : wallet["bank"] is List
                  ? "Unknown Bank"
                  : "Unknown Bank" ?? "---",
              "bank_code": "N/A", // Hardcode since bank data is null


              "currency_network": network,
              "label": label,
              "status": walletStatus,
              "created_at": createdAt,
              "wallet_address": walletAddress,

              "currency_code": wallet["currency"] is Map && wallet["currency"]?["code"] != null
                  ? wallet["currency"]["code"]
                  : wallet["currency"] is List,// Hardcode since bank data is null
            };
          }).toList();

          setState(() {
            wallets = List<Map<String, dynamic>>.from(processedWallets.reversed);
            hasError = false;
          });



          if (wallets.isNotEmpty) {

            setState(() {
              _selectedWallet = wallets.first;
            });
          }



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

  void _showWalletBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select Wallet',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Scrollable wallet list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final w = wallets[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white70,
                        border: Border.all(color: Colors.black),
                      ),

                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: _selectedWallet == w ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        leading:   w['currency_code']=="NGN"? Flag.fromCode(
                          FlagsCode.NG,
                          height: 18,
                          width: 18,
                        ):
                        w['currency_code']=="USD"? Flag.fromCode(
                          FlagsCode.US,
                          height: 18,
                          width: 18,
                        ):
                        w['currency_code']=="GBP"? Flag.fromCode(
                          FlagsCode.GB_ENG,
                          height: 18,
                          width: 18,
                        ):
                        w['currency_code']=="EUR"? Flag.fromCode(
                          FlagsCode.EU,
                          height: 18,
                          width: 18,
                        ):
                        w['currency_code']=="CAD"? Flag.fromCode(
                          FlagsCode.CD,
                          height: 18,
                          width: 18,
                        ):

                        w['currency_code']=="USDT"? Image.asset(
                          'assets/tether.png',
                          height: 18,
                          width: 18,
                        ):
                        w['currency_code']=="USDC"? Image.asset(
                          'assets/usdc.png',
                          height: 18,
                          width: 18,
                        ):
                        Icon(CupertinoIcons.flag, size: 16, color: Colors.black),
                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              w['currency_name'] ?? "---",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Row(
                              children: [
                                Text(
                                  w['currency'] ?? "---",
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat("#,##0.00").format(w["balance"] ?? 0.0) ?? "---",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: _selectedWallet == w ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                        onTap: () {
                          setState(() {
                            _selectedWallet = w;
                            currentIndexWallet = wallets.indexWhere((wallet) => wallet == w);
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String getLastFourDigits(String accountNumber) {
    // Ensure the account number is at least 4 characters long
    if (accountNumber.length >= 4) {
      return accountNumber.substring(accountNumber.length - 4);
    } else {
      // If it's shorter than 4, return the full string
      return accountNumber;
    }
  }

  void showCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: wallets.length,
          itemBuilder: (context, index) {
            final w = wallets[index];

            return ListTile(
              onTap: () async {


                _selectedWallet = w;
                currentIndexWallet = wallets.indexWhere((wallet) => wallet == w);



              },

              leading: CircleAvatar(
                backgroundColor: _primaryColor,
                child: Text(w['currency'] ?? "---",style: TextStyle(color: Colors.white),),
              ),
              title: Text(w['currency_code']),
              subtitle: Text(NumberFormat("#,##0.00").format(w["balance"] ?? 0.0) ?? "---",),
              trailing: _selectedWallet == w ? const Icon(Icons.check, color: Colors.white, size: 20) : null,

            );
          },
        );
      },
    );
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _buttonScale.value = 0.9,
      onTapUp: (_) {
        _buttonScale.value = 1.0;
        onTap();
      },
      onTapCancel: () => _buttonScale.value = 1.0,
      child: ValueListenableBuilder<double>(
        valueListenable: _buttonScale,
        builder: (_, scale, child) {
          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// --- Wallet Card with Fade & Slide In ---
  Widget _buildWalletCardUnified() {
    if (wallets.isEmpty) return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), // slides up slightly
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: _primaryColor!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Currency Selector ---
              GestureDetector(


                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flag.fromCode(
                        FlagsCode.NG,
                        height: 18,
                        width: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "--- --- ---",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Balance Display ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isBalanceHidden ? "••••••" : "---",
                    style:  GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),

                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.all(10.8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.blue[600],
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Account Number ---
              GestureDetector(

                onTap: (){
                  Navigator.pushNamed(context, Routes.wallet);

                },

                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bank,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Wallet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Action Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.more_horiz,
                    label: '---',
                    onTap: () {


                    },
                  ),
                  _buildActionButton(
                    icon: Icons.north_east,
                    label: '---',
                    onTap: () {



                    },
                  ),
                  _buildActionButton(
                    icon: Icons.sync,
                    label: '---',
                    onTap: () {


                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final wallet = _selectedWallet!;
    final String formattedBalance = NumberFormat("#,##0.00")
        .format(wallet["balance"] ?? 0.0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), // slides up slightly
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: _primaryColor!.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Currency Selector ---
              GestureDetector(
                onTap: () => _showWalletBottomSheet(),


                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      wallet['currency_code']=="NGN"? Flag.fromCode(
                        FlagsCode.NG,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USD"? Flag.fromCode(
                        FlagsCode.US,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="GBP"? Flag.fromCode(
                        FlagsCode.GB_ENG,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="EUR"? Flag.fromCode(
                        FlagsCode.EU,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="CAD"? Flag.fromCode(
                        FlagsCode.CD,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USDT"? Image.asset(
                        'assets/tether.png',
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USDC"? Image.asset(
                        'assets/usdc.png',
                        height: 18,
                        width: 18,
                      ):
                      Text(_selectedWallet?['currency'] ?? "---"),
                      const SizedBox(width: 8),
                      Text(
                        wallet['currency_name'].toString().length<26?wallet['currency_name'].toString():wallet['currency_name'].toString().substring(0,26)+"...",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Balance Display ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedWallet?['currency'] ?? "---",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isBalanceHidden ? "••••••" : "$formattedBalance",
                    style:  GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),

                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.all(10.8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.blue[600],
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Account Number ---
              GestureDetector(
                onTap: () {

                  wallet['currency_type'].toString().toLowerCase()=="crypto"?Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                    ),
                  ):

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FiatWalletDetailPage(wallet: wallet),
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bank,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '******',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getLastFourDigits(wallet['wallet_number'].toString()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Action Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.add,
                    label: 'Add wallet',
                    onTap: () {

                      Navigator.pushNamed(context, Routes.wallet);

                      /*
                      wallet['currency_type'].toString().toLowerCase()=="crypto"?Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                        ),
                      ):

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FiatWalletDetailPage(wallet: wallet),
                        ),
                      );

                       */
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.north_east,
                    label: 'Send',
                    onTap: () {
                      _showTransferOptions(context,wallet);



                    },
                  ),
                  _buildActionButton(
                    icon: Icons.sync,
                    label: 'Convert',
                    onTap: () {

                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: SwapPageIntent(wallet: wallet),
                        withNavBar: false,
                      );

                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWalletCardUnifiedMonk() {
    if (wallets.isEmpty) return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), // slides up slightly
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Currency Selector ---
              GestureDetector(


                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flag.fromCode(
                        FlagsCode.NG,
                        height: 18,
                        width: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "--- --- ---",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Balance Display ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isBalanceHidden ? "••••••" : "---",
                    style:  GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),

                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.all(10.8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.blue[600],
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Account Number ---
              GestureDetector(

                onTap: (){
                  Navigator.pushNamed(context, Routes.wallet);

                },

                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bank,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Wallet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Action Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.more_horiz,
                    label: '---',
                    onTap: () {


                    },
                  ),
                  _buildActionButton(
                    icon: Icons.north_east,
                    label: '---',
                    onTap: () {



                    },
                  ),
                  _buildActionButton(
                    icon: Icons.sync,
                    label: '---',
                    onTap: () {


                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final wallet = _selectedWallet!;
    final String formattedBalance = NumberFormat("#,##0.00")
        .format(wallet["balance"] ?? 0.0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), // slides up slightly
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: _primaryColor!.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Currency Selector ---
              GestureDetector(
                onTap: () => _showWalletBottomSheet(),


                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      wallet['currency_code']=="NGN"? Flag.fromCode(
                        FlagsCode.NG,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USD"? Flag.fromCode(
                        FlagsCode.US,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="GBP"? Flag.fromCode(
                        FlagsCode.GB_ENG,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="EUR"? Flag.fromCode(
                        FlagsCode.EU,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="CAD"? Flag.fromCode(
                        FlagsCode.CD,
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USDT"? Image.asset(
                        'assets/tether.png',
                        height: 18,
                        width: 18,
                      ):
                      wallet['currency_code']=="USDC"? Image.asset(
                        'assets/usdc.png',
                        height: 18,
                        width: 18,
                      ):
                      Text(_selectedWallet?['currency'] ?? "---"),
                      const SizedBox(width: 8),
                      Text(
                        wallet['currency_name'].toString().length<26?wallet['currency_name'].toString():wallet['currency_name'].toString().substring(0,26)+"...",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Balance Display ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedWallet?['currency'] ?? "---",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _isBalanceHidden ? "••••••" : "$formattedBalance",
                    style:  GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),

                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.all(10.8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.blue[600],
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Account Number ---
              GestureDetector(
                onTap: () {

                  wallet['currency_type'].toString().toLowerCase()=="crypto"?Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                    ),
                  ):

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FiatWalletDetailPage(wallet: wallet),
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.bank,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '******',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getLastFourDigits(wallet['wallet_number'].toString()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Action Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.add,
                    label: 'Add wallet',
                    onTap: () {

                      Navigator.pushNamed(context, Routes.wallet);

                      /*
                      wallet['currency_type'].toString().toLowerCase()=="crypto"?Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                        ),
                      ):

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FiatWalletDetailPage(wallet: wallet),
                        ),
                      );

                       */
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.north_east,
                    label: 'Send',
                    onTap: () {
                      _showTransferOptions(context,wallet);



                    },
                  ),
                  _buildActionButton(
                    icon: Icons.sync,
                    label: 'Convert',
                    onTap: () {

                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: SwapPageIntent(wallet: wallet),
                        withNavBar: false,
                      );

                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _refreshWallets() async {
    await _loadWallets2();
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
      _loadWallets2();

    }

    setState(() {
      _userProfileFuture = Future.value(profile);
    });
  }


  Future<void> _refreshProfileX() async {
    final profile = await ProfileController.fetchUserProfile(); // Wait for profile

    await _loadPrimaryColorAndLogo(); // Wait
    await _loadAppSettings();
    await _loadWallets2();

    //  _loadAds();// Wait

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

  bool hasCachedWallets = false;


  Timer? _refreshTimer;

  Future<void> _checkStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final test = prefs.getString('first_name');
    final userData = prefs.getString('user');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      String? firstName;

      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        firstName = userMap['first_name'];
      }

      setState(() {
        _displayName = test ;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    _loadAppSettings();
    _checkStoredUsername();
    _loadCachedWallets();

    //loadCacheWallet();

    _userProfileFuture =  ProfileController.fetchUserProfile().then((profile) async {
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






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button

        title: Text("Hi, "+_displayName!,style: GoogleFonts.inter(fontSize: 18,fontWeight: FontWeight.w800),),
        actions: [
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: IconButton(

              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
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
                      hasError?_buildWalletCardUnified(): wallets.length>0?_buildWalletCardUnified(): _buildWalletCardUnified(),



                      const SizedBox(height: 2),
                      RecommendedSection(),
                      //  _buildGraph(),
                      const SizedBox(height: 5),
                      const TransactionList(),
                      const SizedBox(height: 16),


                    ],
                  ),
                ):hasCachedWallets? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hasError?_buildWalletCardUnifiedMonk(): wallets.length>0?_buildWalletCardUnifiedMonk(): _buildWalletCardUnifiedMonk(),




                      const SizedBox(height: 2),
                      RecommendedSection(),


                      //  _buildGraph(),
                      const SizedBox(height: 5),


                      const TransactionList(),
                      const SizedBox(height: 16),




                    ],
                  ),
                ):Center(child: CircularProgressIndicator(strokeWidth: 1.1,color: Colors.black,));
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
                      hasError?_buildWalletCardUnified(): wallets.length>0? _buildWalletCardUnified() : _buildWalletCardUnified(),


                      const SizedBox(height: 2),
                      /*
                      if (_showBanner && _ads.isNotEmpty) ...[
                        AdCarousel(ads: _ads),
                        const SizedBox(height: 16),
                      ],

                       */



                      RecommendedSection(),
                      //   _buildGraph(),
                      const SizedBox(height: 5),
                      const TransactionList(),
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
                          errorMessage.toLowerCase().contains("subtype of type")?"Something went wrong, please check your internet connection":errorMessage,
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
              final cardNumber = '---';
              final balance ='---';
              final bankName = '---';
              final hasWallet =  true;
              final currencySymbol =  '';


              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hasError?_buildWalletCardUnified(): wallets.length>0? _buildWalletCardUnified(): _buildWalletCardUnified(),

                    const SizedBox(height: 2),

                    /*
                    if (_showBanner && _ads.isNotEmpty) ...[
                      AdCarousel(ads: _ads),
                      const SizedBox(height: 16),
                    ],

                     */



                    RecommendedSection(),
                    //    _buildGraph(),
                    const SizedBox(height: 5),
                    const TransactionList(),
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




class _TransferOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _TransferOptionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
}





class RecommendedSection extends StatefulWidget {
  const RecommendedSection({Key? key}) : super(key: key);

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late List<Animation<double>> _buttonAnimations;
  late List<Animation<Offset>> _buttonSlideAnimations;
  final Color _defaultSecondaryColor = const Color(0xFFFF9800);
  final Color _defaultTertiaryColor = const Color(0xFFF5F5F5);
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();


    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _buttonAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _buttonController,
          curve: Interval(index * 0.1, 0.6 + (index * 0.1),
              curve: Curves.easeOut),
        ),
      );
    });

    _buttonSlideAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _buttonController,
          curve: Interval(index * 0.1, 0.6 + (index * 0.1),
              curve: Curves.easeOut),
        ),
      );
    });

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
  void _showTransferOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Bills & Airtime",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Wallet to Wallet Transfer option
              _TransferOptionTile(
                icon: Icons.phone_android,
                title: "Airtime",
                color: Colors.black87,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/airtime'),
                    screen: BuyAirtimePage(),
                    withNavBar: true,
                  );
                },
              ),
              // Wallet to Bank Transfer option

              const SizedBox(height: 10),

              _TransferOptionTile(
                icon: Icons.wifi,
                title: "Data",
                color: Colors.black87,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/data_purchase'),
                    screen:  DataPurchasePage(),
                    withNavBar: true,
                  );
                },
              ),

              _TransferOptionTile(
                icon: Icons.flash_on_rounded,
                title: "Electricity",
                color: Colors.black87,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/electric'),
                    screen:  ElectricityPaymentPage(),
                    withNavBar: true,
                  );
                },
              ),

              _TransferOptionTile(
                icon: Icons.tv,
                title: "Cable TV",
                color: Colors.black87,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/cable_tv'),
                    screen:  CableTVPage(),
                    withNavBar: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

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



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _titleSlideAnimation,
            child: FadeTransition(
              opacity: _titleFadeAnimation,
              child: Text(
                'Recommended',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _buildAnimatedButton(

                  route: (){

                    _showTransferOptions(context);


                  },

                  'Pay Bills', FontAwesomeIcons.receipt, _secondaryColor!.withOpacity(0.5), 2),

              _buildAnimatedButton(

                  route: (){

                    PersistentNavBarNavigator.pushNewScreen(
                      context,
                      screen: LoanPage(),
                      withNavBar: true,
                    );

                  },

                  'Loans', FontAwesomeIcons.moneyBill,
                  _secondaryColor!.withOpacity(0.5),0),
              _buildAnimatedButton(
                  route: (){

                    PersistentNavBarNavigator.pushNewScreen(
                      context,
                      screen: CryptoWalletPage(menu:true),
                      withNavBar: true,
                    );


                  },

                  'Crypto', Icons.currency_bitcoin_sharp, _secondaryColor!.withOpacity(0.5), 1),

              _buildAnimatedButton(

                  route: (){

                    PersistentNavBarNavigator.pushNewScreen(
                      context,
                      screen: MoreMenuPage(),
                      withNavBar: true,
                    );



                  },

                  'More', Icons.apps_rounded,
                  _secondaryColor!.withOpacity(0.5), 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(
      String text, IconData icon, Color color, int index, {required Null Function() route}) {
    return SlideTransition(
      position: _buttonSlideAnimations[index],
      child: ScaleTransition(
        scale: _buttonAnimations[index],
        child: _AnimatedButton(
          text: text,
          icon: icon,
          route:route,
          color: color,
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Null Function() route;

  const _AnimatedButton({
    required this.text,
    required this.icon,
    required this.color, required this.route,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;



  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onTap: widget.route,

      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: widget.color),
              const SizedBox(height: 6),
              Text(
                widget.text,
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




















class WalletDataCache {
  static const _key = "cached_wallet_data";

  static Future<void> cacheRawData(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<List<Map<String, dynamic>>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Failed to decode cached wallet data: $e");
      return null;
    }
  }
}

class CryptoDataCache {
  static const _key = "cached_crypto_data";

  static Future<void> cacheRawData(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<List<Map<String, dynamic>>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Failed to decode cached wallet data: $e");
      return null;
    }
  }
}

class FXDataCache {
  static const _key = "cached_fx_data";

  static Future<void> cacheRawData(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<List<Map<String, dynamic>>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Failed to decode cached wallet data: $e");
      return null;
    }
  }
}

 */