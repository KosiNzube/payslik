import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/newdesigns/FundCard.dart';
import 'package:gobeller/newdesigns/SendMoneyScreen.dart';
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
                        _buildDetailRowX(
                          label:accountNumber.length<13? 'Account number':"Wallet Address",
                          value: accountNumber.length<13? accountNumber:accountNumber.substring(0,10)+"..."+getLastFourDigits(accountNumber),
                        ),

                        const SizedBox(height: 24),


                        _buildDetailRowX(
                          label:"Bank name",
                          value: bankName,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24,),


                ],
              ),
            ),
            const SizedBox(height: 24),


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

                  isMobileMoney && mobilemoney_receive==true?ListTile(
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

                  isMobileMoney && mobilemoney_receive==true?SizedBox(height: 10,):Container(),

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

                  _existingRequestData != null?_buildRequestStatus():Container(),

                  SizedBox(height: 24,),




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


                  isMobileMoney &&mobilemoney_send==true && currency.toUpperCase() != "NGN"?ListTile(
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

    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Fix string concatenation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.wallet["currency_code"] ?? "Fiat"} Account', // Fixed concatenation
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),



            // Show different content based on wallet status
            if (wallet != null) ...[
              // Active Account - Show wallet details
              _buildActiveAccountSection(data, wallet, currency),
            ] else ...[
              // Pending Request - Show request details
              _buildPendingRequestSection(data, userRequestData),
            ],

            SizedBox(height: 16),

            // Timeline (always show)
            _buildTimelineSection(data),
            // ... rest of your code
          ],
        ),
      ),
    );
  }
  Widget _buildTimelineSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Timeline'),

        // Request Created
        _buildDetailRow(
            'Request Submitted',
            _formatDate(data['created_at'])
        ),





        // For active accounts, show wallet creation date
        if (data['wallet'] != null) ...[
          _buildDetailRow(
              'Account Activated',
              _formatDate(data['wallet']['created_at'])
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
  Widget _buildActiveAccountSection(Map<String, dynamic> data, Map<String, dynamic> wallet, Map<String, dynamic> currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Details
        _buildSectionTitle('Account Details'),
        _buildDetailRow('Account Number', wallet['wallet_number'] ?? 'N/A'),
        _buildDetailRow('Account Holder', wallet['ownership_label'] ?? 'N/A'),
        _buildDetailRow('Account Type', _formatOwnershipType(wallet['ownership_type'])),
        _buildDetailRow('Currency', '${currency['name']} (${currency['symbol']})'),
        _buildDetailRow('Balance', _formatBalance(wallet['balance'], currency['symbol'])),
        _buildDetailRow('Status', data['status']['label'] ?? 'Unknown'),

        SizedBox(height: 16),

        // Personal Information (from user_request_data if available)
        if (data['user_request_data'] != null) ...[
          _buildSectionTitle('Account Purpose'),
          _buildDetailRow('Designated Use', data['user_request_data']['account_designations']),
          _buildDetailRow('Occupation', data['user_request_data']['occupation']),
          _buildDetailRow('Income Source', _formatIncomeSource(data['user_request_data']['source_of_income'])),
        ],
      ],
    );
  }

  Widget _buildPendingRequestSection(Map<String, dynamic> data, Map<String, dynamic> userRequestData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Request Information
        _buildSectionTitle('Request Information'),
        _buildDetailRow('Status', '${data['status']['label']}'),
        _buildDetailRow('Account Type', _formatAccountType(data['account_type'])),
        _buildDetailRow('Purpose', userRequestData['account_designations']),

        SizedBox(height: 16),

        // Personal Information
        _buildSectionTitle('Personal Information'),
        _buildDetailRow('Occupation', userRequestData['occupation']),
        _buildDetailRow('Employment', _formatEmploymentStatus(userRequestData['employment_status'])),
        _buildDetailRow('Income Source', _formatIncomeSource(userRequestData['source_of_income'])),
        _buildDetailRow('Identification', _formatIdType(userRequestData['means_of_identification_type'])),
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