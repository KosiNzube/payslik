import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/TargetSavingsController.dart';
import 'TargetSavingsApplicationPage.dart';

class TargetSavingsCalculatorPage extends StatefulWidget {
  final String productId;
  final String productName;
  final Map<String, dynamic> product;

  const TargetSavingsCalculatorPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.product,
  }) : super(key: key);

  @override
  State<TargetSavingsCalculatorPage> createState() => _TargetSavingsCalculatorPageState();
}

class _TargetSavingsCalculatorPageState extends State<TargetSavingsCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  bool _hasCalculated = false;
  bool _autoDebit = true;
  String _frequency = 'monthly';
  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadThemeColors();
    // Set initial duration to minimum lock period
    _durationController.text = widget.product['lock_min_period'].toString();
    _autoDebit=widget.product['allow_auto_debit'];
  }

  Future<void> _loadThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    if (settingsJson == null) return;

    try {
      final settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};
      setState(() {
        _primaryColor = _parseColor(data['customized-app-primary-color']);
        _secondaryColor = _parseColor(data['customized-app-secondary-color']);
      });
    } catch (_) {}
  }

  Color? _parseColor(String? hexColor) {
    return hexColor != null
        ? Color(int.parse(hexColor.replaceAll('#', '0xFF')))
        : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _calculateSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final duration = int.parse(_durationController.text);

    final success = await context.read<TargetSavingsController>().calculateSchedule(
      savingsProductId: widget.productId,
      targetAmount: amount,
      desiredLockPeriod: duration.toString(),
    );

    if (success) {
      setState(() => _hasCalculated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _primaryColor ?? theme.primaryColor;
    final secondaryColor = _secondaryColor ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor!, _primaryColor!],
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
          "Savings Calculator",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.productName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.percent, color: primaryColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.product['interest_rate']}% P.A.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Calculator Form
                Text(
                  'Savings Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Target Amount Input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₦ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter target amount';
                    }
                    final amount = double.tryParse(value.replaceAll(',', '')) ?? 0;
                    final minAmount = double.tryParse(
                        widget.product['min_target_amount']?.toString() ?? '0') ?? 0;
                    final maxAmount = widget.product['max_target_amount'] != null
                        ? double.tryParse(widget.product['max_target_amount'].toString())
                        : null;

                    if (amount < minAmount) {
                      return 'Minimum amount is ₦${NumberFormat('#,##0').format(minAmount)}';
                    }
                    if (maxAmount != null && amount > maxAmount) {
                      return 'Maximum amount is ₦${NumberFormat('#,##0').format(maxAmount)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Duration Input
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (months)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    final duration = int.tryParse(value) ?? 0;
                    final minPeriod = widget.product['lock_min_period'] ?? 1;
                    final maxPeriod = widget.product['lock_max_period'];

                    if (duration < minPeriod) {
                      return 'Minimum duration is $minPeriod months';
                    }
                    if (maxPeriod != null && duration > maxPeriod) {
                      return 'Maximum duration is $maxPeriod months';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  value: _frequency,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) => setState(() => _frequency = value!),
                  decoration: InputDecoration(
                    labelText: 'Savings Frequency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Auto Debit Switch
                const SizedBox(height: 24),

                // Calculate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Calculate Savings Plan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Results Section
                if (_hasCalculated) _buildResultsSection(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildResultsSection(Color primaryColor) {
    return Consumer<TargetSavingsController>(
      builder: (context, controller, _) {
        final result = controller.scheduleResult;
        if (result == null) return const SizedBox();

        // Add null checks and default values for all numeric fields
        final targetAmount = result['target_amount'] ?? 0.0;
        final monthlySavings = result['periodic_saving_amount'] ?? 0.0;
        final totalInterest = result['total_interest_amount'] ?? 0.0;
        final totalSavings = result['total_value_at_maturity'] ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Savings Plan Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Target Amount',
                '₦${NumberFormat('#,##0').format(targetAmount)}'),
            _buildSummaryRow('Monthly Savings',
                '₦${NumberFormat('#,##0').format(monthlySavings)}'),
            _buildSummaryRow('Total Interest',
                '₦${NumberFormat('#,##0').format(totalInterest)}'),
            _buildSummaryRow('Total Savings',
                '₦${NumberFormat('#,##0').format(totalSavings)}'),
            _buildSummaryRow('Duration', '${_durationController.text} months'),
            _buildSummaryRow('Frequency', _frequency),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add validation before navigation
                  final amountText = _amountController.text.replaceAll(',', '');
                  final durationText = _durationController.text;

                  if (amountText.isEmpty || durationText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all required fields')),
                    );
                    return;
                  }

                  final targetAmountValue = double.tryParse(amountText);
                  final durationValue = int.tryParse(durationText);

                  if (targetAmountValue == null || durationValue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid numbers')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TargetSavingsApplicationPage(
                        productId: widget.productId,
                        productName: widget.productName,
                        targetAmount: targetAmountValue,
                        duration: durationValue,
                        frequency: _frequency,
                        autoDebit: _autoDebit,
                        calculationResult: result,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Saving',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}