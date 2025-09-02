import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/TargetSavingsController.dart';
import '../controller/wallet_transfer_controller.dart';

class TargetSavingsApplicationPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double targetAmount;
  final int duration;
  final String frequency;
  final bool autoDebit;
  final Map<String, dynamic> calculationResult;
  final Map<String, dynamic>? productDetails;

  const TargetSavingsApplicationPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.targetAmount,
    required this.duration,
    required this.frequency,
    required this.autoDebit,
    required this.calculationResult,
    this.productDetails,
  }) : super(key: key);

  @override
  State<TargetSavingsApplicationPage> createState() => _TargetSavingsApplicationPageState();
}

class _TargetSavingsApplicationPageState extends State<TargetSavingsApplicationPage> {
  String? selectedSourceWallet;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountNameController = TextEditingController();

  Color? _primaryColor;
  String _selectedSavingSourceChannel = '';
  String? _selectedWalletIdx;
  String? _selectedBankId;
  String? wallet_number;
  Map<String, dynamic>? _selectedBank;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });

    _selectedSavingSourceChannel = widget.autoDebit ? 'direct-debit' : 'bank-transfer';
    _loadThemeColors();
    context.read<TargetSavingsController>().getBanks();
  }

  Future<void> _loadThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    if (settingsJson == null) return;
    final settings = json.decode(settingsJson);
    final data = settings['data'] ?? {};
    setState(() {
      _primaryColor = _parseColor(data['customized-app-primary-color']) ?? const Color(0xFF1B3A5D);
    });
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor ?? Theme.of(context).primaryColor;
    final transferController = Provider.of<WalletTransferController>(context);


    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Confirm Savings Plan",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<TargetSavingsController>(
        builder: (context, controller, child) {
          if (widget.calculationResult == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: Missing calculation data'),
                  Text('Please go back and recalculate.'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSummaryCard(color),
                  const SizedBox(height: 20),
                  _buildSourceSelection(color, controller,transferController),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<TargetSavingsController>(
        builder: (context, controller, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: controller.isApplying ? null : () => _submitApplication(controller,wallet_number!.toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: controller.isApplying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Start Saving', style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Color color) {
    // Add null checks and default values for all calculation result fields
    final monthlySavings = widget.calculationResult['periodic_saving_amount'] ?? 0.0;
    final totalInterest = widget.calculationResult['total_interest_amount'] ?? 0.0;
    final totalSavings = widget.calculationResult['total_value_at_maturity'] ?? 0.0;
    final interestRate = widget.calculationResult['interest_rate_pct'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            _buildRow('Target Amount', '₦${NumberFormat('#,##0.00').format(widget.targetAmount)}'),
            _buildRow('Duration', '${widget.duration} months'),
            _buildRow('Frequency', widget.frequency.toUpperCase()),
            _buildRow('Auto Debit', widget.autoDebit ? 'Enabled' : 'Disabled'),
            _buildRow('Monthly Savings', '₦${NumberFormat('#,##0.00').format(monthlySavings)}'),
            _buildRow('Total Interest', '₦${NumberFormat('#,##0.00').format(totalInterest)}'),
            _buildRow('Total Savings', '₦${NumberFormat('#,##0.00').format(totalSavings)}'),
            _buildRow('Interest Rate', '${interestRate.toStringAsFixed(2)}% P.A.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelection(Color color, TargetSavingsController controller, WalletTransferController transferController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedSavingSourceChannel,
          items: const [
            DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
            DropdownMenuItem(value: 'direct-debit', child: Text('Direct Debit')),
            DropdownMenuItem(value: 'bank-transfer', child: Text('Bank Transfer')),
          ],
          decoration: InputDecoration(
            labelText: 'Saving Source Channel',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() {
              _selectedSavingSourceChannel = value!;
              _selectedBankId = null;
              _selectedBank = null;
              _bankAccountNumberController.clear();
              _bankAccountNameController.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        if (_selectedSavingSourceChannel == 'wallet')
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedSourceWallet,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: transferController.sourceWallets.map((wallet) {
              return DropdownMenuItem<String>(
                value: wallet['id']+"**#*"+wallet['account_number'].toString(),
                child: Text(
                  "${wallet['account_number']} - (${wallet['available_balance']} NGN)",
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() {

              String input=value!;
              List<String> parts=input.split("**#*");
              selectedSourceWallet= parts[0];
              wallet_number=parts[1];
            } ),
            validator: (value) => value == null ? "Please select a source wallet" : null,
          ),
        if (_selectedSavingSourceChannel != 'wallet') ...[
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedBank,
            decoration: const InputDecoration(labelText: 'Bank'),
            items: (controller.banks ?? [])
                .map((bank) => DropdownMenuItem(
              value: bank,
              child: Text(bank['name']?.toString() ?? 'Unknown Bank'),
            ))
                .toList(),
            onChanged: (bank) => setState(() {
              _selectedBank = bank;
              _selectedBankId = bank?['id'];
            }),
            validator: (val) => val == null ? 'Select a bank' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankAccountNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Bank Account Number'),
            validator: (val) =>
            val == null || val.isEmpty ? 'Enter account number' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankAccountNameController,
            decoration: const InputDecoration(labelText: 'Account Name'),
            validator: (val) =>
            val == null || val.isEmpty ? 'Enter account name' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _submitApplication(TargetSavingsController controller, String wallet_number) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.applyForTargetSavings(
      savingsProductId: widget.productId,
      targetAmount: widget.targetAmount,
      desiredLockPeriod: widget.duration.toString(),
      savingSourceChannel: _selectedSavingSourceChannel,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      walletId: selectedSourceWallet,
      bankId: _selectedBankId,
      bankAccountNumber:_selectedSavingSourceChannel == 'wallet'?wallet_number.toString() :_bankAccountNumberController.text,
      bankAccountName: _bankAccountNameController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Savings plan created successfully'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context)..pop()..pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(controller.applicationError),
        backgroundColor: Colors.red,
      ));
    }
  }
}
