import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/newdesigns/FundCard.dart';
import 'package:gobeller/newdesigns/SendMoneyScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controller/organization_controller.dart';
import '../../../newdesigns/ReceiveMoneyScreen.dart';
import '../../../newdesigns/wallet_to_bank_intent.dart';
import '../../../newdesigns/wallet_to_wallet_intent.dart';
import '../../../service/VirtualAccountService.dart';
import 'CryptoReceivePage.dart';
import 'CryptoSwapPage.dart';
import 'CryptoTransferPage.dart';
import 'VirtualAccountRequestForm.dart';

class CryptoWalletDetailPage extends StatefulWidget {
  final Map<String, dynamic> wallet;


  const CryptoWalletDetailPage({super.key, required this.wallet});

  @override
  State<CryptoWalletDetailPage> createState() => _CryptoWalletDetailPageState();
}

class _CryptoWalletDetailPageState extends State<CryptoWalletDetailPage> {

  Map<String, dynamic> _menuItems = {};


  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#FF9800';


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

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMenus();

  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.wallet["currency_code"] ?? "Crypto";
    final balance = widget.wallet["balance"]?.toString() ?? "0";
    final address = widget.wallet["wallet_address"] ?? widget.wallet["wallet_number"] ?? "Unavailable";
    final network = widget.wallet["currency_network"] ?? "Unknown";
    final name = widget.wallet["label"] ?? "Unnamed Wallet";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("$currency Wallet"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Section
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
                    "Current Balance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    balance,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Wallet Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Wallet Details",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow("Name/Owner", name),
                  const SizedBox(height: 16),
                  _buildDetailRow("Network", network),
                  const SizedBox(height: 16),
                  _buildDetailRow("Address", address, isAddress: true),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
// Action Buttons
            Row(
              children: [
                if (_menuItems['display-send-crypto-menu'] == true)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),  // Half of the total spacing
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CryptoTransferPage(wallet: widget.wallet),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                        label: const Text(
                          "Send",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 1,
                          shadowColor: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),

                if (_menuItems['display-receive-crypto-menu'] == true)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),  // Balanced spacing
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CryptoReceivePage(wallet: widget.wallet),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                        label: const Text(
                          "Receive",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 1,
                          shadowColor: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),

              ],
            )          ],
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value, {bool isAddress = false}) {
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),

        ),
      ],
    );
  }
}



class FiatWalletDetailPage extends StatefulWidget {
  final Map<String, dynamic> wallet;


  const FiatWalletDetailPage({super.key, required this.wallet});

  @override
  State<FiatWalletDetailPage> createState() => _FiatWalletDetailPageState();
}

class _FiatWalletDetailPageState extends State<FiatWalletDetailPage> {

  Map<String, dynamic> _menuItems = {};

  bool isLoading=false;

  bool _hasExistingRequest = false;
  Map<String, dynamic>? _existingRequestData;
  bool _isCheckingExistingRequest = true;

  String? errorMessage;

  bool mobilemoney_receive=false;

  bool mobilemoney_send=false;

  bool wallet_transfer=false;

  bool bank_transfer=false;
  bool isMobileMoney=false;


  Future<void> _loadSettingsAndMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    final orgJson = prefs.getString('organizationData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final secondaryColorHex = settings['customized-app-secondary-color'] ?? '#FF9800';


    }

    if (orgJson != null) {
      final orgData = json.decode(orgJson);
      setState(() {
        _menuItems = {
          ...?orgData['data']?['customized_app_displayable_menu_items'],
        };
      });
    }
    // Check if user has USD virtual account requests

  }

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMenus();
    _checkForExistingRequest();
    _loadOptions();
    // Check if user has USD virtual account requests


  }

  Future<void> _checkForExistingRequest() async {
    setState(() {
      _isCheckingExistingRequest = true;
    });

    try {
      // Step 1: Check if user has any request for this currency
      final hasRequest = await VirtualAccountService.hasRequestForCurrency(widget.wallet["currency_code"]);

      if (hasRequest) {
        _hasExistingRequest = true;

        // Step 2: Get the actual request data for display
        final requestData = await VirtualAccountService.getLatestRequestForCurrency(widget.wallet["currency_code"]);

        if (requestData != null) {
          setState(() {
            _existingRequestData = requestData;
            _isCheckingExistingRequest = false;
          });

          debugPrint("User has existing ${widget.wallet["currency_code"]} virtual account request");
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

        debugPrint("No existing ${widget.wallet["currency_code"]} virtual account request found");
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
      /*
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking existing requests. Please try again.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _checkForExistingRequest,
            ),
          ),
        );
      }

       */
    }
  }

  Future<void> _loadOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        final menuItems = orgData['data']?['customized_app_displayable_menu_items'];

        setState(() {
          mobilemoney_receive = menuItems?['display-receive-mobile-money'] ?? false;
          mobilemoney_send = menuItems?['display-send-mobile-money'] ?? false;
          wallet_transfer=menuItems?['display-wallet-transfer-menu']??false;
          bank_transfer=menuItems?['display-bank-transfer-menu']??false;
          isMobileMoney=menuItems?['cross-border-payment-mgt']??false;



        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          mobilemoney_receive = false;
          mobilemoney_send = false;
          wallet_transfer=false;
          bank_transfer=false;
          isMobileMoney=false;

        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currency = widget.wallet["currency_code"] ?? "";
    final balance = widget.wallet["balance"]?.toString() ?? "0";
    final accountNumber = widget.wallet["wallet_number"] ?? widget.wallet["wallet_number"] ?? "Unavailable";
    final bankName=widget.wallet["bank_name"] ?? widget.wallet["bank_name"] ?? "Unavailable";
    final name = widget.wallet["name"] ?? "Unnamed Wallet";
    final code = widget.wallet['currency_code']??"---";

    final String formattedBalance = NumberFormat("#,##0.00")
        .format(double.tryParse(balance) ?? 0.0);



    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("$currency Wallet"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    "Current Balance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedBalance,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),



            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [


                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Account details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),


                        // Account Name Field
                        _buildDetailRowX(
                          label: 'Account name',
                          value: name,
                        ),

                        const SizedBox(height: 24),

                        // Account Number Field
                        Column(
                          children: [
                            _buildDetailRowX(
                              label:accountNumber.length<13? 'Account number':"Account number",
                              value: accountNumber.length<13? accountNumber:accountNumber.substring(0,10)+"..."+getLastFourDigits(accountNumber),
                            ),
                            const SizedBox(height: 24),



                          ],
                        ),

                        currency.toUpperCase() != "NGN" ?Container() :_buildDetailRowX(
                          label:"Bank name",
                          value: bankName,
                        ),

                        currency.toUpperCase() == "NGN" ||currency.toUpperCase() == "KES"  ?Container():  _isCheckingExistingRequest?Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 1.5,),):Container(),

                        currency.toUpperCase() == "KES"? _buildActiveAccountSectionKES(widget.wallet):_existingRequestData != null?_buildRequestStatus():Container(),


                      ],
                    ),
                  ),
                  SizedBox(height: 24,),


                ],
              ),
            ),
            const SizedBox(height: 24),


          //  currency.toUpperCase() == "USD" ||currency.toUpperCase() == "EUR"||currency.toUpperCase() == "GBP" || (mobilemoney_receive==true && currency.toUpperCase() != "NGN") ?  Container(
            currency.toUpperCase() == "USD" ||currency.toUpperCase() == "EUR"||currency.toUpperCase() == "GBP" || (mobilemoney_receive==true && currency.toUpperCase() != "NGN") ?  Container(

            width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Add money',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),



                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.credit_card, color: Colors.blue),
                    ),
                    title: Text('Fund $currency Wallet With Card'),
                    subtitle: Text('Add money using your card'),
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FundCard(wallet: widget.wallet),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 10,),

                  mobilemoney_receive==true?ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(Icons.payment, color: Colors.orange),
                    ),
                    title: Text('Receive via Mobile Money'),
                    subtitle: Text('Add money through mobile money'),
                    onTap: () {
                      //  Navigator.pop(context);
                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: ReceiveMoneyScreen(wallet: widget.wallet,),
                        withNavBar: true,
                      );



                      //  _showComingSoon('Receive Payment');
                    },
                  ):Container(),

                  mobilemoney_receive==true?SizedBox(height: 10,):Container(),

                  _isCheckingExistingRequest?Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 1.5,),) :_hasExistingRequest==false?  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(Icons.payment, color: Colors.orange),
                    ),
                    title: Text('Request $currency Account'),
                    subtitle: Text('Get money from others'),
                    onTap: () {
                      //  Navigator.pop(context);
                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: VirtualAccountRequestForm(code: code,),
                        withNavBar: true,
                      );



                      //  _showComingSoon('Receive Payment');
                    },
                  ):Container(),

                  const SizedBox(height: 24),

                  /*
                  _existingRequestData != null?_buildRequestStatus():Container(),

                  SizedBox(height: 24,),


                   */



                ],
              ),
            ):Container(),


            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Send money',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),



                  wallet_transfer?ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.credit_card, color: Colors.blue),
                    ),
                    title: Text('Wallet Transfer'),
                    //subtitle: Text('Add money using your card'),
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalletToWalletTransferPageIntent(wallet: widget.wallet),
                        ),
                      );
                    },
                  ):Container(),





                  SizedBox(height: 24,),

                  bank_transfer?ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.credit_card, color: Colors.blue),
                    ),
                    title: Text('Nigeria Bank Transfer'),
                    //subtitle: Text('Add money using your card'),
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalletToBankTransferPageIntent(wallet: widget.wallet),
                        ),
                      );
                    },
                  ):Container(),

                  SizedBox(height: 24,),


                  mobilemoney_send==true && currency.toUpperCase() != "NGN"?ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.credit_card, color: Colors.blue),
                    ),
                    title: Text('Send via Mobile Money'),
                    //subtitle: Text('Add money using your card'),
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendMoneyScreen(wallet: widget.wallet),
                        ),
                      );
                    },
                  ):Container(),

                  SizedBox(height: 14,),

                ],
              ),
            ),

            // Bottom padding
            const SizedBox(height: 40),
          ],
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

  Widget _buildDetailRowX({required String label, required String value}) {
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final orgData = orgController.organizationData?['data'] ?? {};
    final name = orgData['short_name'] ?? '---';

    if(value.toLowerCase()=="unknown bank"){
      setState(() {
        value=name;
      });
    }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.length>22?value.substring(0,22)+"...":value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));

                  SmartDialog.showToast(label+" copied");
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowQ({required String label, required String value}) {
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final orgData = orgController.organizationData?['data'] ?? {};
    final name = orgData['short_name'] ?? '---';

    if(value.toLowerCase()=="unknown bank"){
      setState(() {
        value=name;
      });
    }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.length>22?value.substring(0,22)+"...":value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));

                  SmartDialog.showToast(label+" copied");
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),

            ],
          ),
        ),


      ],
    );
  }


  Widget _buildRequestStatus() {
    // Add proper null check first
    if (_existingRequestData == null) {
      return Center(child: Text('No request data available'));
    }

    final data = _existingRequestData!;
    final userRequestData = data['user_request_data'] ?? {};
    final status = data['status'] ?? {};
    final currency = data['currency'] ?? {};
    final wallet = data['wallet'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Fix string concatenation




        // Show different content based on wallet status
        if (wallet != null) ...[
          // Active Account - Show wallet details
          widget.wallet["currency_code"]=="USD"?_buildActiveAccountSectionUSD(data, wallet, currency):  _buildActiveAccountSection(data, wallet, currency),
        ] else ...[
          // Pending Request - Show request details
          _buildPendingRequestSection(data, userRequestData),
        ],


        /*
        SizedBox(height: 16),

        // Timeline (always show)
        _buildTimelineSection(data),

         */
        // ... rest of your code
      ],
    );
  }
  Widget _buildTimelineSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Request Created


        _buildDetailRowX(
          label: 'Request Submitted',
          value: _formatDate(data['created_at']) ?? 'N/A',
        ),


        SizedBox(height: 24),


        // For active accounts, show wallet creation date
        if (data['wallet'] != null) ...[

          _buildDetailRowX(
            label: 'Account Activated',
            value:  _formatDate(data['wallet']['created_at']) ?? 'N/A',
          ),
        ],
      ],
    );
  }
  String _formatBalance(String? balance, String? symbol) {
    if (balance == null) return 'N/A';
    double amount = double.tryParse(balance) ?? 0.0;
    return '${symbol ?? ''}${amount.toStringAsFixed(2)}';
  }

  String _formatOwnershipType(String? type) {
    if (type == null) return 'N/A';
    return type
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildActiveAccountSectionUSD(Map<String, dynamic> data, Map<String, dynamic> wallet, Map<String, dynamic> currency) {
    final wallet = data['wallet'];
    final providerMetadata = wallet['provider_metadata'];

    // Safely extract data
    dynamic rawData;
    if (providerMetadata is Map) {
      rawData = providerMetadata['data'];
    } else if (providerMetadata is String) {
      final decoded = jsonDecode(providerMetadata);
      rawData = decoded['data'];
    } else {
      print('Unexpected provider_metadata type: ${providerMetadata.runtimeType}');
    }

    // Ensure rawData is a Map
    if (rawData is! Map) {
      print('accountData is not a Map: ${rawData.runtimeType}');
    }

    final accountData = rawData as Map<String, dynamic>;

    // Primary account (ACH)
    final primaryAccount = {
      'accountNumber': accountData['accountNumber'] ?? 'N/A',
      'accountName': accountData['accountName'] ?? 'N/A',
      'bankName': accountData['bankName'] ?? 'N/A',
      'bankCode': accountData['bankCode'] ?? 'N/A',
      'countryCode': accountData['countryCode'] ?? 'N/A',
      'postalCode': accountData['postalCode'] ?? 'N/A',
      'reference': accountData['reference'] ?? 'N/A',
      'addressableIn': accountData['otherInfo'] != null ? accountData['otherInfo']['addressableIn'] ?? 'N/A' : 'N/A',
      'memo': accountData['otherInfo'] != null ? accountData['otherInfo']['memo'] ?? 'N/A' : 'N/A',
      'iban': accountData['otherInfo'] != null ? accountData['otherInfo']['iban'] ?? 'N/A' : 'N/A',
      'sortCode': accountData['otherInfo'] != null ? accountData['otherInfo']['sortCode'] ?? 'N/A' : 'N/A',
      'bankSwiftCode': accountData['otherInfo'] != null ? accountData['otherInfo']['bankSwiftCode'] ?? 'N/A' : 'N/A',
      'bankAddress': accountData['otherInfo'] != null ? accountData['otherInfo']['bankAddress'] ?? 'N/A' : 'N/A',
      'checkNumber': accountData['otherInfo'] != null ? accountData['otherInfo']['checkNumber'] ?? 'N/A' : 'N/A',
    };

    // Alternate accounts array
    final alternateAccounts = accountData['alternateAccountDetails'] as List;

    // Account 1 - SWIFT (Switzerland)
    final swiftAccount = alternateAccounts[0];
    final swiftAccountData = {
      'accountNumber': swiftAccount['accountNumber'] ?? 'N/A',
      'accountName': swiftAccount['accountName'] ?? 'N/A',
      'bankName': swiftAccount['bankName'] ?? 'N/A',
      'bankCode': swiftAccount['bankCode'] ?? 'N/A',
      'countryCode': swiftAccount['countryCode'] ?? 'N/A',
      'postalCode': swiftAccount['postalCode'] ?? 'N/A',
      'reference': swiftAccount['reference'] ?? 'N/A',
      'bankSwiftCode': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['bankSwiftCode'] ?? 'N/A' : 'N/A',
      'addressableIn': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['addressableIn'] ?? 'N/A' : 'N/A',
      'bankAddress': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['bankAddress'] ?? 'N/A' : 'N/A',
      'memo': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['memo'] ?? 'N/A' : 'N/A',
      'iban': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['iban'] ?? 'N/A' : 'N/A',
      'sortCode': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['sortCode'] ?? 'N/A' : 'N/A',
      'checkNumber': swiftAccount['otherInfo'] != null ? swiftAccount['otherInfo']['checkNumber'] ?? 'N/A' : 'N/A',
    };

    // Account 2 - FEDWIRE (US)
    final fedwireAccount = alternateAccounts[1];
    final fedwireAccountData = {
      'accountNumber': fedwireAccount['accountNumber'] ?? 'N/A',
      'accountName': fedwireAccount['accountName'] ?? 'N/A',
      'bankName': fedwireAccount['bankName'] ?? 'N/A',
      'bankCode': fedwireAccount['bankCode'] ?? 'N/A',
      'countryCode': fedwireAccount['countryCode'] ?? 'N/A',
      'postalCode': fedwireAccount['postalCode'] ?? 'N/A',
      'reference': fedwireAccount['reference'] ?? 'N/A',
      'addressableIn': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['addressableIn'] ?? 'N/A' : 'N/A',
      'bankAddress': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['bankAddress'] ?? 'N/A' : 'N/A',
      'memo': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['memo'] ?? 'N/A' : 'N/A',
      'iban': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['iban'] ?? 'N/A' : 'N/A',
      'sortCode': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['sortCode'] ?? 'N/A' : 'N/A',
      'bankSwiftCode': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['bankSwiftCode'] ?? 'N/A' : 'N/A',
      'checkNumber': fedwireAccount['otherInfo'] != null ? fedwireAccount['otherInfo']['checkNumber'] ?? 'N/A' : 'N/A',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountDetails(primaryAccount, 'US Bank Transfer'),
        SizedBox(height: 24),

        // Tab 2: SWIFT
        _buildAccountDetails(swiftAccountData, 'International Wire'),
        SizedBox(height: 24),

        // Tab 3: FEDWIRE
        _buildAccountDetails(fedwireAccountData, 'US Wire Transfer'),

        // Account Details
        SizedBox(height: 24),
      ],
    );
  }
  Widget _buildAccountDetails(Map<String, dynamic> accountData, String type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 24),



        // IBAN (mainly for European transfers)
        if (accountData['iban'] != null && accountData['iban'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'IBAN',
            value: accountData['iban']?.isEmpty == true ? 'N/A' : accountData['iban'],
          ),
          SizedBox(height: 24),
        ],

        // Bank Name
        _buildDetailRowX(
          label: 'Bank Name',
          value: accountData['bankName']?.isEmpty == true ? 'N/A' : (accountData['bankName'] ?? 'N/A'),
        ),
        SizedBox(height: 24),

        // Bank Code
        _buildDetailRowX(
          label: 'Bank Code',
          value: accountData['bankCode'] ?? 'N/A',
        ),
        SizedBox(height: 24),

        // Sort Code (mainly for UK transfers)
        if (accountData['sortCode'] != null && accountData['sortCode'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'Sort Code',
            value: accountData['sortCode']?.isEmpty == true ? 'N/A' : accountData['sortCode'],
          ),
          SizedBox(height: 24),
        ],

        // SWIFT Code for international transfers
        if (type == 'International Wire' || (accountData['bankSwiftCode'] != null && accountData['bankSwiftCode'] != 'N/A')) ...[
          _buildDetailRowX(
            label: 'SWIFT Code',
            value: accountData['bankSwiftCode']?.isEmpty == true ? 'N/A' : (accountData['bankSwiftCode'] ?? 'N/A'),
          ),
          SizedBox(height: 24),
        ],

        // Country Code
        if (accountData['countryCode'] != null && accountData['countryCode'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'Country Code',
            value: accountData['countryCode']?.isEmpty == true ? 'N/A' : accountData['countryCode'],
          ),
          SizedBox(height: 24),
        ],

        // Postal Code
        if (accountData['postalCode'] != null && accountData['postalCode'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'Postal Code',
            value: accountData['postalCode']?.isEmpty == true ? 'N/A' : accountData['postalCode'],
          ),
          SizedBox(height: 24),
        ],

        // Bank Address for wire transfers
        if (type == 'International Wire' || type == 'US Wire Transfer' || (accountData['bankAddress'] != null && accountData['bankAddress'] != 'N/A')) ...[
          _buildDetailRowX(
            label: 'Bank Address',
            value: accountData['bankAddress']?.isEmpty == true ? 'N/A' : (accountData['bankAddress'] ?? 'N/A'),
          ),
          SizedBox(height: 24),
        ],

        // Check Number
        if (accountData['checkNumber'] != null && accountData['checkNumber'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'Check Number',
            value: accountData['checkNumber']?.isEmpty == true ? 'N/A' : accountData['checkNumber'],
          ),
          SizedBox(height: 24),
        ],

        // Transfer Method
        _buildDetailRowX(
          label: 'Transfer Method',
          value: (accountData['addressableIn']?.isEmpty == true ? type : (accountData['addressableIn'] ?? type)),
        ),
        SizedBox(height: 24),

        // Reference
        if (accountData['reference'] != null && accountData['reference'] != 'N/A') ...[
          _buildDetailRowX(
            label: 'Reference',
            value: accountData['reference']?.isEmpty == true ? 'N/A' : accountData['reference'],
          ),
          SizedBox(height: 24),
        ],

        // Reference/Memo
        _buildDetailRowX(
          label: 'Reference/Memo',
          value: accountData['memo']?.isEmpty == true ? 'N/A' : (accountData['memo'] ?? 'N/A'),
        ),
      ],
    );
  }
  Widget _buildActiveAccountSection(Map<String, dynamic> data, Map<String, dynamic> wallet, Map<String, dynamic> currency) {
    final walletData = data['wallet'];
    final providerMetadata = walletData['provider_metadata'];

    // Safely extract data
    dynamic rawData;
    if (providerMetadata is Map) {
      rawData = providerMetadata['data'];
    } else if (providerMetadata is String) {
      try {
        final decoded = jsonDecode(providerMetadata);
        rawData = decoded['data'];
      } catch (e) {
        print('Error decoding provider_metadata JSON: $e');
        return SizedBox.shrink();
      }
    } else {
      print('Unexpected provider_metadata type: ${providerMetadata.runtimeType}');
      return SizedBox.shrink();
    }

    // Ensure rawData is a Map
    if (rawData is! Map) {
      print('accountData is not a Map: ${rawData.runtimeType}');
      return SizedBox.shrink();
    }

    final accountData = rawData as Map<String, dynamic>;

    // Primary account details
    final primaryAccount = {
      'accountNumber': accountData['accountNumber'] ?? 'N/A',
      'accountName': accountData['accountName'] ?? 'N/A',
      'bankName': accountData['bankName'] ?? 'N/A',
      'bankCode': accountData['bankCode'] ?? 'N/A',
      'countryCode': accountData['countryCode'] ?? 'N/A',
      'postalCode': accountData['postalCode'] ?? 'N/A',
      'reference': accountData['reference'] ?? 'N/A',
      'iban': accountData['otherInfo'] != null ? accountData['otherInfo']['iban'] ?? 'N/A' : 'N/A',
      'sortCode': accountData['otherInfo'] != null ? accountData['otherInfo']['sortCode'] ?? 'N/A' : 'N/A',
      'bankSwiftCode': accountData['otherInfo'] != null ? accountData['otherInfo']['bankSwiftCode'] ?? 'N/A' : 'N/A',
      'addressableIn': accountData['otherInfo'] != null ? accountData['otherInfo']['addressableIn'] ?? 'N/A' : 'N/A',
      'bankAddress': accountData['otherInfo'] != null ? accountData['otherInfo']['bankAddress'] ?? 'N/A' : 'N/A',
      'checkNumber': accountData['otherInfo'] != null ? accountData['otherInfo']['checkNumber'] ?? 'N/A' : 'N/A',
      'memo': accountData['otherInfo'] != null ? accountData['otherInfo']['memo'] ?? 'N/A' : 'N/A',
    };

    // Get alternate accounts if they exist
    final alternateAccounts = accountData['alternateAccountDetails'] as List?;
    Map<String, dynamic>? alternateAccount;

    if (alternateAccounts != null && alternateAccounts.isNotEmpty) {
      final alternate = alternateAccounts[0];
      alternateAccount = {
        'accountNumber': alternate['accountNumber'] ?? 'N/A',
        'accountName': alternate['accountName'] ?? 'N/A',
        'bankName': alternate['bankName'] ?? 'N/A',
        'bankCode': alternate['bankCode'] ?? 'N/A',
        'countryCode': alternate['countryCode'] ?? 'N/A',
        'postalCode': alternate['postalCode'] ?? 'N/A',
        'reference': alternate['reference'] ?? 'N/A',
        'iban': alternate['otherInfo'] != null ? alternate['otherInfo']['iban'] ?? 'N/A' : 'N/A',
        'sortCode': alternate['otherInfo'] != null ? alternate['otherInfo']['sortCode'] ?? 'N/A' : 'N/A',
        'bankSwiftCode': alternate['otherInfo'] != null ? alternate['otherInfo']['bankSwiftCode'] ?? 'N/A' : 'N/A',
        'addressableIn': alternate['otherInfo'] != null ? alternate['otherInfo']['addressableIn'] ?? 'N/A' : 'N/A',
        'bankAddress': alternate['otherInfo'] != null ? alternate['otherInfo']['bankAddress'] ?? 'N/A' : 'N/A',
        'checkNumber': alternate['otherInfo'] != null ? alternate['otherInfo']['checkNumber'] ?? 'N/A' : 'N/A',
        'memo': alternate['otherInfo'] != null ? alternate['otherInfo']['memo'] ?? 'N/A' : 'N/A',
      };
    }

    // Determine transfer type based on addressableIn
    String primaryTransferType = _getTransferType(primaryAccount['addressableIn']);
    String? alternateTransferType = alternateAccount != null
        ? _getTransferType(alternateAccount['addressableIn'])
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Account
        _buildAccountDetails(primaryAccount, primaryTransferType),

        // Alternate Account (if exists)
        if (alternateAccount != null) ...[
          SizedBox(height: 24),
          _buildAccountDetails(alternateAccount, alternateTransferType!),
        ],

        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActiveAccountSectionKES(Map<String, dynamic> wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRowX(
          label: 'Bank name',
          value: wallet['bank_name']?.isEmpty == true ? 'N/A' : wallet['bank_name'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Bank code',
          value: wallet['bank_code']?.isEmpty == true ? 'N/A' : wallet['bank_code'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Bank short code',
          value: wallet['bank_short_code']?.isEmpty == true ? 'N/A' : wallet['bank_short_code'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Bank swift code',
          value: wallet['bank_swift_code']?.isEmpty == true ? 'N/A' : wallet['bank_swift_code'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Bank branch code',
          value: wallet['bank_branch_code']?.isEmpty == true ? 'N/A' : wallet['bank_branch_code'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Bank address',
          value: wallet['bank_address']?.isEmpty == true ? 'N/A' : wallet['bank_address'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Currency code',
          value: wallet['currency_code']?.isEmpty == true ? 'N/A' : wallet['currency_code'],
        ),
        SizedBox(height: 24),

        _buildDetailRowX(
          label: 'Currency network',
          value: wallet['currency_network']?.isEmpty == true ? 'N/A' : wallet['currency_network'],
        ),
        SizedBox(height: 24),

        // Account Details
      ],
    );
  }  String _getTransferType(String? addressableIn) {
    switch (addressableIn?.toUpperCase()) {
      case 'FPS':
        return 'UK Faster Payments';
      case 'CHAPS':
        return 'UK CHAPS Transfer';
      case 'SWIFT':
        return 'International Wire';
      case 'SEPA':
        return 'SEPA Transfer';
      case 'ACH':
        return 'US Bank Transfer';
      case 'FEDWIRE':
        return 'US Wire Transfer';
      default:
        return 'Bank Transfer';
    }
  }



  Widget _buildPendingRequestSection(Map<String, dynamic> data, Map<String, dynamic> userRequestData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Request Information

        _buildDetailRowX(
          label: 'Status',
          value: '${data['status']['label']}',
        ),
        SizedBox(height: 24),




        _buildDetailRowX(
          label: 'Account Type',
          value: _formatAccountType(data['account_type']),
        ),
        SizedBox(height: 24),



        // Personal Information (from user_request_data if available)
      ],
    );
  }
  String _formatEmploymentStatus(String? status) {
    if (status == null) return 'N/A';

    switch (status.toLowerCase()) {
      case 'employed':
        return 'Employed';
      case 'unemployed':
        return 'Unemployed';
      case 'self_employed':
      case 'self-employed':
        return 'Self Employed';
      case 'student':
        return 'Student';
      case 'retired':
        return 'Retired';
      case 'freelancer':
        return 'Freelancer';
      case 'contractor':
        return 'Contractor';
      case 'business_owner':
      case 'business-owner':
        return 'Business Owner';
      default:
      // Fallback: capitalize first letter and replace underscores/hyphens with spaces
        return status
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String _formatIncomeSource(String? source) {
    if (source == null) return 'N/A';

    switch (source.toLowerCase()) {
      case 'business_income':
      case 'business-income':
        return 'Business Income';
      case 'salary':
        return 'Salary';
      case 'freelance':
      case 'freelancing':
        return 'Freelance Work';
      case 'investment':
      case 'investments':
        return 'Investments';
      case 'rental_income':
      case 'rental-income':
        return 'Rental Income';
      case 'pension':
        return 'Pension';
      case 'social_benefits':
      case 'social-benefits':
        return 'Social Benefits';
      case 'trading':
        return 'Trading';
      case 'consulting':
        return 'Consulting';
      case 'commission':
        return 'Commission';
      case 'royalties':
        return 'Royalties';
      case 'dividend':
      case 'dividends':
        return 'Dividends';
      case 'other':
        return 'Other';
      default:
      // Fallback: capitalize and format
        return source
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String _formatIdType(String? idType) {
    if (idType == null) return 'N/A';

    switch (idType.toLowerCase()) {
      case 'passport':
        return 'Passport';
      case 'national_id':
      case 'national-id':
        return 'National ID';
      case 'drivers_license':
      case 'drivers-license':
      case 'driver_license':
      case 'driver-license':
        return "Driver's License";
      case 'voter_id':
      case 'voter-id':
        return 'Voter ID';
      case 'nin':
        return 'NIN (National Identification Number)';
      case 'bvn':
        return 'BVN (Bank Verification Number)';
      case 'work_permit':
      case 'work-permit':
        return 'Work Permit';
      case 'residence_permit':
      case 'residence-permit':
        return 'Residence Permit';
      case 'military_id':
      case 'military-id':
        return 'Military ID';
      case 'student_id':
      case 'student-id':
        return 'Student ID';
      default:
      // Fallback: capitalize and format
        return idType
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String _formatAccountType(String? type) {
    return type?.replaceAll('_', ' ').toUpperCase() ?? 'N/A';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.contact_support),
              title: Text('Contact Support'),
              onTap: () {
                Navigator.pop(context);
                // Add contact support functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Download Details'),
              onTap: () {
                Navigator.pop(context);
                // Add download functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share Details'),
              onTap: () {
                Navigator.pop(context);
                // Add share functionality
              },
            ),
          ],
        ),
      ),
    );
  }

}