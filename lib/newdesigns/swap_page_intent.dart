// Unchanged imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gobeller/utils/currency_input_formatter.dart';

import '../../controller/swap_controller.dart';
import '../../utils/api_service.dart';
import '../../utils/routes.dart';

class SwapPageIntent extends StatefulWidget {


  final Map<String, dynamic> wallet;

   SwapPageIntent({super.key, required this.wallet});

  @override
  State<SwapPageIntent> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPageIntent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destWalletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String? selectedSourceWallet;
  bool _isPinHidden = true;
  bool _isCompletingTransfer = false;

  String? selectedAccountNumber;
  String? selectedCurrency;
  Color? _primaryColor;
  Color? _secondaryColor;


  String? destinationSourceWallet;


  String? destinationAccountNumber;
  String? destinationCurrency;

  final TextEditingController _swapAmountController = TextEditingController();
  bool _isLoading = false;




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


  bool estimate=false;

  String? selectedID;
  String? destinationID;

  @override
  void initState() {
    super.initState();
    _fetchThemeColors();

    selectedSourceWallet=widget.wallet['id']??"selected";
    selectedAccountNumber = widget.wallet["wallet_number"];
    selectedCurrency = widget.wallet["currency"];
    selectedID = widget.wallet["id"];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<SwapController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });
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

  Future<Color> _getColorFromPrefs(String key, Color fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final colorInt = prefs.getInt(key);
    return colorInt != null ? Color(colorInt) : fallback;
  }

  void _resetForm(SwapController controller) {
    _formKey.currentState?.reset();
    _destWalletController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();

    controller.clearBeneficiaryName();
  }


  void _navigateToTransferResult(bool success, String message) {
    final controller = Provider.of<SwapController>(context, listen: false);

    if (success) {
      _resetForm(controller); // Clear the form first
    }

    Navigator.pushNamed(
      context,
      Routes.transfer_result,
      arguments: {
        'success': success,
        'message': message,
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final transferController = Provider.of<SwapController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Convert money")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                      NumberFormat("#,##0.00")
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



              // Source Wallet


              const SizedBox(height: 20),

              // Amount Field
              Text("Amount to Swap", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _swapAmountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixText: selectedCurrency,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              // Destination Wallet
              Text("Select Destination Wallet", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: destinationSourceWallet,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.wallet),
               //   labelText: "Destination Wallet",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: transferController.sourceWallets.map((wallet) {
                  final encodedValue = jsonEncode({
                    "account_number": wallet["account_number"],
                    "currency": wallet["currency_symbol"],
                    "id": wallet["id"],
                  });
                  String azanumber=wallet['account_number'].toString().length>11?wallet['account_number'].toString().substring(0,11)+"...":wallet['account_number'].toString();

                  return DropdownMenuItem<String>(
                    value: encodedValue,
                    child: Text(
                      "${azanumber} - (${wallet['currency_symbol']}${wallet['available_balance']})",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final decoded = jsonDecode(value);
                    setState(() {
                      destinationSourceWallet = value;
                      destinationAccountNumber = decoded["account_number"];
                      destinationCurrency = decoded["currency"];
                      destinationID = decoded["id"];
                    });
                  }
                },
                validator: (value) => value == null ? "Please select a destination wallet" : null,
              ),

              const SizedBox(height: 24),

              // Estimate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (selectedSourceWallet == null) {
                      SmartDialog.showToast("Please select source wallet");
                    } else if (destinationSourceWallet == null) {
                      SmartDialog.showToast("Please select destination wallet");
                    } else if (_swapAmountController.text.isEmpty) {
                      SmartDialog.showToast("Please enter amount to swap");
                    } else {
                      _showSwapSummary();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.calculate_outlined),
                  label: Text("Estimate", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 30),

              // Exchange Rate Summary
              if (exchangeX != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Exchange Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Exchange Rate:', exchangeX),
                        const Divider(height: 32),

                        Text("Source Wallet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Wallet Number:', sourceWalletNumberX),
                        _buildSummaryRow('Amount:', sourceAmountX),
                        _buildSummaryRow('Platform Fee:', sourceFeeX),
                        _buildSummaryRow('Total Debit:', TotalDebitX),
                        _buildSummaryRowX('Balance After:', BalanceAfterX),

                        const Divider(height: 32),

                        Text("Destination Wallet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Wallet Number:', destinationWalletNumberX),
                        _buildSummaryRow('Amount Received:', destinationAmountX),
                        _buildSummaryRow('Platform Fee:', destinationFeeX),
                        _buildSummaryRow('Net Credited:', netCreditedX),
                        _buildSummaryRowX('New Balance:', destinationBalanceAfterX),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Transaction PIN
              Text("Enter Transaction PIN", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController2,
                obscureText: _isPinHidden,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                //  labelText: "PIN",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isPinHidden ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPinHidden = !_isPinHidden),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) => value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
              ),

              const SizedBox(height: 24),

              // Final Swap Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!estimate) {
                      SmartDialog.showToast("Please do the estimate first");
                    } else if (_pinController2.text.isEmpty) {
                      SmartDialog.showToast("Please input your PIN");
                    } else {
                      _initiateSwap(double.tryParse(_swapAmountController.text) ?? 0.0);
                    }
                  },
                  icon: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.swap_horiz_rounded),
                  label: Text("Swap", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSwapSummary() async {
    SmartDialog.showLoading(msg: "Please wait");

    double amount = double.tryParse(_swapAmountController.text) ?? 0.0;

    String sourceIdentifier = selectedID ?? selectedAccountNumber ?? "";
    String destinationIdentifier = destinationID ?? destinationAccountNumber ?? "";

    Map<String, dynamic> initiateData = {
      'source_wallet_number_or_uuid': sourceIdentifier,
      'source_wallet_swap_amount': amount,
      'destination_wallet_number_or_uuid': destinationIdentifier,
      'description': 'Swap funds',
    };

    try {
      final initiateResponse = await ApiService.postRequest(
        '/customers/wallet-funds-swap/initiate',
        initiateData,
      );

      if ((initiateResponse['status'] == 'success' || initiateResponse['status'] != 'error') &&
          initiateResponse['data'] != null &&
          initiateResponse['data']['source_wallet_initialization_summary'] != null &&
          initiateResponse['data']['destination_wallet_initialization_summary'] != null) {

        final data = initiateResponse['data'];
        final sourceWallet = data['source_wallet_initialization_summary'];
        final destinationWallet = data['destination_wallet_initialization_summary'];
        final exchangeRate = data['exchange_rate'];

        setState(() {
          estimate = true;

          amountx = '${selectedCurrency}${amount.toStringAsFixed(2)}';
          exchangeX = '1 ${destinationWallet['currency_code']} = ${exchangeRate} ${sourceWallet['currency_code']}';

          sourceAmountX = '${sourceWallet['currency_symbol']}${sourceWallet['amount_processable']}';
          sourceFeeX = '${sourceWallet['currency_symbol']}${sourceWallet['platform_charge_fee']}';
          TotalDebitX = '${sourceWallet['currency_symbol']}${sourceWallet['total_amount_processable']}';
          sourceBalanceBeforeX = '${sourceWallet['currency_symbol']}${sourceWallet['actual_balance_before']}';
          BalanceAfterX = '${sourceWallet['currency_symbol']}${sourceWallet['expected_balance_after']}';
          sourceWalletNumberX = sourceWallet['wallet_number'];

          destinationAmountX = '${destinationWallet['currency_symbol']}${destinationWallet['amount_processable']}';
          destinationFeeX = '${destinationWallet['currency_symbol']}${destinationWallet['platform_charge_fee']}';
          netCreditedX = '${destinationWallet['currency_symbol']}${destinationWallet['total_amount_processable']}';
          destinationBalanceBeforeX = '${destinationWallet['currency_symbol']}${destinationWallet['actual_balance_before']}';
          destinationBalanceAfterX = '${destinationWallet['currency_symbol']}${destinationWallet['expected_balance_after']}';
          destinationWalletNumberX = destinationWallet['wallet_number'];

          transactionStatusX = 'Success';
          transactionTypeX = 'Wallet Swap';
          exchangeRateValueX = exchangeRate.toString();

          sourceCurrencyX = '${sourceWallet['currency_code']} (${sourceWallet['currency_symbol']})';
          destinationCurrencyX = '${destinationWallet['currency_code']} (${destinationWallet['currency_symbol']})';
          transactionDateX = DateTime.now().toString();
        });

        SmartDialog.dismiss();
      } else {
        SmartDialog.dismiss();
        _showErrorDialog(initiateResponse['message'] ?? 'Failed to estimate swap');
      }
    } catch (e, stackTrace) {
      SmartDialog.dismiss();
      _showErrorDialog('An error occurred while processing the swap.\n$e');
      debugPrint("❌ Error in _showSwapSummary: $e\n$stackTrace");
    }
  }
  Future<void> _initiateSwap(double amount) async {

    SmartDialog.showLoading(msg: "Swapping");
    setState(() {
      _isLoading = true;
    });

    try {
      String sourceWalletNumber = selectedAccountNumber ?? selectedID ?? "";
      String destinationWalletNumber = destinationAccountNumber ?? destinationID ?? "";

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



  @override
  void dispose() {
    _destWalletController.dispose();
    _amountController.dispose();
    _swapAmountController.dispose();

    _narrationController.dispose();
    _pinController.dispose();
    _pinController2.dispose();

    super.dispose();
  }
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

  Widget _buildSummaryRowX(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500,textStyle: TextStyle(fontSize: 17))),
          Flexible(child: Text(value, textAlign: TextAlign.end,style: GoogleFonts.inter(fontWeight: FontWeight.w500,textStyle: TextStyle(fontSize: 17)))),
        ],
      ),
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


}
