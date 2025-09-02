import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';


import '../pages/quick_action/wallet_to_bank.dart';
import '../pages/quick_action/wallet_to_wallet.dart';
import '../pages/success/widget/FundWalletPage.dart';
import '../pages/success/widget/MoneyConverterPage.dart';


class QuickActionsOne extends StatefulWidget {
  const QuickActionsOne({super.key});

  @override
  State<QuickActionsOne> createState() => _QuickActionsListState();
}

class _QuickActionsListState extends State<QuickActionsOne> {
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadSecondaryColor();
  }

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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,


        children: [

        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMenuCard(

              context, icon: Icons.add, label: "Fund wallets", route: (){
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: FundWalletPage(),
                withNavBar: true,
              );
            }

            ),
            _buildMenuCard(
              context, icon: FontAwesomeIcons.arrowsRotate, label: "Convert", route: (){
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: MoneyConverterPage(),
                withNavBar: false,
              );


            }
            ),
            _buildMenuCard(
                context, icon: FontAwesomeIcons.paperPlane, label: "Send", route: (){
              _showTransferOptions(context);

            }
            ),


            _buildMenuCard(
              context, icon: FontAwesomeIcons.userPlus, label: "+Beneficiary", route: (){

            }


            ),
          ],
        ),
      ],),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String label, required Null Function() route}) {
    return GestureDetector(
      onTap: route,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primaryColor!.withOpacity(0.1), // same purple bg as screenshot
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
                "Choose Transfer Option",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.wallet, color: _secondaryColor),
                title: const Text("Wallet to Wallet"),
                onTap: () {
                  Navigator.pop(context);
                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: RouteSettings(name: '/transfer'),
                    screen: WalletToWalletTransferPage(),
                    withNavBar: true,
                  );

                },
              ),
              ListTile(
                leading: Icon(FontAwesomeIcons.piggyBank, color: _secondaryColor),
                title: const Text("Wallet to Bank"),
                onTap: () {
                  Navigator.pop(context);

                  PersistentNavBarNavigator.pushNewScreenWithRouteSettings(
                    context,
                    settings: RouteSettings(name: '/bank_transfer'),
                    screen: WalletToBankTransferPage(),
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
}
