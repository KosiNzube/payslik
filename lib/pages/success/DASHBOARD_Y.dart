

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
import 'package:gobeller/controller/wallet_services.dart';
import 'package:gobeller/newdesigns/SendMoneyScreen.dart';
import 'package:gobeller/newdesigns/cross_border_transfer.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

import '../../WalletProviders/General_Wallet_Provider.dart';
import '../../controller/WalletController.dart';
import '../../controller/WalletTransactionController.dart';
import '../../controller/create_wallet_controller.dart';
import '../../newdesigns/ReceiveMoneyScreen.dart';
import '../../newdesigns/quick_actions_list.dart';
import '../../newdesigns/swap_page_intent.dart';
import '../../newdesigns/wallet_to_bank_intent.dart';
import '../../newdesigns/wallet_to_wallet_intent.dart';
import '../../service/VirtualAccountService.dart';
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
  Map<String, dynamic>? _selectedWallet; // currently selected wallet
  final ValueNotifier<double> _buttonScale = ValueNotifier(1.0);
  bool isWalletTypeLoading = true;
  String selectedCurrencyId = '';

  String selectedAccountType = 'internal-account';


  bool _currentHasWallet=false;
  String _currentCurrencySymbol="";
  String _displayName ="DASHBOARD";
  bool isBanksLoading = true;

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
  bool isCurrencyLoading = true;

  bool isCreatingWallet = false;
  bool isWalletsLoading = false;
  bool _canCreateFxWallet = false;
  List<Map<String, dynamic>> walletTypes = [];
  List<Map<String, dynamic>> banks = [];
  List<dynamic> currencies = [];


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

              if (_menuItems['display-wallet-transfer-menu'] == true)
              // Wallet to Wallet Transfer option
                  _TransferOptionTile(
                    icon: Icons.wallet,
                    title: "Wallet Transfer",
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

              if (_menuItems['display-bank-transfer-menu'] == true)

                _TransferOptionTile(
                  icon: Icons.double_arrow_rounded,
                  title: "Nigeria Bank Transfer",
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
              const SizedBox(height: 10),

              _TransferOptionTile(
                icon: Icons.phone_android,
                title: "Mobile Money (Africa)",
                color: Colors.black54,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/send-money'),
                    screen:  SendMoneyScreen(wallet: wallet),
                    withNavBar: true,
                  );
                },
              ),

              const SizedBox(height: 10),

              _TransferOptionTile(
                icon: Icons.swap_horiz_sharp,
                title: "Cross Border Transfer",
                color: Colors.black54,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/cross-border-money'),
                    screen:  CrossBorderTransferPageIntent(wallet: wallet),
                    withNavBar: true,
                  );
                },
              ),

              /*
              const SizedBox(height: 10),

              _TransferOptionTile(
                icon: Icons.send_sharp,
                title: "International Transfer",
                color: Colors.black54,
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: const RouteSettings(name: '/send-money'),
                    screen:  SendMoneyScreen(wallet: wallet),
                    withNavBar: true,
                  );
                },
              ),

               */
            ],
          ),
        );
      },
    );
  }


  bool _hasExistingRequest = false;
  Map<String, dynamic>? _existingRequestData;
  bool _isCheckingExistingRequest = true;

  Future<void> _checkForExistingRequest( Map<String, dynamic> wallet) async {
    setState(() {
      _isCheckingExistingRequest = true;
    });

    try {
      // Step 1: Check if user has any request for this currency
      final hasRequest = await VirtualAccountService.hasRequestForCurrency(wallet["currency_code"]);

      if (hasRequest) {
        // Step 2: Get the actual request data for display
        final requestData = await VirtualAccountService.getLatestRequestForCurrency(wallet["currency_code"]);

        if (requestData != null) {
          setState(() {
            _hasExistingRequest = true;
            _existingRequestData = requestData;
            _isCheckingExistingRequest = false;
          });

          debugPrint("User has existing ${wallet["currency_code"]} virtual account request");
          debugPrint("Request Status: ${requestData['status']['label']}");
        } else {
          // Edge case: hasRequest was true but couldn't get data
          setState(() {
            _hasExistingRequest = false;
            _existingRequestData = null;
            _isCheckingExistingRequest = false;
          });
        }
      } else {
        // No existing request found - show the form
        setState(() {
          _hasExistingRequest = false;
          _existingRequestData = null;
          _isCheckingExistingRequest = false;
        });

        debugPrint("No existing ${wallet["currency_code"]} virtual account request found");
      }

    } catch (e) {
      // Handle any errors during the check
      setState(() {
        _isCheckingExistingRequest = false;
        _hasExistingRequest = false;
        _existingRequestData = null;
      });

      debugPrint("Error checking existing request: $e");

      // Show error to user
    }
  }


  Widget _buildDropdown({
    required String label,
    required List<DropdownMenuItem<String>> items,
    String? value,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _loadCurrencies() async {
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);



      final response = await CurrencyController.fetchCurrenciesMM();
      if (response != null) {
        setState(() => currencies = response);
      }
    } catch (e) {
      debugPrint("Failed to load currencies: $e");
    } finally {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }



  Future<void> _loadWalletTypes() async {
    try {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = true);

      final response = await CurrencyController.fetchWalletTypes();
      if (!mounted) return;

      setState(() {
        walletTypes = response ?? [];
        isWalletTypeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isWalletTypeLoading = false);
    }
  }
  Future<void> _loadBanks() async {
    try {
      if (!mounted) return;
      setState(() => isBanksLoading = true);

      final response = await CurrencyController.fetchBanks();
      if (!mounted) return;

      setState(() {
        banks = response ?? [];
        isBanksLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isBanksLoading = false);
    }
  }



  void _createNewWallet(BuildContext context) {
    if (isCurrencyLoading) {

      snacklen("Please wait, loading options...");


      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !isCreatingWallet,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Add New Wallet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDropdown(
                          label: "Account Type",
                          items: const [
                            DropdownMenuItem(
                              value: "internal-account",
                              child: Text("Internal Account"),
                            ),
                          ],
                          value: "internal-account",
                          onChanged: null,
                        ),
                        const SizedBox(height: 20),

                        isCurrencyLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdown(
                          label: "Currency",
                          items: currencies.map<DropdownMenuItem<String>>((currency) {
                            return DropdownMenuItem<String>(
                              value: currency["id"],
                              child: Text(
                                currency["name"],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: selectedCurrencyId.isNotEmpty ? selectedCurrencyId : null,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedCurrencyId = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),




                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: isCreatingWallet
                          ? null
                          : () async {
                        if (selectedCurrencyId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields.")),
                          );
                          return;
                        }

                        final requestBody = {
                          "account_type": "internal-account",
                          "currency_id": selectedCurrencyId,
                        };

                        setStateDialog(() => isCreatingWallet = true);

                        try {
                          final result = await CurrencyController.createWallet(requestBody);

                          if (result["status"] == "success" || result["status"] == true) {
                            await _refreshProfile();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Wallet added successfully.")),
                            );

                            setState(() {
                              selectedCurrencyId = '';
                              selectedAccountType = 'internal-account';
                            });

                            Navigator.of(context).pop();
                          } else {
                            final errorMsg = result["message"] ?? "Something went wrong.";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          }
                        } catch (e) {
                          final errorMsg = e.toString().replaceFirst("Exception: ", "");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        } finally {
                          setStateDialog(() => isCreatingWallet = false);
                        }
                      },
                      child:  Text("Add Wallet",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
                if (isCreatingWallet)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        );
      },
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
                    color: Colors.white,
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
    return Consumer<GeneralWalletProvider>(
      builder: (context, walletProvider, child) {
        if (!walletProvider.hasWallets) {
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
                  color: _primaryColor!,
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
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isBalanceHidden ? "••••••" : "---",
                          style: GoogleFonts.poppins(
                            fontSize: 35,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                              color: Colors.black,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Account Number ---
                    GestureDetector(
                      onTap: () async {
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
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.north_east,
                          label: '---',
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.sync,
                          label: '---',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // When wallets exist, use the selected wallet
        final String formattedBalance = NumberFormat("#,##0.00")
            .format(double.tryParse(walletProvider.currentBalance) ?? 0.0);

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
                color: _primaryColor!,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Currency Selector ---
                  GestureDetector(
                    onTap: () => _showWalletBottomSheet(walletProvider),
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
                          _buildCurrencyIcon(walletProvider.currentCurrencyCode),
                          const SizedBox(width: 8),
                          Text(
                            _truncateText(walletProvider.currentCurrencyName, 26),
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
                        walletProvider.currentCurrency,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isBalanceHidden ? "••••••" : formattedBalance,
                        style: GoogleFonts.poppins(
                          fontSize: 35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                            color: Colors.black,
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
                      final wallet = walletProvider.selectedWallet!;

                      wallet['currency_type'].toString().toLowerCase() == "crypto"
                          ? Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                        ),
                      )
                          : Navigator.push(
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
                            getLastFourDigits(walletProvider.currentWalletNumber),
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
                      if (_menuItems['can-create-fx-wallet'] == true || walletProvider.currentCurrencyCode=='KES')

                        !['NGN', 'USD', 'EUR', 'GBP'].contains(walletProvider.currentCurrencyCode)?_buildActionButton(
                          icon: Icons.add,
                          label: 'Add money',
                          onTap: () async {
                            /*
                              //Navigator.pushNamed(context, Routes.wallet);
                              SmartDialog.showLoading(msg: "Please wait...");

                              try {
                                // Capture the response
                                final result = await WalletService.createCustomerWallet(
                                    accountType: "internal-account",
                                    currencyId: walletProvider.currentCurrencyID
                                );

                                SmartDialog.dismiss();

                                // Check if wallet was created successfully
                                if (result['status'] == true) {
                                  // Success!
                                  SmartDialog.showToast("✅ ${result['message'] ?? 'Wallet added successfully'}");

                                  // Optional: Refresh wallet list or navigate somewhere
                                  // walletProvider.refreshWallets();
                                  // Navigator.pop(context);

                                } else {
                                  // Failed
                                  SmartDialog.showToast("❌ ${result['message'] ?? 'Failed to add wallet'}");
                                }

                              } catch (e) {
                                SmartDialog.dismiss();
                                SmartDialog.showToast("❌ Error: $e");
                              }

                               */
                            final wallet = walletProvider.selectedWallet!;

                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: ReceiveMoneyScreen(wallet: wallet),
                              withNavBar: false,
                            );
                          },
                        )
                            /*
                            :(walletProvider.currentCurrencyCode == 'USD' ||
                            walletProvider.currentCurrencyCode == 'EUR' ||
                            walletProvider.currentCurrencyCode == 'GBP') &&
                            walletProvider.currentBankName.contains("Unknown") ? _buildActionButton(
                          icon: Icons.add,
                          label: 'Get Account',
                          onTap: () async {
                            /*
                              //Navigator.pushNamed(context, Routes.wallet);
                              SmartDialog.showLoading(msg: "Please wait...");

                              try {
                                // Capture the response
                                final result = await WalletService.createCustomerWallet(
                                    accountType: "internal-account",
                                    currencyId: walletProvider.currentCurrencyID
                                );

                                SmartDialog.dismiss();

                                // Check if wallet was created successfully
                                if (result['status'] == true) {
                                  // Success!
                                  SmartDialog.showToast("✅ ${result['message'] ?? 'Wallet added successfully'}");

                                  // Optional: Refresh wallet list or navigate somewhere
                                  // walletProvider.refreshWallets();
                                  // Navigator.pop(context);

                                } else {
                                  // Failed
                                  SmartDialog.showToast("❌ ${result['message'] ?? 'Failed to add wallet'}");
                                }

                              } catch (e) {
                                SmartDialog.dismiss();
                                SmartDialog.showToast("❌ Error: $e");
                              }

                               */

                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: VirtualAccountRequestForm(code:walletProvider.currentCurrencyCode ,),
                              withNavBar: false,
                            );
                          },
                        )

                             */

                            :_buildActionButton(
                            icon: Icons.add,
                            label: 'Add wallet',
                            onTap: () async {
                              /*
                              //Navigator.pushNamed(context, Routes.wallet);
                              SmartDialog.showLoading(msg: "Please wait...");

                              try {
                                // Capture the response
                                final result = await WalletService.createCustomerWallet(
                                    accountType: "internal-account",
                                    currencyId: walletProvider.currentCurrencyID
                                );

                                SmartDialog.dismiss();

                                // Check if wallet was created successfully
                                if (result['status'] == true) {
                                  // Success!
                                  SmartDialog.showToast("✅ ${result['message'] ?? 'Wallet added successfully'}");

                                  // Optional: Refresh wallet list or navigate somewhere
                                  // walletProvider.refreshWallets();
                                  // Navigator.pop(context);

                                } else {
                                  // Failed
                                  SmartDialog.showToast("❌ ${result['message'] ?? 'Failed to add wallet'}");
                                }

                              } catch (e) {
                                SmartDialog.dismiss();
                                SmartDialog.showToast("❌ Error: $e");
                              }

                               */

                              _createNewWallet(context);

                            },
                          ),
                      if (_menuItems['display-bank-transfer-menu'] == true||_menuItems['display-wallet-transfer-menu'] == true||_menuItems['display-send-mobile-money'] == true)
                          _buildActionButton(
                            icon: Icons.north_east,
                            label: 'Send',
                            onTap: () {
                              final wallet = walletProvider.selectedWallet!;
                              _showTransferOptions(context, wallet);
                            },
                          ),

                      if (_menuItems['display-fiat-crypto-conversion-options'] == true)
                        _buildActionButton(
                                  icon: Icons.sync,
                                  label: 'Convert',
                                  onTap: () {
                                    final wallet = walletProvider.selectedWallet!;
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
      },
    );
  }

  Widget _buildCurrencyIcon(String currencyCode) {
    switch (currencyCode) {
    // Nigerian Naira
      case "NGN":
        return Flag.fromCode(FlagsCode.NG, height: 18, width: 18);

    // West African CFA franc
      case "XOF":
        return Flag.fromCode(FlagsCode.EC, height: 18, width: 18); // Using Ivory Coast flag for XOF

    // Central African CFA franc
      case "XAF":
        return Flag.fromCode(FlagsCode.CM, height: 18, width: 18); // Using Cameroon flag for XAF

    // Congolese franc
      case "CDF":
        return Flag.fromCode(FlagsCode.CD, height: 18, width: 18);

    // Ghanaian cedi
      case "GHS":
        return Flag.fromCode(FlagsCode.GH, height: 18, width: 18);

    // Kenyan shilling
      case "KES":
        return Flag.fromCode(FlagsCode.KE, height: 18, width: 18);

    // Lesotho loti
      case "LSL":
        return Flag.fromCode(FlagsCode.LS, height: 18, width: 18);

    // Malawian kwacha
      case "MWK":
        return Flag.fromCode(FlagsCode.MW, height: 18, width: 18);

    // Mozambican metical
      case "MZN":
        return Flag.fromCode(FlagsCode.MZ, height: 18, width: 18);

    // Rwandan franc
      case "RWF":
        return Flag.fromCode(FlagsCode.RW, height: 18, width: 18);

    // Sierra Leonean leone
      case "SLL":
        return Flag.fromCode(FlagsCode.SL, height: 18, width: 18);

    // Tanzanian shilling
      case "TZS":
        return Flag.fromCode(FlagsCode.TZ, height: 18, width: 18);

    // Ugandan shilling
      case "UGX":
        return Flag.fromCode(FlagsCode.UG, height: 18, width: 18);

    // Zambian kwacha
      case "ZMW":
        return Flag.fromCode(FlagsCode.ZM, height: 18, width: 18);

    // Existing logic for global currencies
      case "USD":
        return Flag.fromCode(FlagsCode.US, height: 18, width: 18);
      case "GBP":
        return Flag.fromCode(FlagsCode.GB_ENG, height: 18, width: 18);
      case "EUR":
        return Flag.fromCode(FlagsCode.EU, height: 18, width: 18);
      case "CAD":
        return Flag.fromCode(FlagsCode.CA, height: 18, width: 18);

    // Crypto
      case "USDT":
        return Image.asset('assets/tether.png', height: 18, width: 18);
      case "USDC":
        return Image.asset('assets/usdc.png', height: 18, width: 18);
      case "CBC":
        return Image.asset('assets/carbon.png', height: 18, width: 18);

    // Default fallback
      default:
        return Text(currencyCode);
    }

  }

// Helper method to truncate text
  String _truncateText(String text, int maxLength) {
    return text.length <= maxLength
        ? text
        : "${text.substring(0, maxLength)}...";
  }


  void _showWalletBottomSheet(GeneralWalletProvider walletProvider) {
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
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final w = walletProvider.wallets[index];
                    final isSelected = index == walletProvider.currentWalletIndex;

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
                        tileColor: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        leading: _buildCurrencyIcon(w['currency_code']),
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
                                  NumberFormat("#,##0.00").format(w["balance"] ?? 0.0),
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
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                        onTap: () {
                          walletProvider.selectWallet(index);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GeneralWalletProvider>().loadWallets();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<WalletTransactionController>(context, listen: false)
            .fetchWalletTransactions(refresh: false);
      });
    }

    setState(() {
      _userProfileFuture = Future.value(profile);
    });
  }


  Future<void> _refreshProfileX() async {
    final profile = await ProfileController.fetchUserProfile(); // Wait for profile

    await _loadPrimaryColorAndLogo(); // Wait
    await _loadAppSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });
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
        _displayName = "Hi, "+test! ;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    _loadAppSettings();
    _loadSettingsAndMenus();
    _loadCurrencies();
    _checkStoredUsername();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });


    //loadCacheWallet();

    _userProfileFuture =  ProfileController.fetchUserProfile().then((profile) async {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GeneralWalletProvider>().loadWallets();
      });
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

/*
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        _refreshProfile();
      }else{

      }
    });

 */
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
      // Clear the wallet data cache
      await WalletDataCache.clearCache();

      // Navigate to the login page
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



  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');



    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      setState(() {
        _menuItems = {
          ...?orgData['data']?['customized_app_displayable_menu_items'],
        };
      });
    }


  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralWalletProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button

        title: Text(_displayName,style: GoogleFonts.inter(fontSize: 18,fontWeight: FontWeight.w800),),
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

          child: provider!=null? FutureBuilder<Map<String, dynamic>?>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _alreadyOpen==true? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      provider.hasError?_buildWalletCardUnified(): provider.hasWallets?_buildWalletCardUnified(): _buildWalletCardUnified(),



                      const SizedBox(height: 2),
                      RecommendedSection(),
                     // const QuickActionsGrid(),

                      //  _buildGraph(),
                      const SizedBox(height: 5),
                      const TransactionList(),
                      const SizedBox(height: 16),


                    ],
                  ),
                ):provider.hasCachedWallets ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      provider.hasError?_buildWalletCardUnified(): provider.hasWallets?_buildWalletCardUnified(): _buildWalletCardUnified(),




                      const SizedBox(height: 2),
                     // const QuickActionsGrid(),

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
                      provider.hasError?_buildWalletCardUnified(): provider.hasWallets?_buildWalletCardUnified(): _buildWalletCardUnified(),


                      const SizedBox(height: 2),
                      /*
                      if (_showBanner && _ads.isNotEmpty) ...[
                        AdCarousel(ads: _ads),
                        const SizedBox(height: 16),
                      ],

                       */

                      RecommendedSection(),


                     // const QuickActionsGrid(),
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
                    provider.hasError?_buildWalletCardUnified(): provider.hasWallets?_buildWalletCardUnified(): _buildWalletCardUnified(),

                    const SizedBox(height: 2),

                    /*
                    if (_showBanner && _ads.isNotEmpty) ...[
                      AdCarousel(ads: _ads),
                      const SizedBox(height: 16),
                    ],

                     */

                    RecommendedSection(),


                 //   const QuickActionsGrid(),
                    //    _buildGraph(),
                    const SizedBox(height: 5),
                    const TransactionList(),
                    const SizedBox(height: 16),


                  ],
                ),
              );
            },
          ):Container(),
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
  Color _primaryColor=Color(0xFFFF9800);
  Color _secondaryColor=Colors.teal;
  Map<String, dynamic> _menuItems = {};


  // Get organization features

  bool isVtuEnabled = false;
  bool isFixedDepositEnabled = false;
  bool isLoanEnabled = false;
  bool isInvestmentEnabled = false;
  bool isTarget_Savings_Enabled=false;
  bool isBNPLEnabled = false;
  bool isCustomerMgtEnabled = false;
  bool isMobileMoney=false;
  bool Solarcoin=false;

  bool electricity=false;

  bool airtime=false;

  bool data=false;

  bool cable=false;

  bool loan=false;

  bool investment=false;

  bool ts=false;

  bool crypto=false;

  bool bnpl=false;



  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#FF9800';

      setState(() {
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      setState(() {
        _menuItems = {
          ...?orgData['data']?['customized_app_displayable_menu_items'],
        };
      });
    }

  }

  Future<void> _buildVisibleMenuCards() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      isVtuEnabled = orgData['data']?['organization_subscribed_features']?['vtu-mgt'] ?? false;
      isFixedDepositEnabled = orgData['data']?['organization_subscribed_features']?['fixed-deposit-mgt'] ?? false;
      isLoanEnabled = orgData['data']?['organization_subscribed_features']?['loan-mgt'] ?? false;
      isInvestmentEnabled = orgData['data']?['organization_subscribed_features']?['investment-mgt'] ?? false;
      isTarget_Savings_Enabled = orgData['data']?['organization_subscribed_features']?['target-saving-mgt'] ?? false;

      isBNPLEnabled = orgData['data']?['organization_subscribed_features']?['properties-mgt'] ?? false;
      isCustomerMgtEnabled = orgData['data']?['organization_subscribed_features']?['customers-mgt'] ?? false;

      isMobileMoney=orgData['data']?['organization_subscribed_features']?['cross-border-payment-mgt'] ?? false;

      Solarcoin=orgData['data']?['organization_subscribed_features']?['customized-currency-mgt'] ?? false;

    }










    // Only show VTU-related menus if vtu-mgt is enabled
    if (isVtuEnabled) {
      if (_menuItems['display-electricity-menu'] == true) {
        electricity=true;
      }
      if (_menuItems['display-airtime-menu'] == true) {
        airtime=true;
      }
      if (_menuItems['display-data-menu'] == true) {
        data=true;
      }
      if (_menuItems['display-cable-tv-menu'] == true) {
        cable=true;
      }
    }

    // Only show loan if enabled
    if (isLoanEnabled) {
      if (_menuItems['display-loan-menu'] == true) {
        loan=true;
      }
    }

    // Only show Investment if enabled
    if (isInvestmentEnabled) {
      if (_menuItems['display-investment-menu'] == true) {
        investment=true;
      }
    }

    if (isTarget_Savings_Enabled) {
      ts=true;

    }
    if (_menuItems['display-crypto-exchange-menu'] == true) {
      crypto=true;
    }

    // Only show BNLP if enabled
    if (isBNPLEnabled) {
      if (_menuItems['display-buy-now-pay-later-menu'] == true) {
        bnpl=true;
      }
    }




  }



  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();


    _loadSettingsAndMenus();
    _buildVisibleMenuCards();


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
              const SizedBox(height: 10),

              // Wallet to Wallet Transfer option

              if(airtime)
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

              if(data)
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
              const SizedBox(height: 10),


              if(electricity)
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
              const SizedBox(height: 10),


              if(cable)
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

          if(primaryColorHex!=null) {
            _primaryColor = Color(int.parse(primaryColorHex.replaceAll(
                '#', '0xFF'))); // Changed to null instead of default
          }

          if(secondaryColorHex!=null) {
            _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
          }


        });
      } catch (_) {
        // If there's an error parsing, use default colors

      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return  Padding(
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

              if(isVtuEnabled)

                _buildAnimatedButton(

                    route: () {
                      _showTransferOptions(context);
                    },

                    'Pay Bills', FontAwesomeIcons.receipt,
                    _secondaryColor!.withOpacity(0.5), 2),




              if(loan)

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


              if(crypto)
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
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}


void snacklen(String s) {

  SmartDialog.showToast(s,alignment:Alignment.center );


}
