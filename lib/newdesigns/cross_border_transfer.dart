import 'dart:convert';
import 'dart:math';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/DASHBOARD_DEFAULT.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_to_bank_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class CrossBorderTransferPageIntent extends StatefulWidget {
  final Map<String, dynamic> wallet;

  CrossBorderTransferPageIntent({super.key, required this.wallet});

  @override
  State<CrossBorderTransferPageIntent> createState() => _CrossBorderTransferPageState();
}

class _CrossBorderTransferPageState extends State<CrossBorderTransferPageIntent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // New controllers for API fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _bankSortCodeController = TextEditingController();
  final TextEditingController _bankSwiftCodeController = TextEditingController();
  String? selectedBank;
  String? selectedBankId;

  // New variables for API fields
  String? selectedCountryCode;
  String selectedPaymentScheme = "swift";

  bool isLoading = false;
  bool _isPinHidden = true;
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
      final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
      controller.fetchBanks();
      controller.fetchSourceWallets();
      controller.fetchSavedBeneficiaries();
      _resetForm();
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bankCodeController.dispose();
    _bankSortCodeController.dispose();   // Dispose new controller
    _bankSwiftCodeController.dispose();  // Dispose new controller
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
    String cleaned = input.replaceAll(',', '');
    int? number = int.tryParse(cleaned);
    if (number == null) return input;
    return formatter.format(number);
  }

  // Generate initialization reference
  String generateInitializationReference() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  void _showTransactionSummary() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SafeArea(
                  top: false,
                  child: Stack(
                    children: [
                      ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Kindly review details",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Change",
                                    style: TextStyle(
                                      color: Color(0xFF007AFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Transaction Details Card
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  "AMOUNT",
                                  "${formatNumber(_amountController.text)}",
                                  isAmount: true,
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "PAYMENT SCHEME",
                                    selectedPaymentScheme.toUpperCase()
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "BENEFICIARY",
                                    "${_firstNameController.text} ${_lastNameController.text}"
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "EMAIL",
                                    _emailController.text
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "ACCOUNT NUMBER",
                                    _accountNumberController.text
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "BANK CODE",
                                    _bankCodeController.text
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                    "COUNTRY",
                                    selectedCountryCode ?? ""
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                  "DESCRIPTION",
                                  _narrationController.text.isNotEmpty
                                      ? _narrationController.text
                                      : "Cross Border FX Transfer",
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // PIN Section
                          Center(
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                "Enter PIN to confirm",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // PIN Display
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _pinController.text.length > index
                                          ? Colors.black87
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: _pinController.text.length > index
                                        ? Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Custom PIN Pad
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                _buildPinRow(['1', '2', '3'], setModalState),
                                const SizedBox(height: 16),
                                _buildPinRow(['4', '5', '6'], setModalState),
                                const SizedBox(height: 16),
                                _buildPinRow(['7', '8', '9'], setModalState),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const SizedBox(width: 60),
                                    _buildPinButton('0', setModalState),
                                    GestureDetector(
                                      onTap: () {
                                        if (_pinController.text.isNotEmpty) {
                                          setModalState(() {
                                            _pinController.text =
                                                _pinController.text.substring(
                                                    0,
                                                    _pinController.text.length - 1);
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.backspace_outlined,
                                          size: 24,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Consumer<WalletToBankTransferController>(
                              builder: (context, controller, child) {
                                bool canProceed = _pinController.text.length == 4 &&
                                    !controller.isProcessing &&
                                    !isLoading;

                                return SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (canProceed) {
                                        _confirmTransfer(controller);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canProceed
                                          ? const Color(0xFF34C759)
                                          : Colors.grey[300],
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: controller.isProcessing || isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                        : const Text(
                                      "Proceed",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),

                      // Optional overlay if processing
                      if (isLoading ||
                          context.read<WalletToBankTransferController>().isProcessing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(25)),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
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

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isAmount ? 20 : 16,
              fontWeight: isAmount ? FontWeight.w700 : FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinRow(List<String> numbers, StateSetter setModalState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildPinButton(number, setModalState)).toList(),
    );
  }

  Widget _buildPinButton(String number, StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        if (_pinController.text.length < 4) {
          setModalState(() {
            _pinController.text += number;
          });
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Updated API method


// Updated completeBankTransfer method
  Future<Map<String, dynamic>> completeBankTransfer({
    required String sourceWalletNumberOrUuid,
    required String transferPaymentScheme,
    required double transferAmount,
    required String transferDescription,
    required String initializationReference,
    required String transactionPin,
    required String beneficiaryFirstName,
    required String beneficiaryLastName,
    required String beneficiaryAccountNumber,
    required String beneficiaryCountryCode,
    required String beneficiaryEmail,
    required String beneficiaryBankCode,
    required String beneficiaryBankSortCode,  // New parameter
    required String beneficiaryBankSwiftCode, // New parameter
  }) async {
    String _transactionMessage = "";

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        return {"success": false, "message": _transactionMessage};
      }

      final requestBody = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "transfer_payment_scheme": transferPaymentScheme,
        "transfer_amount": transferAmount.toString(),
        "transfer_description": transferDescription,
        "initialization_reference": initializationReference,
        "transaction_pin": transactionPin,
        "beneficiary_first_name": beneficiaryFirstName,
        "beneficiary_last_name": beneficiaryLastName,
        "beneficiary_account_number": beneficiaryAccountNumber,
        "beneficiary_country_code": beneficiaryCountryCode,
        "beneficiary_email": beneficiaryEmail,
        "beneficiary_bank_code": beneficiaryBankCode,
        "beneficiary_bank_sort_code": beneficiaryBankSortCode,   // New field
        "beneficiary_bank_swift_code": beneficiaryBankSwiftCode, // New field
      };

      final response = await ApiService.postRequest(
        "/cross-border-payment-mgt/fx-wallet-bank-transfer/process",
        requestBody,
        extraHeaders: {
          'Authorization': 'Bearer $token',
          'AppID': 'e64af448-e2a8-4842-b859-2cfc824439d1',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Your transfer was successful! Funds have been sent to the bank.";
        return {"success": true, "message": _transactionMessage};
      } else {
        _transactionMessage = response["message"] ?? "❌ Transfer failed. Please check your details and try again.";
        return {"success": false, "message": _transactionMessage};
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while processing the transfer. Please try again.";
      return {"success": false, "message": _transactionMessage};
    }
  }

  Future<Map<String, dynamic>> initializeTransfer({
    required String sourceWalletNumberOrUuid,
    required double transferAmount,
    required String transferPaymentScheme,
    required String transferDescription,
  }) async {
    String _transactionMessage = "";

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        return {"success": false, "message": _transactionMessage};
      }

      final requestBody = {
        "source_wallet_number_or_uuid": sourceWalletNumberOrUuid,
        "transfer_payment_scheme": transferPaymentScheme,
        "transfer_amount": transferAmount.toString(),
        "transfer_description": transferDescription,
      };

      final response = await ApiService.postRequest(
        "/cross-border-payment-mgt/fx-wallet-bank-transfer/initiate",
        requestBody,
        extraHeaders: {
          'Authorization': 'Bearer $token',
          'AppID': 'e64af448-e2a8-4842-b859-2cfc824439d1',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Your transfer was initiated! Funds have been sent to the bank.";

        // Extract initialization_reference from the response data
        String? initializationReference = response["data"]?["initialization_reference"];

        return {
          "success": true,
          "message": _transactionMessage,
          "initialization_reference": initializationReference,
          "data": response["data"] // Optional: include full data if needed elsewhere
        };
      } else {
        _transactionMessage = response["message"] ?? "❌ Transfer failed. Please check your details and try again.";
        snacklen(_transactionMessage);
        return {"success": false, "message": _transactionMessage};
      }
    } catch (e) {
      _transactionMessage = "❌ We encountered an error while processing the transfer. Please try again.";
      snacklen(_transactionMessage);

      return {"success": false, "message": _transactionMessage};
    }
  }

// Updated _confirmTransfer method
  void _confirmTransfer(WalletToBankTransferController controller) async {
    setState(() {
      isLoading = true;
    });

    SmartDialog.showLoading(msg: "Please wait");

    final result_initialize = await initializeTransfer(
        sourceWalletNumberOrUuid: widget.wallet['wallet_number'] ?? widget.wallet['uuid'],

        transferAmount: double.parse(_amountController.text.replaceAll(",", "")),
        transferPaymentScheme: selectedPaymentScheme,
        transferDescription: _narrationController.text.isNotEmpty
            ? _narrationController.text
            : "Cross Border FX Transfer");


    // Generate initialization reference if not already generated
    if (result_initialize["success"] == true) {
      // Get the initialization reference
      String initializationReference = result_initialize["initialization_reference"];
      print("Transfer initiated successfully!");
      print("Initialization Reference: $initializationReference");

      final result = await completeBankTransfer(
        sourceWalletNumberOrUuid: widget.wallet['wallet_number'] ?? widget.wallet['uuid'],
        transferPaymentScheme: selectedPaymentScheme,
        transferAmount: double.parse(_amountController.text.replaceAll(",", "")),
        transferDescription: _narrationController.text.isNotEmpty
            ? _narrationController.text
            : "Cross Border FX Transfer",
        initializationReference: initializationReference!,
        transactionPin: _pinController.text,
        beneficiaryFirstName: _firstNameController.text,
        beneficiaryLastName: _lastNameController.text,
        beneficiaryAccountNumber: _accountNumberController.text,
        beneficiaryCountryCode: selectedCountryCode!,
        beneficiaryEmail: _emailController.text,
        beneficiaryBankCode: _bankCodeController.text,
        beneficiaryBankSortCode: _bankSortCodeController.text,   // New field
        beneficiaryBankSwiftCode: _bankSwiftCodeController.text, // New field
      );

      setState(() {
        isLoading = false;

      });
      SmartDialog.dismiss();

      if (result['success']) {
        _resetForm(); // Reset form on success
      }

      Navigator.pushNamed(
        context,
        '/bank_result',
        arguments: {
          'success': result['success'],
          'message': result['message'],
          'data': result['data'],
        },
      );

      // You can now use this reference for further processing
      // e.g., store it, pass it to another function, etc.
    } else {
      SmartDialog.dismiss();
      setState(() {
        isLoading = false;

      });

    }

  }



  void _resetForm() {
    _formKey.currentState?.reset();
    _accountNumberController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _bankCodeController.clear();
    _bankSortCodeController.clear();   // Clear new field
    _bankSwiftCodeController.clear();  // Clear new field

    setState(() {
      selectedBank = null;
      selectedBankId = null;
      selectedCountryCode = null;
      selectedPaymentScheme = "swift";
    });

    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    controller.clearBeneficiaryName();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WalletToBankTransferController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cross Border Transfer"),
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
                    // Source Wallet Display
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

                    const SizedBox(height: 24),

                    // Beneficiary First Name
                    const Text("First Name"),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter beneficiary's first name",
                      ),
                      validator: (value) => value!.isEmpty ? "First name is required" : null,
                    ),

                    const SizedBox(height: 16),

                    // Beneficiary Last Name
                    const Text("Last Name"),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter beneficiary's last name",
                      ),
                      validator: (value) => value!.isEmpty ? "Last name is required" : null,
                    ),

                    const SizedBox(height: 16),

                    // Email Address
                    const Text("Email Address"),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter beneficiary's email",
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return "Email is required";
                        if (!value.contains('@')) return "Enter a valid email";
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Country Code
                    const Text("Beneficiary Country"),
                    DropdownButtonFormField<String>(
                      value: selectedCountryCode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text("Select country"),
                      items: const [
                        DropdownMenuItem(value: "US", child: Text("United States (US)")),
                        DropdownMenuItem(value: "UK", child: Text("United Kingdom (UK)")),
                        DropdownMenuItem(value: "CA", child: Text("Canada (CA)")),

                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCountryCode = value;
                        });
                      },
                      validator: (value) => value == null ? "Please select a country" : null,
                    ),

                    const SizedBox(height: 16),

                    // Bank Code
                    const Text("Beneficiary Bank Code"),
                    TextFormField(
                      controller: _bankCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter bank routing/sort code",
                      ),
                      validator: (value) => value!.isEmpty ? "Bank code is required" : null,
                    ),

                    const SizedBox(height: 16),

                    // Account Number
                    const Text("Beneficiary Account Number"),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter account number",
                      ),
                      validator: (value) => value!.isEmpty ? "Account number is required" : null,
                    ),

                    const SizedBox(height: 16),

                    // Payment Scheme
                    const Text("Payment Scheme"),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentScheme,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "swift", child: Text("SWIFT")),
                        DropdownMenuItem(value: "ach", child: Text("ACH")),
                        DropdownMenuItem(value: "fed_wire", child: Text("FED WIRE")),
                        DropdownMenuItem(value: "fps", child: Text("FPS")),
                        DropdownMenuItem(value: "sepa", child: Text("SEPA")),
                        DropdownMenuItem(value: "sepa_instant", child: Text("SEPA INSTANT")),



                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentScheme = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // NEW FIELD: Bank Sort Code
                    const Text("Beneficiary Bank Sort Code"),
                    TextFormField(
                      controller: _bankSortCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter bank sort code",
                      ),
                      validator: (value) => value!.isEmpty ? "Bank sort code is required" : null,
                    ),

                    const SizedBox(height: 16),

// NEW FIELD: Bank SWIFT Code
                    const Text("Beneficiary Bank SWIFT Code"),
                    TextFormField(
                      controller: _bankSwiftCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter SWIFT/BIC code (e.g., ABCDUS33)",
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return "SWIFT code is required";
                        if (value.length < 8 || value.length > 11) {
                          return "SWIFT code must be 8-11 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Amount
                    const Text("Amount"),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter amount",
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (value) => value!.isEmpty ? "Enter a valid amount" : null,
                    ),

                    const SizedBox(height: 16),

                    // Narration
                    const Text("Description (Optional)"),
                    TextFormField(
                      controller: _narrationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter transfer description",
                      ),
                    ),
/*
                    const SizedBox(height: 16),

                    // Save Beneficiary Checkbox

                    CheckboxListTile(
                      title: const Text("Save as Beneficiary"),
                      value: saveBeneficiary,
                      onChanged: (value) {
                        setState(() {
                          saveBeneficiary = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

 */

                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedCountryCode != null) {
                            _showTransactionSummary();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all required fields")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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


  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: message.contains("✅")
            ? const Text("✅ Transfer Successful")
            : const Text("❌ Transfer Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              if (message.contains("✅")) {
                // If successful, reload the page (reset everything)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
                  controller.fetchBanks();
                  controller.fetchSourceWallets();
                  controller.clearBeneficiaryName();
                });
                _resetForm();
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

}
