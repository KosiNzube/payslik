import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobeller/pages/borrowers/processSubscriptionRequest.dart';
import 'package:gobeller/pages/property/property_history_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gobeller/controller/loan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/pages/success/widget/searchable_bank_dropdown.dart';
import '../../controller/property_controller.dart';


class InitiateSubscriptionScreen extends StatefulWidget {
  final String propertyId;
  final int quantity; // <-- Add this

  const InitiateSubscriptionScreen({
    super.key,
    required this.propertyId,
    required this.quantity, // <-- Assign this
  });

  @override
  State<InitiateSubscriptionScreen> createState() => _InitiateSubscriptionScreenState();
}


class _InitiateSubscriptionScreenState extends State<InitiateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNameController = TextEditingController();

  int _quantity = 1;
  DateTime? _startDate;
  int _durationInterval = 1;
  String _paymentOption = 'wallet'; // or String? _paymentOption;



  String? _bankId;
  String? _bankAccountNumber;
  String? _bankAccountName;

  String? _walletId;
  String? productName;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;
  String? _selectedBankId;
  String? _selectedWalletId;
  String? _selectedBankName;
  String? _selectedWalletName;
  bool _isFormValid = false;

  // Add this to track the last processed beneficiary name
  String _lastProcessedBeneficiaryName = '';

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  LoanController? _loanController;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo(); // optional

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<LoanController>(context, listen: false);
      _loanController = controller;

      await controller.fetchBanks();
      await controller.fetchSourceWallets();

      if (mounted) {
        controller.addListener(_onLoanControllerChange);
      }
    });
  }

  void _onLoanControllerChange() {
    if (!mounted || _loanController == null) return;

    final controller = _loanController!;

    if (controller.beneficiaryName.isNotEmpty &&
        _lastProcessedBeneficiaryName != controller.beneficiaryName) {
      setState(() {
        _bankAccountName = controller.beneficiaryName;
        _accountNameController.text = _bankAccountName ?? '';
        _lastProcessedBeneficiaryName = controller.beneficiaryName;
      });
    }
  }

  // @override
  // void dispose() {
  //   _loanController?.removeListener(_onLoanControllerChange);
  //   super.dispose();
  // }



  void _updateFormValidity() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isFormValid = isValid && _startDate != null;
    });
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

  @override
  void dispose() {
    // Remove the listener before disposing
    try {
      final controller = Provider.of<LoanController>(context, listen: false);
      controller.removeListener(_onLoanControllerChange);
    } catch (e) {
      // Handle case where context might be unavailable
      print('Error removing listener: $e');
    }

    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyController = Provider.of<PropertyController>(context);
    final loanController = Provider.of<LoanController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Initiate Subscription")),
      body: propertyController.isSubscriptionLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Property ID display removed - it was here:
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 16),
              //   child: Text(
              //     "Property ID: ${widget.propertyId}",
              //     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              //   ),
              // ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Purchase Quantity",
                  helperText: "Enter the number of units you want to purchase (Maximum: ${widget.quantity})",
                  prefixIcon: const Icon(Icons.shopping_cart),
                ),
                keyboardType: TextInputType.number,
                initialValue: _quantity.toString(),
                validator: (value) {
                  final val = int.tryParse(value ?? '');
                  if (val == null || val <= 0) return "Please enter a valid number of units";
                  if (val > widget.quantity) return "Maximum available units is ${widget.quantity}";
                  return null;
                },
                onSaved: (value) => _quantity = int.tryParse(value ?? '1') ?? 1,
              ),

              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? "When would you like payments to begin?"
                    : "Payment Start Date: ${_dateFormat.format(_startDate!)}"),
                subtitle: _startDate == null 
                    ? const Text("Tap to select a date")
                    : null,
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                  _updateFormValidity();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Payment Duration",
                  helperText: "How many months would you like to spread the payment over?",
                  prefixIcon: Icon(Icons.access_time),
                  suffixText: "months",
                ),
                keyboardType: TextInputType.number,
                initialValue: _durationInterval.toString(),
                onSaved: (value) => _durationInterval = int.tryParse(value ?? '1') ?? 1,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentOption,
                decoration: const InputDecoration(
                  labelText: "How would you like to pay?",
                  helperText: "Choose your preferred payment method",
                  prefixIcon: Icon(Icons.payment),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'wallet',
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance_wallet, size: 20),
                        SizedBox(width: 8),
                        Text("Pay from Wallet"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'direct-debit',
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance, size: 20),
                        SizedBox(width: 8),
                        Text("Direct Debit (Bank Account)"),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentOption = value!;
                    _selectedBankId = null;
                    _selectedWalletId = null;
                    _bankAccountNumber = null;
                    _bankAccountName = null;
                    _accountNameController.clear();
                    _lastProcessedBeneficiaryName = '';
                  });
                  _updateFormValidity();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select how you would like to pay';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              _buildPaymentInfoBanner(),
              const SizedBox(height: 16),

              if (_paymentOption == 'wallet')
                _buildWalletSelector(),

              if (_paymentOption == 'direct-debit') ...[
                _buildBankDropdownField(),
                const SizedBox(height: 16),
                _buildBankAccountFields(),
              ],


              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isFormValid ? () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  if (_startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a payment start date")),
                    );
                    return;
                  }

                  final result = await propertyController.initiateSubscriptionRequest(
                    propertyId: widget.propertyId,
                    quantity: _quantity,
                    desiredPaymentStartDate: _dateFormat.format(_startDate!),
                    desiredPaymentDurationInterval: _durationInterval,
                    preferredPaymentOption: _paymentOption,
                    bankId: _selectedBankId,
                    bankAccountNumber: _bankAccountNumber,
                    bankAccountName: _bankAccountName,
                    walletId: _selectedWalletId,

                  );

                  if (result['status'] == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessSubscriptionScreen(
                          propertyId: widget.propertyId,
                          quantity: _quantity,
                          desiredPaymentStartDate: _dateFormat.format(_startDate!),
                          desiredPaymentDurationInterval: _durationInterval,
                          preferredPaymentOption: _paymentOption,
                          bankId: _selectedBankId,
                          bankAccountNumber: _bankAccountNumber,
                          bankAccountName: _bankAccountName,
                          walletId: _selectedWalletId,
                          bankName: _selectedBankName,
                          walletName: _selectedWalletName,
                        ),
                      ),
                    );
                  }
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed: ${result['message']}")),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid ? (_primaryColor ?? Colors.blue) : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Initiate Subscription"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDropdownField() {
    return Consumer<LoanController>(
      builder: (context, loanController, _) {
        final banks = loanController.banks;

        return SearchableBankDropdown(
          banks: banks,
          value: _selectedBankId,
          onChanged: (value) {
            setState(() {
              _selectedBankId = value;
              // Get the bank name when selected
              _selectedBankName = banks.firstWhere(
                (bank) => bank['id'].toString() == value,
                orElse: () => {'name': ''},
              )['name']?.toString();
              // Reset account info when bank changes
              _bankAccountNumber = null;
              _bankAccountName = null;
              _accountNameController.clear();
              _lastProcessedBeneficiaryName = '';
            });
          },
          validator: (value) {
            if ((_paymentOption == 'bank' || _paymentOption == 'direct-debit') && value == null) {
              return 'Please select a bank';
            }
            return null;
          },
          labelText: 'Select Your Bank',
          helperText: 'Choose your bank for direct debit payments',
        );
      },
    );
  }

  Widget _buildBankAccountFields() {
    return Consumer<LoanController>(
      builder: (context, loanController, _) {
        // Handle beneficiary name update with improved logic
        if (loanController.beneficiaryName.isNotEmpty &&
            _lastProcessedBeneficiaryName != loanController.beneficiaryName &&
            mounted) {
          // Use Future.microtask to avoid setState during build
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _bankAccountName = loanController.beneficiaryName;
                _accountNameController.text = _bankAccountName ?? '';
                _lastProcessedBeneficiaryName = loanController.beneficiaryName;
              });

            }
          });
        }

        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Bank Account Number",
                helperText: "Enter your 10-digit bank account number",
                prefixIcon: Icon(Icons.account_box),
                hintText: "Example: 0123456789",
              ),
              keyboardType: TextInputType.number,
              maxLength: 10,
              onChanged: (val) {
                setState(() {
                  _bankAccountNumber = val;
                });

                // Trigger verification when account number is complete
                if (val.length == 10 && _selectedBankId != null) {
                  // Clear previous beneficiary name before new verification
                  _lastProcessedBeneficiaryName = '';
                  _bankAccountName = null;
                  _accountNameController.clear();

                  loanController.verifyBankAccount(
                    accountNumber: val,
                    bankId: _selectedBankId!,
                  );
                } else if (val.length < 10) {
                  // Clear account name if user is still typing
                  setState(() {
                    _bankAccountName = null;
                    _accountNameController.clear();
                    _lastProcessedBeneficiaryName = '';
                  });
                }

              },
              validator: (value) {
                if ((_paymentOption == 'bank' || _paymentOption == 'direct-debit')) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  if (value.length != 10) {
                    return 'Account number must be 10 digits';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (loanController.isVerifyingWallet)
              Column(
                children: [
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 4),
                  Text(
                    'Verifying account...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Account Holder's Name",
                helperText: "This will be automatically filled after account verification",
                prefixIcon: const Icon(Icons.person),
                hintText: "Account name will appear here after verification",
                suffixIcon: _bankAccountName != null
                    ? Icon(Icons.check_circle, color: Colors.green.shade600)
                    : null,
              ),
              controller: _accountNameController,
              readOnly: true,
              validator: (value) {
                if ((_paymentOption == 'bank' || _paymentOption == 'direct-debit')) {
                  if (value == null || value.isEmpty) {
                    return 'Account name is required';
                  }
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWalletSelector() {
    return Consumer<LoanController>(
      builder: (context, loanController, _) {
        // Show loading state
        if (loanController.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading wallets...'),
                ],
              ),
            ),
          );
        }

        final wallets = loanController.sourceWallets;

        // Debug info (remove in production)
        print('🔹 Wallet selector - wallets count: ${wallets.length}');
        print('🔹 Wallet selector - wallets data: $wallets');

        // Show error/empty state with retry option
        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No wallets found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please make sure you have a personal wallet set up',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    print('🔄 Retrying wallet fetch...');
                    await loanController.fetchSourceWallets();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          );
        }

        // Show wallet dropdown
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Wallet',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: '${wallets.length} wallet(s) available',
            ),
            value: _selectedWalletId,
            items: wallets.map((wallet) {
              String walletId = wallet['id']?.toString() ?? '';
              String walletType = wallet['wallet_type']?.toString() ?? 'Wallet';
              String walletNumber = wallet['account_number']?.toString() ?? wallet['wallet_number']?.toString() ?? 'N/A';
              String currencySymbol = wallet['currency_symbol']?.toString() ?? '₦';
              String balance = wallet['available_balance']?.toString() ?? wallet['balance']?.toString() ?? '0.00';
              String label = '$walletType - $walletNumber';
              if (balance != '0.00') {
                label += ' ($currencySymbol$balance)';
              } else {
                label += ' ($currencySymbol)';
              }

              return DropdownMenuItem<String>(
                value: walletId,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (wallet['ownership_label'] != null)
                      Text(
                        wallet['ownership_label'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return wallets.map((wallet) {
                String walletType = wallet['wallet_type']?.toString() ?? 'Wallet';
                String walletNumber = wallet['account_number']?.toString() ?? wallet['wallet_number']?.toString() ?? 'N/A';
                String currencySymbol = wallet['currency_symbol']?.toString() ?? '₦';
                String balance = wallet['available_balance']?.toString() ?? wallet['balance']?.toString() ?? '0.00';
                String label = '$walletType - $walletNumber';
                if (balance != '0.00') {
                  label += ' ($currencySymbol$balance)';
                } else {
                  label += ' ($currencySymbol)';
                }

                return Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                );
              }).toList();
            },
            onChanged: (value) {
              print('🔹 Selected wallet ID: $value');
              setState(() {
                _selectedWalletId = value;
                // Get the wallet name when selected
                if (value != null) {
                  final selectedWallet = wallets.firstWhere(
                    (wallet) => wallet['id'].toString() == value,
                    orElse: () => {},
                  );
                  String walletType = selectedWallet['wallet_type']?.toString() ?? 'Wallet';
                  String walletNumber = selectedWallet['account_number']?.toString() ?? selectedWallet['wallet_number']?.toString() ?? 'N/A';
                  _selectedWalletName = '$walletType - $walletNumber';
                } else {
                  _selectedWalletName = null;
                }
              });
            },
            validator: (value) {
              if (_paymentOption == 'wallet' && (value == null || value.isEmpty)) {
                return 'Please select a wallet for repayment';
              }
              return null;
            },
            isExpanded: true,
          ),
        );
      },
    );
  }
  Widget _buildPaymentInfoBanner() {
    String message;
    IconData icon = Icons.info_outline;
    Color backgroundColor = Colors.blue.shade50;
    Color textColor = Colors.blue.shade900;

    switch (_paymentOption) {
      case 'bank':
        message = "Payment for this subscription will be automatically deducted from your selected bank account.";
        break;
      case 'wallet':
        message = "Payment for this subscription will be automatically deducted from your selected wallet.";
        break;
      case 'direct-debit':
        message = "Your subscription payment will be processed automatically via direct debit.";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

}