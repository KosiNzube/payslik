import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/newdesigns/BuyCarbonCoinPage.dart';
import 'package:gobeller/newdesigns/TradingAgentConfigScreen.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_to_bank_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';
import 'SellCarbonCoinPage.dart';

class CarbonCoin extends StatefulWidget {
  final Map<String, dynamic> wallet;

  CarbonCoin({super.key, required this.wallet});

  @override
  State<CarbonCoin> createState() => _CarbonCoinState();
}

class _CarbonCoinState extends State<CarbonCoin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? selectedBank;
  String? selectedBankId;

  bool isLoading = false;
  bool _isPinHidden = true; // Add this as a class-level variable if not already declared
  bool saveBeneficiary = false;

  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  List<Map<String, dynamic>> filteredSuggestions = [];
  bool showSuggestions = false;
  final formatter = NumberFormat('#,###');



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrimaryColorAndLogo();
    });


  }



  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    super.dispose();
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

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }
  String formatNumber(String input) {
    // Remove any commas before parsing
    String cleaned = input.replaceAll(',', '');
    int? number = int.tryParse(cleaned);
    if (number == null) return input; // Return as-is if not a number
    return formatter.format(number);
  }

















  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carbon Coin"),
        // actions: [
        //   TextButton.icon(
        //     icon: const Icon(Icons.people_alt_outlined, color: Colors.black),
        //     label: const Text(
        //       "Saved Beneficiary",
        //       style: TextStyle(color: Colors.black),
        //     ),
        //     onPressed: () {
        //       _showSavedBeneficiaries(context);
        //     },
        //   ),
        // ],
      ),



      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.all(32),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(color: Colors.grey[200]!),

                      ),

                      child: Column(

                        children: [

                          Text(

                            "Source Wallet",

                            style: TextStyle(

                              fontSize: 16,

                              color: Colors.grey[600],

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                          const SizedBox(height: 8),

                          Text(



                            widget.wallet['currency']+ NumberFormat("#,##0.00")

                                .format(double.tryParse(widget.wallet['balance'].toString())),





                            style: const TextStyle(

                              fontSize: 32,

                              fontWeight: FontWeight.bold,

                              color: Colors.black87,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            'Account: '+ widget.wallet['wallet_number'],textAlign: TextAlign.center,

                            style: TextStyle(

                              fontSize: 18,

                              color: Colors.grey[600],

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Column(
                          children: [
                            // Tournaments menu item
                            _buildMenuTile(
                              icon: CupertinoIcons.upload_circle,
                              title: 'Buy Carbon Coin',
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BuyCarbonCoinPage(wallet: widget.wallet)),
                                );
                              },
                            ),

                            // Divider
                            Container(
                              height: 0.5,
                              color: CupertinoColors.inactiveGray,
                              margin: const EdgeInsets.only(left: 56.0),
                            ),

                            // Date/Time menu item
                            _buildMenuTile(
                              icon: CupertinoIcons.download_circle,
                              title: 'Sell Carbon Coin',
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SellCarbonCoinPage(wallet: widget.wallet)),
                                );

                                },
                            ),

                            // Divider
                            Container(
                              height: 0.5,
                              color: CupertinoColors.inactiveGray,
                              margin: const EdgeInsets.only(left: 56.0),
                            ),

                            // All Fixtures menu item
                            _buildMenuTile(
                              icon: CupertinoIcons.checkmark_seal_fill,
                              title: 'Become an Agent',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TradingAgentConfigScreen(wallet: widget.wallet)),
                                );
                              },
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),




                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                size: 18,
                color: CupertinoColors.black,
              ),
            ),

            const SizedBox(width: 12.0),

            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.black,
                ),
              ),
            ),

            // Chevron
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.black,
            ),
          ],
        ),
      ),
    );
  }
}
