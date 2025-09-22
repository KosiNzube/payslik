// Unchanged imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gobeller/utils/currency_input_formatter.dart';
import 'package:gobeller/controller/wallet_transfer_controller.dart';

import '../../utils/routes.dart';

class WalletToWalletTransferPageIntent extends StatefulWidget {
  final Map<String, dynamic> wallet;

  WalletToWalletTransferPageIntent({super.key, required this.wallet});

  @override
  State<WalletToWalletTransferPageIntent> createState() => _WalletToWalletTransferPageState();
}

class _WalletToWalletTransferPageState extends State<WalletToWalletTransferPageIntent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destWalletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final formatter = NumberFormat('#,###');

  String? selectedSourceWallet;
  bool _isPinHidden = true;
  bool _isCompletingTransfer = false;

  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _fetchThemeColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });

    selectedSourceWallet=widget.wallet['wallet_number']??"---";

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

  void _resetForm(WalletTransferController controller) {
    _formKey.currentState?.reset();
    _destWalletController.clear();
    _amountController.clear();
    _narrationController.clear();
    _pinController.clear();

    controller.clearBeneficiaryName();
  }

  void _showTransferResult(WalletTransferController controller) {
    if (controller.transactionMessage.contains("successfully")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Transfer Successful"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Transaction Reference: ${controller.transactionReference}"),
              Text("New Balance: ${controller.transactionCurrencySymbol}${controller.expectedBalanceAfter}"),
              Text("Status: ${controller.transactionStatus}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm(controller);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.transactionMessage)),
      );
    }
  }

  void _navigateToTransferResult(bool success, String message) {
    final controller = Provider.of<WalletTransferController>(context, listen: false);

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
  String formatNumber(String input) {
    // Remove any commas before parsing
    String cleaned = input.replaceAll(',', '');
    int? number = int.tryParse(cleaned);
    if (number == null) return input; // Return as-is if not a number
    return formatter.format(number);
  }

  void showTransactionSummaryModal(WalletTransferController controller) async {
    final primaryColor = await _getColorFromPrefs('customized-app-primary-color', const Color(0xFF171E3B));
    final secondaryColor = await _getColorFromPrefs('customized-app-secondary-color', const Color(0xFFEB6D00));

    // Hide keyboard first (more direct than FocusScope.of(context).unfocus())
    FocusManager.instance.primaryFocus?.unfocus();

    // Wait a frame so MediaQuery updates after keyboard dismissal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If this method lives inside a State class, keep this check:
      if (!mounted) return;

      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final height = MediaQuery.of(context).size.height * 0.85;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Stack(
                    children: [
                      // Make the main content scrollable
                      SingleChildScrollView(
                        child: Column(
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
                                      color: Colors.black,
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
                              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                  _buildDetailRow("AMOUNT TO TRANSFER", "${formatNumber(_amountController.text)}", isAmount: true),
                                  const SizedBox(height: 20),
                                  _buildDetailRow("TRANSACTION TYPE", "Wallet to Wallet Transfer"),
                                  const SizedBox(height: 20),
                                  _buildDetailRow("CURRENCY", controller.transactionCurrency),
                                  const SizedBox(height: 20),
                                  _buildDetailRow("ACTUAL BALANCE BEFORE", "${controller.transactionCurrencySymbol} ${controller.actualBalanceBefore}"),
                                  const SizedBox(height: 20),
                                  _buildDetailRow("PLATFORM CHARGE FEE", "${controller.transactionCurrencySymbol} ${controller.platformChargeFee}"),
                                  const SizedBox(height: 20),
                                  _buildDetailRow("EXPECTED BALANCE AFTER", "${controller.transactionCurrencySymbol} ${formatNumber(controller.expectedBalanceAfter.toString())}"),
                                ],
                              ),
                            ),

                            // PIN Section
                            const Padding(
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
                                        color: _pinController.text.length > index ? Colors.black87 : Colors.grey[300]!,
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
                            const SizedBox(height: 24), // Reduced from 32

                            // Custom PIN Pad - Made more compact
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: [
                                  _buildPinRow(['1', '2', '3'], setModalState),
                                  const SizedBox(height: 12), // Reduced from 16
                                  _buildPinRow(['4', '5', '6'], setModalState),
                                  const SizedBox(height: 12), // Reduced from 16
                                  _buildPinRow(['7', '8', '9'], setModalState),
                                  const SizedBox(height: 12), // Reduced from 16
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 60), // Empty space
                                      _buildPinButton('0', setModalState),
                                      GestureDetector(
                                        onTap: () {
                                          if (_pinController.text.isNotEmpty) {
                                            setModalState(() {
                                              _pinController.text = _pinController.text
                                                  .substring(0, _pinController.text.length - 1);
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
                            const SizedBox(height: 24), // Reduced from 40

                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _pinController.text.length == 4 && !_isCompletingTransfer
                                      ? () async {
                                    if (selectedSourceWallet == null) return;

                                    setModalState(() => _isCompletingTransfer = true);

                                    SmartDialog.showLoading(msg: "Please wait");

                                    final result = await controller.completeTransfer(
                                      sourceWallet: selectedSourceWallet!,
                                      destinationWallet: _destWalletController.text.trim(),
                                      amount: double.parse(_amountController.text.replaceAll(",","")),
                                      description: _narrationController.text.trim(),
                                      transactionPin: _pinController.text.trim(),
                                    );

                                    if (mounted) {
                                      setModalState(() => _isCompletingTransfer = false);
                                      _navigateToTransferResult(result['success'], result['message']);
                                    }

                                    SmartDialog.dismiss();
                                  }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pinController.text.length == 4 && !_isCompletingTransfer
                                        ? secondaryColor
                                        : Colors.grey[300],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isCompletingTransfer
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
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),

                      // Loading overlay

                    ],
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
  @override
  Widget build(BuildContext context) {
    final transferController = Provider.of<WalletTransferController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet to Wallet Transfer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

              const Text("Destination wallet number"),
              TextFormField(
                controller: _destWalletController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  if (value.length == 10) {
                    transferController.verifyWalletNumber(value);
                  }
                },
                validator: (value) => value!.isEmpty ? "Wallet number is required" : null,
              ),
              const SizedBox(height: 8),

              Consumer<WalletTransferController>(builder: (context, controller, _) {
                if (controller.isVerifyingWallet) {
                  return const Center(child: CircularProgressIndicator());
                } else if (controller.beneficiaryName.isNotEmpty) {
                  return Text("Beneficiary: ${controller.beneficiaryName}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                } else {
                  return const Text("Enter destination wallet number", style: TextStyle(color: Colors.red));
                }
              }),
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
                  labelText: "Narration (Optional)",
                ),
              ),
              const SizedBox(height: 16),

              transferController.isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: transferController.isProcessing
                      ? null
                      : () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedSourceWallet == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a source wallet")),
                        );
                        return;
                      }

                      transferController
                          .initializeTransfer(
                        sourceWallet: selectedSourceWallet!,
                        destinationWallet: _destWalletController.text.trim(),
                        amount: double.parse(_amountController.text.replaceAll(',', '').trim()),
                        description: _narrationController.text.trim(),
                      )
                          .then((_) => showTransactionSummaryModal(transferController));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Initialize Transfer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destWalletController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
