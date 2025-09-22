import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_to_bank_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class WalletToBankTransferPageIntent extends StatefulWidget {
  final Map<String, dynamic> wallet;

   WalletToBankTransferPageIntent({super.key, required this.wallet});

  @override
  State<WalletToBankTransferPageIntent> createState() => _WalletToBankTransferPageState();
}

class _WalletToBankTransferPageState extends State<WalletToBankTransferPageIntent> {
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
      final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
      controller.fetchBanks();
      controller.fetchSourceWallets();
      controller.fetchSavedBeneficiaries(); // 👈 Add this
      _resetForm();
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
  void _showTransactionSummary() {
    // 1️⃣ Hide the keyboard first
    FocusManager.instance.primaryFocus?.unfocus();

    // 2️⃣ Wait for MediaQuery to update so viewInsets is accurate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                // ✅ Use updated bottomInset (will be 0 if keyboard is gone)
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
                                    formatNumber(_amountController.text),
                                    isAmount: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDetailRow(
                                    "RECIPIENT BANK",
                                    selectedBank ?? "Not Selected",
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDetailRow(
                                    "ACCOUNT NUMBER",
                                    _accountNumberController.text,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDetailRow(
                                    "ACCOUNT NAME",
                                    context
                                        .read<WalletToBankTransferController>()
                                        .beneficiaryName,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDetailRow(
                                    "NARRATION",
                                    _narrationController.text.isNotEmpty
                                        ? _narrationController.text
                                        : "Wallet to Bank Transfer",
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDetailRow(
                                    "SAVE AS BENEFICIARY",
                                    saveBeneficiary ? "Yes" : "No",
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // PIN Section
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Center(
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
                                    margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                                    _pinController.text.length - 1,
                                                  );
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

                            // Action Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Consumer<WalletToBankTransferController>(
                                builder: (context, controller, child) {
                                  final canProceed = _pinController.text.length == 4 &&
                                      !controller.isProcessing &&
                                      !isLoading;

                                  return SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: canProceed
                                          ? () => _confirmTransfer(controller)
                                          : null,
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
                            context
                                .read<WalletToBankTransferController>()
                                .isProcessing)
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
    });
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
  Future<Map<String, dynamic>> completeBankTransfer({
    required String sourceWallet,
    required String destinationAccountNumber,
    required String bankId,
    required double amount,
    required String description,
    required String transactionPin,
    required bool saveBeneficiary,
  }) async {
    String _transactionMessage="";

    try {
      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
        return {"success": false, "message": _transactionMessage};
      }

      final requestBody = {
        "source_wallet_number": sourceWallet,
        "destination_account_number": destinationAccountNumber,
        "bank_id": bankId,
        "amount": amount,
        "description": description.isNotEmpty ? description : "Wallet to Bank Transfer",
        "transaction_pin": transactionPin,
      };

      final response = await ApiService.postRequest(
        "/customers/wallet-to-bank-transaction/process",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},
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


  void _confirmTransfer(WalletToBankTransferController controller) async {

    setState(() {
      isLoading = true;
    });

    Navigator.pop(context); // Close the PIN modal

    final result=await completeBankTransfer(sourceWallet: widget.wallet['wallet_number'],
        destinationAccountNumber:_accountNumberController.text,
        bankId:selectedBankId!,
        amount: double.parse(_amountController.text.replaceAll(",", "")),
        description:  _narrationController.text.isNotEmpty ? _narrationController.text : "Wallet to Bank Transfer",
        transactionPin: _pinController.text,
        saveBeneficiary: saveBeneficiary);






    // 🧠 Attempt to save beneficiary only if transfer succeeded
    if (saveBeneficiary && result["success"]) {
      final saveResult = await controller.saveBeneficiary(
        beneficiaryName: controller.beneficiaryName,
        accountNumber: _accountNumberController.text,
        bankId: selectedBankId!,
        transactionPin: _pinController.text,
        nickname: null,
      );

      // 🔁 Refresh saved beneficiaries list regardless of outcome
       controller.fetchSavedBeneficiaries(); // ⬅️ Refetch and overwrite

      if (!saveResult["success"] &&
          !saveResult["message"]
              .toString()
              .contains("Beneficiary Identifier has already been taken")) {
        _showResultDialog("⚠️ Transfer succeeded, but saving beneficiary failed: ${saveResult["message"]}");
      }
    }

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      _resetForm(); // Reset form on success

      // ✅ Refetch and store beneficiaries
      await controller.fetchSavedBeneficiaries(); // This refetches and sets _savedBeneficiaries in controller

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_beneficiaries', jsonEncode(controller.savedBeneficiaries));
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

  void _showSavedBeneficiaries(BuildContext context) {
    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    final beneficiaries = controller.savedBeneficiaries;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Saved Beneficiaries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: beneficiaries.isEmpty
                  ? const Center(child: Text("You have no beneficiaries saved.")) // Updated text here
                  : ListView.separated(
                itemCount: beneficiaries.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final b = beneficiaries[index];
                  return ListTile(
                    title: Text(b['beneficiary_name'] ?? b['account_number']),
                    subtitle: Text("${b['bank_name']} - ${b['account_number']}"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      setState(() {
                        _accountNumberController.text = b["account_number"];
                        selectedBankId = b["bank_id"];
                        final bank = controller.banks.firstWhere(
                              (bk) => bk['id'].toString() == b['bank_id'],
                          orElse: () => {'bank_code': '', 'bank_name': ''},
                        );
                        selectedBank = bank['bank_code'];
                      });
                      controller.verifyBankAccount(
                        accountNumber: b["account_number"],
                        bankId: b["bank_id"],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }




  void _resetForm() {
    _formKey.currentState?.reset();
    _accountNumberController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();
    setState(() {
      selectedBank = null;
      selectedBankId = null;
    });

    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    controller.clearBeneficiaryName();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<WalletToBankTransferController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet to Bank Transfer"),
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

                    const SizedBox(height: 20),



                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showSavedBeneficiaries(context),
                          icon: const Icon(Icons.people_alt_outlined, size: 18),
                          label: const Text("Saved Beneficiary"),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFFEB6D00), // 👈 Orange text
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),


                    const Text("Account Number"),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // labelText: "Account Number",
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],

                      onChanged: (value) {
                        final controller = Provider.of<WalletToBankTransferController>(context, listen: false);

                        if (value.length >= 3) {
                          final suggestions = controller.savedBeneficiaries.where((b) {
                            return b['account_number'] != null &&
                                b['account_number'].toString().contains(value);
                          }).toList();

                          setState(() {
                            filteredSuggestions = suggestions;
                            showSuggestions = suggestions.isNotEmpty;
                          });
                        } else {
                          setState(() {
                            showSuggestions = false;
                          });
                        }

                        if (value.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                          controller.verifyBankAccount(
                            accountNumber: value,
                            bankId: selectedBankId!,
                          );
                        }
                      },


                    ),
                    const SizedBox(height: 16),
                    const Text("Select Bank"),
                    DropdownSearch<Map<String, String>>(
                      items: controller.banks.map<Map<String, String>>((bank) => {
                        "bank_code": bank["bank_code"].toString(),
                        "bank_name": bank["bank_name"].toString(),
                      }).toList(),
                      itemAsString: (bank) => bank["bank_name"]!,
                      selectedItem: controller.banks
                          .map<Map<String, String>>((bank) => {
                        "bank_code": bank["bank_code"].toString(),
                        "bank_name": bank["bank_name"].toString(),
                      })
                          .firstWhere(
                            (bank) => bank["bank_code"] == selectedBank,
                        orElse: () => {"bank_code": "", "bank_name": "Select Bank"},
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(),
                          // labelText: "Select Bank",
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          selectedBank = value?["bank_code"];
                          selectedBankId = controller.banks.firstWhere(
                                (bank) => bank['bank_code'].toString() == selectedBank,
                            orElse: () => {'id': null},
                          )['id']?.toString();
                        });

                        // ✅ Trigger verification if account number is already 10 digits
                        final accountNumber = _accountNumberController.text;
                        if (accountNumber.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                          controller.verifyBankAccount(
                            accountNumber: accountNumber,
                            bankId: selectedBankId!,
                          );
                        }
                      },



                      validator: (value) => value == null ? "Please select a bank" : null,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(labelText: "Search Bank"),
                        ),
                      ),
                    ),



                    if (showSuggestions)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredSuggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final suggestion = filteredSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                suggestion['beneficiary_name'] ?? suggestion['account_number'],
                                style: TextStyle(color: Color(0xFFEB6D00)),
                              ),
                              subtitle: Text(
                                "${suggestion['bank_name']} - ${suggestion['account_number']}",
                                style: TextStyle(color: Color(0xFFEB6D00)),
                              ),

                              onTap: () {
                                setState(() {
                                  _accountNumberController.text = suggestion['account_number'];
                                  selectedBankId = suggestion['bank_id'];
                                  showSuggestions = false;

                                  final bank = controller.banks.firstWhere(
                                        (bk) => bk['id'].toString() == suggestion['bank_id'],
                                    orElse: () => {'bank_code': '', 'bank_name': ''},
                                  );
                                  selectedBank = bank['bank_code'];
                                });

                                controller.verifyBankAccount(
                                  accountNumber: suggestion['account_number'],
                                  bankId: suggestion['bank_id'],
                                );
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 8),

                    controller.isVerifyingWallet
                        ? const CircularProgressIndicator()
                        : Text(
                      controller.beneficiaryName.isNotEmpty
                          ? "Beneficiary: ${controller.beneficiaryName}"
                          : "Enter account number to verify",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),


                    const SizedBox(height: 16),

                    const Text("Amount"),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (value) => value!.isEmpty ? "Enter a valid amount" : null,
                    ),

                    const SizedBox(height: 16),

                    const Text("Narration (Optional)"),
                    TextFormField(
                      controller: _narrationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // labelText: "Narration (Optional)",
                      ),
                    ),

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

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _showTransactionSummary();
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
}
