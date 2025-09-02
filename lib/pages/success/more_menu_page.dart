import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/controller/CacVerificationController.dart';

class MoreMenuPage extends StatefulWidget {
  const MoreMenuPage({super.key});

  @override
  State<MoreMenuPage> createState() => _MoreMenuPageState();
}

class _MoreMenuPageState extends State<MoreMenuPage> {
  final CacVerificationController _CacVerificationController = CacVerificationController();
  Color _primaryColor = const Color(0xFF2BBBA4);
  Color _secondaryColor = const Color(0xFFFF9800);
  Map<String, dynamic> _menuItems = {};
  List<Widget> _menuCards = [];
  bool _showBanner = false;
  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMenus();
  }

  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');
    final userProfileRaw = prefs.getString('userProfileRaw');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final primaryColorHex = settings['customized-app-primary-color'] ?? '#2BBBA4';
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#FF9800';

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
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

    _menuCards = await _buildAllMenuCards();
    setState(() {});
  }

  Future<List<Widget>> _buildAllMenuCards() async {
    final List<Widget> cards = [];
    int index = 0;

    // Get organization features
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');
    bool isVtuEnabled = false;
    bool isFixedDepositEnabled = false;
    bool isLoanEnabled = false;
    bool isInvestmentEnabled = false;
    bool isBNPLEnabled = false;
    bool isCustomerMgtEnabled = false;
    bool isTarget_Savings_Enabled=false;

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      isVtuEnabled = orgData['data']?['organization_subscribed_features']?['vtu-mgt'] ?? false;
      isFixedDepositEnabled = orgData['data']?['organization_subscribed_features']?['fixed-deposit-mgt'] ?? false;
      isLoanEnabled = orgData['data']?['organization_subscribed_features']?['loan-mgt'] ?? false;
      isInvestmentEnabled = orgData['data']?['organization_subscribed_features']?['investment-mgt'] ?? false;
      isBNPLEnabled = orgData['data']?['organization_subscribed_features']?['properties-mgt'] ?? false;
      isCustomerMgtEnabled = orgData['data']?['organization_subscribed_features']?['customers-mgt'] ?? false;
      isTarget_Savings_Enabled = orgData['data']?['organization_subscribed_features']?['target-saving-mgt'] ?? false;

    }
    // Add individual wallet transfer icon


    if (isCustomerMgtEnabled) {
      /*
      if (_menuItems['display-wallet-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.wallet, label: "Wallet transfer", route: Routes.transfer, index: index++));
      }

      // Add individual bank transfer icon
      if (_menuItems['display-bank-transfer-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.swap_horiz, label: "Other bank ", route: Routes.bank_transfer, index: index++));
      }

       */

      if (_menuItems['display-corporate-account-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.business, label: "Corporate", route: Routes.corporate, index: index++));
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

    // Only show BNLP if enabled
    if (isBNPLEnabled) {
      if (_menuItems['display-buy-now-pay-later-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.card_giftcard_outlined, label: "BNPL", route: Routes.borrow, index: index++));
      }
    }


    // Only show fixed deposit menu if fixed-deposit-mgt is enabled
    if (isFixedDepositEnabled) {
      if (_menuItems['display-fixed-deposit-menu'] == true) {
        cards.add(_buildMenuCard(context, icon: Icons.account_balance_outlined, label: "fixed deposit", route: Routes.fixed, index: index++));
      }
    }
    if (isTarget_Savings_Enabled) {
      cards.add(_buildMenuCard(context, icon: CupertinoIcons.scope, label: "Target Savings", route: Routes.target_savings, index: index++));

    }
    if (_menuItems['display-crypto-exchange-menu'] == true) {
      cards.add(_buildMenuCard(context, icon: Icons.currency_bitcoin, label: "Crypto", route: Routes.crypto, index: index++));
    }



    // If we have 7 or more cards, replace the last visible one with "See More"
    

    return cards;
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        String? route,
        required int index,
      }) {
    return GestureDetector(

      onTap: () async {
        // Add haptic feedback for iOS-like experience
        HapticFeedback.lightImpact();

        if (label == "Corporate Account") {
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


      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _secondaryColor!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _secondaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: _secondaryColor!.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );





      GestureDetector(
      onTap: () async {
        // Add haptic feedback for iOS-like experience
        HapticFeedback.lightImpact();

        if (label == "Corporate Account") {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                // iOS-inspired background with subtle gradient

                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1C1C1E),
                  width: 0.6,
                ),
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
      ),
    );
  }


  void _showTransferOptions(BuildContext context) {
    final showWallet = _menuItems['display-wallet-transfer-menu'] == true;
    final showBank = _menuItems['display-bank-transfer-menu'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Choose Transfer Type",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (showWallet)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.transfer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Wallet Transfer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            if (showWallet && showBank) const SizedBox(height: 10),
            if (showBank)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.bank_transfer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Bank Transfer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Services',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _menuCards.isEmpty
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: _menuCards,
                ),
                if (_showBanner && _ads.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AdCarousel(ads: _ads),
                  const SizedBox(height: 16),
                ],
              ],
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
  final PageController _controller = PageController(viewportFraction: 1.0);
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
                      Expanded(
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

