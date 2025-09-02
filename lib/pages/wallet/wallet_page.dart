import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/fx_wallet_page.dart';
import 'screens/crypto_wallet_page.dart';
import 'package:gobeller/utils/routes.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canCreateCryptoWallet = false;

  @override
  void initState() {
    super.initState();
    _checkFxWalletCreationEnabled();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _checkFxWalletCreationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        setState(() {
          _canCreateCryptoWallet =  orgData['data']?['customized_app_displayable_menu_items']?['display-crypto-exchange-menu'] ?? false;
        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _canCreateCryptoWallet = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _canCreateCryptoWallet? Scaffold(
      appBar: AppBar(
        title: const Text("Wallets"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Fiat"), Tab(text: "Crypto")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [FXWalletPage(), CryptoWalletPage(menu: false,)],
      ),

    ):Scaffold(

      body: FXWalletPage(),
    );
  }
}
