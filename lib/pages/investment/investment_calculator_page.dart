import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../controller/investment_controller.dart';

import 'apply_investment_page.dart';

class InvestmentCalculatorPage extends StatefulWidget {
  final String productId;
  final String productName;
  final Map<String, dynamic> product;

  const InvestmentCalculatorPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.product,
  }) : super(key: key);

  @override
  State<InvestmentCalculatorPage> createState() => _InvestmentCalculatorPageState();
}

class _InvestmentCalculatorPageState extends State<InvestmentCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _hasCalculated = false;

  // Add tenure dropdown state
  String? _selectedTenure;
  List<String> _tenureOptions = [];

  // Add these variables to the state class
  bool _autoRollover = false;
  String? _selectedPayoutDuration = 'on_maturity';

  // Add to the state class
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _initializeTenureOptions();
    _loadPrimaryColorAndLogo();
  }

  void _initializeTenureOptions() {
    final minPeriod = double.tryParse(widget.product['tenure_min_period']?.toString() ?? '0') ?? 0;
    final maxPeriod = double.tryParse(widget.product['tenure_max_period']?.toString() ?? '0') ?? 0;
    
    _tenureOptions = List.generate(
      (maxPeriod - minPeriod + 1).toInt(),
      (index) => (minPeriod + index).toStringAsFixed(0),
    );

    // Set initial value if available
    if (_tenureOptions.isNotEmpty) {
      _selectedTenure = _tenureOptions.first;
    }
  }

  // Add the loading method
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
    _amountController.dispose();
    super.dispose();
  }

  // Replace the existing tenure TextFormField with this DropdownButtonFormField
  Widget _buildTenureDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTenure,
      decoration: InputDecoration(
        labelText: 'Investment Tenure',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: _tenureOptions.map((String value) {
        final tenureDisplay = context.read<InvestmentController>()
            .getTenureTypeDisplay(widget.product['tenure_type']);
        return DropdownMenuItem<String>(
          value: value,
          child: Text('$value $tenureDisplay'),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTenure = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select investment tenure';
        }
        return null;
      },
    );
  }

  void _calculateReturns() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    
    final success = await context.read<InvestmentController>().calculateInvestment(
      productId: widget.productId,
      investmentAmount: amount,
      desiredMaturityTenure: _selectedTenure!,
    );

    if (success) {
      setState(() => _hasCalculated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _primaryColor ?? Colors.blue;
    final secondaryColor = _secondaryColor ?? Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Calculator'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[100]!,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Card with Gradient Border
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
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
                            Icon(
                              Icons.trending_up_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
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
                              Icon(
                                Icons.percent_rounded,
                                color: primaryColor,
                                size: 16,
                              ),
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

                // Calculator Form Section
                Text(
                  'Investment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Input with Styled Border
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        if (newValue.text.isEmpty) return newValue;
                        final number = int.parse(newValue.text);
                        final formatted = NumberFormat('#,###').format(number);
                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Investment Amount',
                      prefixText: '₦ ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      labelStyle: TextStyle(color: primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter investment amount';
                      }
                      final amount = double.parse(value.replaceAll(',', ''));
                      final minAmount = double.tryParse(widget.product['min_investment_amount']?.toString() ?? '0') ?? 0;
                      final maxAmount = widget.product['max_investment_amount'] != null 
                          ? double.tryParse(widget.product['max_investment_amount'].toString()) 
                          : null;
                      
                      if (amount < minAmount) {
                        return 'Minimum amount is ₦${NumberFormat('#,###').format(minAmount)}';
                      }
                      
                      if (maxAmount != null && amount > maxAmount) {
                        return 'Maximum amount is ₦${NumberFormat('#,###').format(maxAmount)}';
                      }
                      
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Tenure Dropdown with Matching Style
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildTenureDropdown(),
                ),

                const SizedBox(height: 24),
                // Styled Calculate Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _calculateReturns,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Calculate Returns',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Results Section with Enhanced Styling
                if (_hasCalculated) ...[
                  const SizedBox(height: 32),
                  Consumer<InvestmentController>(
                    builder: (context, controller, child) {
                      final result = controller.calculationResult;
                      if (result == null) return const SizedBox.shrink();

                      final summary = result['investment_summary'];
                      final schedule = result['payout_schedule'] as List;
                      final penalty = result['early_exit_penalty'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Investment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3A5D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Principal Amount', controller.formatAmount(summary['principal_amount'])),
                          _buildSummaryRow('Interest Rate', '${summary['interest_rate']}% P.A.'),
                          _buildSummaryRow('Investment Period', summary['tenure']),
                          _buildSummaryRow('Total Interest', controller.formatAmount(summary['total_interest'])),
                          _buildSummaryRow('Total Payout', controller.formatAmount(summary['total_payout'])),
                          _buildSummaryRow('Start Date', controller.formatDate(summary['start_date'])),
                          _buildSummaryRow('Maturity Date', controller.formatDate(summary['maturity_date'])),
                          if (penalty != null) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Early Exit Terms',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3A5D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              penalty['description'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  Consumer<InvestmentController>(
                    builder: (context, controller, child) {
                      if (controller.calculationResult == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 16),
                            // Investment Options
                            const Text(
                              'Investment Options',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3A5D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Payout Duration Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedPayoutDuration,
                              decoration: InputDecoration(
                                labelText: 'Interest Payout Schedule',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: controller.getPayoutDurationOptions()
                                  .map((option) => DropdownMenuItem(
                                        value: option['value'],
                                        child: Text(option['label']!),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedPayoutDuration = value);
                              },
                              validator: (value) => value == null ? 'Please select payout schedule' : null,
                            ),
                            const SizedBox(height: 16),
                            // Auto Rollover Switch
                            SwitchListTile(
                              title: const Text('Auto Rollover on Maturity'),
                              subtitle: const Text(
                                'Automatically reinvest at maturity',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _autoRollover,
                              onChanged: (bool value) {
                                setState(() => _autoRollover = value);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Apply Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amount = double.parse(_amountController.text.replaceAll(',', ''));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApplyInvestmentPage(
                                        productId: widget.productId,
                                        productName: widget.productName,
                                        amount: amount,
                                        tenure: _selectedTenure!,
                                        payoutDuration: _selectedPayoutDuration!,
                                        autoRollover: _autoRollover,
                                        calculationResult: controller.calculationResult!,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Continue to Apply',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3A5D),
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to handle investment application
  Future<void> _applyForInvestment(InvestmentController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    
    final success = await controller.applyForInvestment(
      productId: widget.productId,
      investmentAmount: amount,
      desiredMaturityTenure: _selectedTenure!,
      preferredInterestPayoutDuration: _selectedPayoutDuration!,
      autoRolloverOnMaturity: _autoRollover,
    );

    if (success) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.applicationError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}