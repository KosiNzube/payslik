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
import '../pages/wallet/screens/widget/wallet_list.dart';

class FundCard extends StatefulWidget {


  final Map<String, dynamic> wallet;

  FundCard({super.key, required this.wallet});

  @override
  State<FundCard> createState() => _FundCardState();
}

class _FundCardState extends State<FundCard> {
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

    return Scaffold(
      appBar: AppBar(title: const Text("Fund with Card")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Source Wallet
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
                      'Account: '+ widget.wallet['wallet_number'],
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

              // Amount Field
              Text("Amount to Add", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
                    _processFunding(double.parse(_swapAmountController.text), _pinController2.text);

                  },
                  icon: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.swap_horiz_rounded),
                  label: Text("Proceed", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
    _destWalletController.dispose();
    _amountController.dispose();
    _swapAmountController.dispose();

    _narrationController.dispose();
    _pinController.dispose();
    _pinController2.dispose();

    super.dispose();
  }



}
