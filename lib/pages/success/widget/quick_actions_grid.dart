import 'dart:convert';
import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/newdesigns/SendMoneyScreen.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/CacVerificationController.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../newdesigns/ReceiveMoneyScreen.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  final CacVerificationController _CacVerificationController = CacVerificationController();
  Map<String, dynamic> _menuItems = {};
  List<Widget> _menuCards = [];
  bool _showAllCards = false;
  Color? _primaryColor;
  Color _secondaryColor=Colors.purple;



  // Fetch colors from SharedPreferences
  Future<void> _loadSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? '#171E3B'; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ?? '#EB6D00'; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSecondaryColor();

    _loadSettingsAndMenus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });
  }

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

    final cards = await _buildVisibleMenuCards();
    setState(() {
      _menuCards = cards;
    });
  }

  Future<void> _handleCorporateNavigation(BuildContext context) async {
    try {
      await _CacVerificationController.fetchWallets();

      final wallets = _CacVerificationController.wallets ?? [];

      final hasCorporate = wallets.any((wallet) =>
      wallet['ownership_type'] == 'corporate-wallet'
      );

      if (hasCorporate) {
        Navigator.pushNamed(context, Routes.dashboard);
      } else {
        Navigator.pushNamed(context, Routes.corporate);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching wallets: $e")),
      );
    }
  }

  Future<List<Widget>> _buildVisibleMenuCards() async {
    final List<Widget> cards = [];
    int index = 0;

    // Get organization features
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');
    bool isVtuEnabled = false;
    bool isFixedDepositEnabled = false;
    bool isLoanEnabled = false;
    bool isInvestmentEnabled = false;
    bool isTarget_Savings_Enabled=false;
    bool isBNPLEnabled = false;
    bool isCustomerMgtEnabled = false;
    bool isMobileMoney=false;


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
    }
    // Add individual wallet transfer icon

    if (isCustomerMgtEnabled) {


      if (_menuItems['display-wallet-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.wallet, label: "To Wallet", route: Routes.transfer, index: index++));
      }

      // Add individual bank transfer icon
      if (_menuItems['display-bank-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.send_sharp, label: "To Bank", route: Routes.bank_transfer, index: index++));
      }

      if (_menuItems['display-fiat-crypto-conversion-options'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.swap_horiz_sharp, label: "Swap", route: Routes.swap, index: index++));
      }



      if (_menuItems['display-corporate-account-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.business_center, label: "Corporate", route: Routes.corporate, index: index++));
      }
    }

    if(isMobileMoney){
      if (_menuItems['display-send-mobile-money'] == true) {
        cards.add(_buildMenuCard(context, icon: CupertinoIcons.arrow_up_circle_fill, label: "Send Momo", route: Routes.corporate, index: index++));
      }
      if (_menuItems['display-receive-mobile-money'] == true) {
        cards.add(_buildMenuCard(context, icon: CupertinoIcons.arrow_down_circle_fill, label: "Receive Momo", route: Routes.corporate, index: index++));
      }
    }



    // Only show VTU-related menus if vtu-mgt is enabled
    if (isVtuEnabled) {
      if (_menuItems['display-electricity-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.electric_bolt, label: "Electricity", route: Routes.electric, index: index++));
      }
      if (_menuItems['display-airtime-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.phone_android_outlined, label: "Airtime", route: Routes.airtime, index: index++));
      }
      if (_menuItems['display-data-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.wifi, label: "Data", route: Routes.data_purchase, index: index++));
      }
      if (_menuItems['display-cable-tv-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.tv_outlined, label: "Cable Tv", route: Routes.cable_tv, index: index++));
      }
    }

    // Only show loan if enabled
    if (isLoanEnabled) {
      if (_menuItems['display-loan-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.money, label: "Loans", route: Routes.loan, index: index++));
      }
    }

    // Only show Investment if enabled
    if (isInvestmentEnabled) {
      if (_menuItems['display-investment-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_outlined, label: "Investment", route: Routes.investment, index: index++));
      }
    }

    if (isTarget_Savings_Enabled) {
      cards.add(_buildMenuCard(context, icon: CupertinoIcons.scope, label: "Target Savings", route: Routes.target_savings, index: index++));

    }
    if (_menuItems['display-crypto-exchange-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.currency_bitcoin, label: "Crypto", route: Routes.crypto, index: index++));
    }

    // Only show BNLP if enabled
    if (isBNPLEnabled) {
      if (_menuItems['display-buy-now-pay-later-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.card_giftcard_outlined, label: "BNPL", route: Routes.borrow, index: index++));
      }
    }

    // Only show fixed deposit menu if fixed-deposit-mgt is enabled
    if (isFixedDepositEnabled) {
      if (_menuItems['display-fixed-deposit-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_outlined, label: "Fixed Deposit", route: Routes.fixed, index: index++));
      }
    }

    // If we have 7 or more cards, replace the last visible one with "See More"
    if (cards.length >= 7) {
      cards.removeAt(6); // Remove the 7th item
      cards.add(_buildMenuCard(
        context,
        icon: Icons.apps_rounded,
        label: "Others",
        route: Routes.more_menu,
        index: index,
      ));
    }

    return cards;
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

    // Default fallback
      default:
        return Text(currencyCode);
    }

  }



  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        String? route,
        required int index,
      }) {

    final provider = Provider.of<GeneralWalletProvider>(context, listen: false);


    return GestureDetector(
      onTap: () async {
        // Add haptic feedback for iOS-like experience
        HapticFeedback.lightImpact();

        if(label=="Send Momo"){
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
                        itemCount: provider.fiatWallets.length,
                        itemBuilder: (context, index) {
                          final w = provider.fiatWallets[index];

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
                            //  trailing: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                              onTap: () {
                                //walletProvider.selectWallet(index);

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SendMoneyScreen(wallet: w)),
                                );

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
        else if(label=="Receive Momo"){
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
                        itemCount: provider.fiatWallets.length,
                        itemBuilder: (context, index) {
                          final w = provider.fiatWallets[index];

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
                              //  trailing: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                              onTap: () {
                                //walletProvider.selectWallet(index);

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ReceiveMoneyScreen(wallet: w)),
                                );

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

        else if (label == "Corporate Account") {
          try {
            await _CacVerificationController.fetchWallets();
            final wallets = _CacVerificationController.wallets ?? [];

            final hasCorporate = wallets.any((wallet) =>
            wallet['ownership_type'] == 'corporate-wallet'
            );

            if (hasCorporate) {
              Navigator.pushNamed(context, Routes.corporate_account);
            } else {
              Navigator.pushNamed(context, Routes.corporate);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching wallets: $e")),
            );
          }
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Coming next on our upgrade...\nStart building your credit score to be the first to benefit from the service by transacting more",
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _secondaryColor.withOpacity(0.3)),
              // iOS-style shadow

            ),
            child: Center(
              child: Icon(
                icon,
                color: _secondaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1C1C1E), // iOS system text color
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.linear(1.0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.9,
        children: _menuCards,
      ),
    );
  }
}