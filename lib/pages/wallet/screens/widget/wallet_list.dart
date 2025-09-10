import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/pages/quick_action/swap_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../../utils/api_service.dart';
import '../CryptoWalletDetailPage.dart';
import '../VirtualAccountRequestForm.dart';

class WalletList extends StatefulWidget {
  const WalletList({super.key});

  @override
  State<WalletList> createState() => _WalletListState();
}

class _WalletListState extends State<WalletList> {

  Color _secondaryColor=Color(0xFFFF9800);

  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final secondaryColorHex = data['customized-app-secondary-color'];



          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : _secondaryColor;


        });
      } catch (_) {
        // If there's an error parsing, use default colors
        setState(() {
          _secondaryColor = _secondaryColor;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _loadPrimaryColorAndLogo();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralWalletProvider>(
      builder: (context, walletProvider, child) {
        if (walletProvider==null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!walletProvider.hasFiatWallets) {
          return  Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wallet,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No available wallet.",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: walletProvider.fiatWallets.length,
          itemBuilder: (context, index) {
            var wallet = walletProvider.fiatWallets[index];
            print(wallet);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FiatWalletDetailPage(wallet: wallet),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),

                  color:  Colors.white,
                  border: Border.all(
                    color: _secondaryColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),

                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading Icon with shadow and gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.wallet, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      // Wallet Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet["type"] ?? "Wallet",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              wallet["bank_name"].toString() == "Unknown Bank"
                                  ? wallet["name"]
                                  : wallet["bank_name"],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Balance: ${wallet["currency"] ?? ""}${wallet["balance"]?.toStringAsFixed(2) ?? "0.00"}",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Acct: ${wallet['wallet_number'] ?? "Unavailable"}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.app_badge,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}












class WalletModal extends StatefulWidget {
  final Map<String, dynamic> wallet;
  final List<Map<String, dynamic>> allWallets;

  const WalletModal({super.key, required this.wallet, required this.allWallets});

  @override
  _WalletModalState createState() => _WalletModalState();
}

class _WalletModalState extends State<WalletModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _swapAmountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _selectedDestinationWallet;


  Color? _primaryColor;
  Color? _secondaryColor;


  // Transaction Overview
  String transactionStatusX = '---';
  String transactionTypeX = '---';
  String transactionDateX = '---';
  String exchangeRateValueX = '---';

// Basic amounts
  String amountx = '---';
  String exchangeX = '---';
  String rateX = '---';
  String TotalDebitX = '---';

// Source Wallet (Debit) Details
  String sourceAmountX = '---';
  String sourceFeeX = '---';
  String sourceBalanceBeforeX = '---';
  String BalanceAfterX = '---';
  String sourceWalletNumberX = '---';
  String sourceCurrencyX = '---';

// Destination Wallet (Credit) Details
  String destinationAmountX = '---';
  String destinationFeeX = '---';
  String netCreditedX = '---';
  String destinationBalanceBeforeX = '---';
  String destinationBalanceAfterX = '---';
  String destinationWalletNumberX = '---';
  String destinationCurrencyX = '---';
  final TextEditingController _pinController2 = TextEditingController();

  bool _isPinHidden = true;

  bool estimate=false;

  bool _canSwap = false;



  Future<void> _checkSwapEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        setState(() {
          _canSwap =  orgData['data']?['customized_app_displayable_menu_items']?['display-fiat-crypto-conversion-options'] ?? false;
        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _canSwap = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    String walletBalance = widget.wallet["balance"].toString() ?? "0.00";
    String walletName = widget.wallet["name"].toString()  ?? "Wallet";
    String walletNumber = widget.wallet["wallet_number"].toString()  ?? "N/A";
    String currency = widget.wallet["currency"].toString()  ?? "";

    String bank=widget.wallet['bank_name'] ?? 'Unknown Bank'; // bank name

    String code=widget.wallet['currency_code'] ?? '---'; // bank name

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Modal Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                walletName,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),

          SizedBox(height: 20),

          // Wallet Balance Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${currency}${walletBalance}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Account: $walletNumber',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              // Add Money Button (only for USD)
              if (currency.toUpperCase() == "USD" || currency.contains("\$"))
                Expanded(
                  child: ElevatedButton(
                    onPressed:(){
                      _showAddMoneyOptions(bank,code);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Money',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              if (currency.toUpperCase() == "USD" || currency.contains("\$"))
                _canSwap?SizedBox(width: 12):Container(),

              // Swap Button (for all wallets)
              _canSwap? Expanded(
                child: ElevatedButton(
                  onPressed: (){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SwapPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text(
                        'Swap',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ):Container(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchThemeColors();
    _checkSwapEnabled();


  }


  Future<void> _fetchThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};
      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }



  void _showAddMoneyOptions(String bank, String code) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Money Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),


              // Receive Payment Option
              bank=="Unknown Bank" || bank==null?Container(): ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.payment, color: Colors.orange),
                ),
                title: Text('Receive Payment'),
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
              ),



             // SizedBox(height: 12),

              // Fund with Card Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.credit_card, color: Colors.blue),
                ),
                title: Text('Fund with Card'),
                subtitle: Text('Add money using your card'),
                onTap: () {
                  Navigator.pop(context);
                  _showFundWithCardDialog();
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSwapOptions() {
    _swapAmountController.clear();
    _selectedDestinationWallet = null;

    // Filter out the current wallet from the list
    List<Map<String, dynamic>> otherWallets = widget.allWallets
        .where((w) => w['wallet_number'] != widget.wallet['wallet_number'])
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) { // Renamed to setModalState for clarity
            return Container(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Swap Funds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Source Wallet Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From: ' + widget.wallet["wallet_number"].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${widget.wallet["name"]} (${widget.wallet["currency"]}${widget.wallet["balance"]})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Amount Input
                    TextField(
                      controller: _swapAmountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount to Swap',
                        prefixText: '${widget.wallet["currency"]}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: '0.00',
                      ),
                    ),

                    SizedBox(height: 20),

                    // Destination Wallet Selection
                    Text(
                      'Select Destination Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Wallet list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: otherWallets.length,
                      itemBuilder: (context, index) {
                        var wallet = otherWallets[index];
                        bool isSelected = _selectedDestinationWallet != null &&
                            _selectedDestinationWallet!['wallet_number'] == wallet['wallet_number'];

                        return GestureDetector(
                          onTap: () {
                            setModalState(() { // Use setModalState here
                              _selectedDestinationWallet = wallet;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _primaryColor! : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected ?_primaryColor!.withOpacity(0.5) : Colors.grey.shade400,
                                  child: Icon(
                                    Icons.wallet,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet['name'] ?? 'Unnamed Wallet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        wallet['wallet_number'].toString() + " - (" '${wallet["currency"]}${wallet["balance"]}' + ")",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color:_primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _selectedDestinationWallet==null?SmartDialog.showToast("Please select destination wallet"): _swapAmountController.text.isEmpty?SmartDialog.showToast("Please enter amount to swap"):  _showSwapSummary(setModalState); // Pass the modal setState
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Estimate',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transaction Overview
                    _buildSummaryRow('Exchange Rate:', exchangeX),

                    const SizedBox(height: 16),

// Add section divider here
                    Text('SOURCE WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    _buildSummaryRow('Wallet Number:', sourceWalletNumberX),
                    _buildSummaryRow('Amount:', sourceAmountX),
                    _buildSummaryRow('Platform Fee:', sourceFeeX),
                    _buildSummaryRow('Total Debit:', TotalDebitX),
                    _buildSummaryRow('Balance After:', BalanceAfterX),

                    const SizedBox(height: 16),


// Add section divider here
                    Text('DESTINATION WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    _buildSummaryRow('Wallet Number:', destinationWalletNumberX),
                    _buildSummaryRow('Amount Received:', destinationAmountX),
                    _buildSummaryRow('Platform Fee:', destinationFeeX),
                    _buildSummaryRow('Net Credited:', netCreditedX),
                    _buildSummaryRow('New Balance:', destinationBalanceAfterX),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _pinController2,
                      obscureText: _isPinHidden,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Transaction PIN",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isPinHidden ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => _isPinHidden = !_isPinHidden), // Use setModalState
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) => value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {

                         estimate==false?SmartDialog.showToast("Please do the estimate first"): _pinController2.text.isEmpty?SmartDialog.showToast("Please input your PIN"): _initiateSwap(double.tryParse(_swapAmountController.text)??0.0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Swap',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    // Add some bottom padding for better spacing
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSwapSummary(Function setModalState) async {

    SmartDialog.showLoading(msg: "Please wait");

    double amount = double.tryParse(_swapAmountController.text) ?? 0.0;

    String sourceIdentifier = widget.wallet["id"] ?? widget.wallet["wallet_number"] ?? "";
    String destinationIdentifier = _selectedDestinationWallet!["id"] ?? _selectedDestinationWallet!["wallet_number"] ?? "";

    Map<String, dynamic> initiateData = {
      'source_wallet_number_or_uuid': sourceIdentifier,
      'source_wallet_swap_amount': amount,
      'destination_wallet_number_or_uuid': destinationIdentifier,
      'description': 'Swap funds',
    };

    final initiateResponse = await ApiService.postRequest(
      '/customers/wallet-funds-swap/initiate',
      initiateData,
    );

    if (initiateResponse['status'] == 'success' || initiateResponse['status'] != 'error') {


      final data = initiateResponse['data'];
      final sourceWallet = data['source_wallet_initialization_summary'];
      final destinationWallet = data['destination_wallet_initialization_summary'];
      final exchangeRate = data['exchange_rate'];

      // Use the modal's setState instead of the main widget's setState
      setModalState(() {

        estimate=true;
        // Basic transaction info
        amountx = '${widget.wallet["currency"]}${amount.toStringAsFixed(2)}';
        exchangeX = '1 ${destinationWallet['currency_code']} = ${exchangeRate} ${sourceWallet['currency_code']}';

        // Source wallet details
        sourceAmountX = '${sourceWallet['currency_symbol']}${sourceWallet['amount_processable']}';
        sourceFeeX = '${sourceWallet['currency_symbol']}${sourceWallet['platform_charge_fee']}';
        TotalDebitX = '${sourceWallet['currency_symbol']}${sourceWallet['total_amount_processable']}';
        sourceBalanceBeforeX = '${sourceWallet['currency_symbol']}${sourceWallet['actual_balance_before']}';
        BalanceAfterX = '${sourceWallet['currency_symbol']}${sourceWallet['expected_balance_after']}';
        sourceWalletNumberX = sourceWallet['wallet_number'];

        // Destination wallet details
        destinationAmountX = '${destinationWallet['currency_symbol']}${destinationWallet['amount_processable']}';
        destinationFeeX = '${destinationWallet['currency_symbol']}${destinationWallet['platform_charge_fee']}';
        netCreditedX = '${destinationWallet['currency_symbol']}${destinationWallet['total_amount_processable']}';
        destinationBalanceBeforeX = '${destinationWallet['currency_symbol']}${destinationWallet['actual_balance_before']}';
        destinationBalanceAfterX = '${destinationWallet['currency_symbol']}${destinationWallet['expected_balance_after']}';
        destinationWalletNumberX = destinationWallet['wallet_number'];

        // Transaction summary
        transactionStatusX = 'Success';
        transactionTypeX = 'Wallet Swap';
        exchangeRateValueX = exchangeRate.toString();

        // Additional details
        sourceCurrencyX = '${sourceWallet['currency_code']} (${sourceWallet['currency_symbol']})';
        destinationCurrencyX = '${destinationWallet['currency_code']} (${destinationWallet['currency_symbol']})';
        transactionDateX = DateTime.now().toString(); // or get from response if available
      });

      SmartDialog.dismiss();

    } else {
      SmartDialog.dismiss();
      _showErrorDialog(initiateResponse['message'] ?? 'Failed to initiate swap');
    }
  }

  Future<void> _initiateSwap(double amount) async {

    SmartDialog.showLoading(msg: "Swapping");
    setState(() {
      _isLoading = true;
    });

    try {
      String sourceWalletNumber = widget.wallet["wallet_number"] ?? widget.wallet["uuid"] ?? "";
      String destinationWalletNumber = _selectedDestinationWallet!["wallet_number"] ?? _selectedDestinationWallet!["uuid"] ?? "";

      // Step 1: Initiate swap

        // Step 2: Process swap with PIN
        Map<String, dynamic> processData = {
          'source_wallet_number_or_uuid': sourceWalletNumber,
          'source_wallet_swap_amount': amount,
          'destination_wallet_number_or_uuid': destinationWalletNumber,
          'description': 'Swap Funds',
          'transaction_pin': int.tryParse(_pinController2.text) ?? 0,
        };

        final processResponse = await ApiService.postRequest(
          '/customers/wallet-funds-swap/process',
          processData,
        );

        if (processResponse['status'] == 'success' ) {
          SmartDialog.dismiss();

          _showSuccessDialog('Swap completed successfully!');
        } else {
          SmartDialog.dismiss();

          _showErrorDialog(processResponse['message'] ?? 'Failed to process swap');
        }

    } catch (e) {
      SmartDialog.dismiss();
      _showErrorDialog('Network error: $e');
    } finally {
      SmartDialog.dismiss();

      setState(() {

        _isLoading = false;
      });
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: Text('Coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFundWithCardDialog() {
    _amountController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Fund with Card'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (USD)',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      hintText: '0.00',
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Enter the amount you want to add to your USD wallet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:  () {
                    Navigator.pop(context);
                    _showFundingSummary();
                  },
                  child: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFundingSummary() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Funding Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Amount:', amount.toStringAsFixed(2)),
              _buildSummaryRow('Currency:', 'USD'),
              _buildSummaryRow('Destination:', 'USD Wallet'),
              _buildSummaryRow('Method:', 'Credit/Debit Card'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Please enter your transaction PIN to proceed with payment.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showFundingPinDialog(amount);
              },
              child: _isLoading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showFundingPinDialog(double amount) {
    final TextEditingController fundingPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Transaction PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fundingPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Transaction PIN',
                      border: OutlineInputBorder(),
                      hintText: '****',
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Enter your 4-digit transaction PIN to proceed with funding',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                   // Navigator.pop(context);
                    _processFunding(amount, fundingPinController.text);
                  },
                  child: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Proceed to Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Future<void> _processFunding(double amount, String pin) async {
    SmartDialog.showLoading(msg: "Please wait");


    setState(() {
      _isLoading = true;
    });

    try {
      String walletNumberOrUuid = widget.wallet["wallet_number"] ?? widget.wallet["uuid"] ?? "";

      // Step 1: Initiate funding transaction
      Map<String, dynamic> initiateData = {
        'funding_amount': amount,
        'funding_currency_code': 'USD',
        'destination_wallet_number_or_uuid': walletNumberOrUuid,
        'description': 'USD wallet funding',
      };

      final initiateResponse = await ApiService.postRequest(
        '/customers/fund-wallet-transaction/initiate',
        initiateData,
      );

      if (initiateResponse['status'] == true) {
        // Step 2: Process funding with PIN and redirect URLs
        Map<String, dynamic> processData = {
          'funding_amount': amount,
          'destination_wallet_number_or_uuid': walletNumberOrUuid,
          'description': 'USD wallet funding',
          'transaction_pin': pin,
          'success_redirect_url': 'https://viyyyyllage.successful-payment-url.com', // Replace with your actual success URL
          'cancelled_redirect_url': 'https://kaeeeebir.village/cancelled', // Replace with your actual cancelled URL
          'failed_redirect_url': 'https://hdddello.world/failed', // Replace with your actual failed URL
        };

        final processResponse = await ApiService.postRequest(
          '/customers/fund-wallet-transaction/process',
          processData,
        );

        if (processResponse['status'] == true) {
          SmartDialog.dismiss();

          // Check for funding URL in the process response
          if (processResponse['data'] != null && processResponse['data']['funding_url'] != null) {
            await _launchFundingUrl(processResponse['data']['funding_url']);
          } else if (processResponse['funding_url'] != null) {
            await _launchFundingUrl(processResponse['funding_url']);
          } else if (processResponse['data'] != null && processResponse['data']['payment_url'] != null) {
            await _launchFundingUrl(processResponse['data']['payment_url']);
          } else if (processResponse['payment_url'] != null) {
            await _launchFundingUrl(processResponse['payment_url']);
          } else {
            // Show success but no URL provided
            _showSuccessDialog('Funding request processed successfully. Please check your account or contact support for payment instructions.');
          }
        } else {
          SmartDialog.dismiss();

          _showErrorDialog(processResponse['message'] ?? 'Failed to process funding');
        }
      } else {
        SmartDialog.dismiss();

        _showErrorDialog(initiateResponse['message'] ?? 'Failed to initiate funding');
      }
    } catch (e) {
      _showErrorDialog('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchFundingUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // Validate URL before navigation
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FundingWebView(
              url: url,
              title: 'Funding', // You can customize this title
            ),
          ),
        );
      } else {
        _showErrorDialog('Invalid funding URL');
      }
    } catch (e) {
      _showErrorDialog('Could not launch funding URL');
    }
  }

// Keep your existing error dialog or use this one:
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _amountController.dispose();
    _swapAmountController.dispose();
    _pinController2.dispose();
    super.dispose();
  }
}

class CryptoWalletList extends StatefulWidget {
  const CryptoWalletList({super.key});

  @override
  State<CryptoWalletList> createState() => _CryptoWalletListState();
}

class _CryptoWalletListState extends State<CryptoWalletList> {

  Color _secondaryColor=Color(0xFFFF9800);

  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final secondaryColorHex = data['customized-app-secondary-color'];



          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : _secondaryColor;


        });
      } catch (_) {
        // If there's an error parsing, use default colors
        setState(() {
          _secondaryColor = _secondaryColor;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _loadPrimaryColorAndLogo();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralWalletProvider>(
      builder: (context, walletProvider, child) {
        if (walletProvider.isLoading) {
          return  Center(
            child: CircularProgressIndicator(),
          );
        }

        if (walletProvider.cryptoWallets.isEmpty) {
          return  Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wallet,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No available crypto wallet.",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: walletProvider.cryptoWallets.length,
          itemBuilder: (context, index) {
            final wallet = walletProvider.cryptoWallets[index];

            // Safe access with fallbacks
            final currency = (wallet["currency_code"] ?? "CRYPTO").toString();
            final address = (wallet["wallet_address"] ?? wallet["wallet_number"] ?? "Unavailable").toString();
            final balance = (wallet["balance"]?.toStringAsFixed(2) ?? "0.00").toString();
            final network = (wallet["currency_network"] ?? "Unknown").toString();
            final label = (wallet["label"] ?? "$currency Wallet").toString();

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: const Color(0xFFFBFBFB),
                border: Border.all(
                  color: _secondaryColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CryptoWalletDetailPage(wallet: wallet),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Currency Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),

                              ),
                              child: Text(
                                currency.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Network Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    network,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Wallet Label
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Balance
                        Text(
                          "Balance: $balance",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Address Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wallet,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address.length > 30
                                      ? "${address.substring(0, 15)}...${address.substring(address.length - 10)}"
                                      : address,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Copy address functionality
                                  Clipboard.setData(
                                      ClipboardData(text: address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text('Address copied to clipboard')),
                                  );
                                },
                                child: Icon(
                                  Icons.copy_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}



class FundingWebView extends StatefulWidget {
  final String url;
  final String title;

  const FundingWebView({
    super.key,
    required this.url,
    this.title = 'Funding',
  });

  @override
  State<FundingWebView> createState() => _FundingWebViewState();
}

class _FundingWebViewState extends State<FundingWebView> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
  bool isLoading = true;
  String? logoUrl;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _loadLogo();
    _initializeWebView();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadLogo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      logoUrl = prefs.getString('org_logo');
    });
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => isLoading = false);
            }
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => isLoading = false);
          //  _showErrorDialog('Could not load funding page');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }


  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_2_circlepath),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: logoUrl != null
                            ? Image.network(
                          logoUrl!,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.money, size: 100, color: Colors.green),
                        )
                            : const Icon(Icons.money, size: 100, color: Colors.green),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading funding page...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

