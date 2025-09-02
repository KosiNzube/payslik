import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controller/fixed_deposit_controller.dart';

import 'fixed_deposit_contract.dart';

class FixedDepositCalculatorPage extends StatefulWidget {
  final String productId;
  final String productName;

  const FixedDepositCalculatorPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<FixedDepositCalculatorPage> createState() => _FixedDepositCalculatorPageState();
}

class _FixedDepositCalculatorPageState extends State<FixedDepositCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _selectedTenure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<FixedDepositController>(context, listen: false);
      final product = controller.selectedProduct;
      if (product != null) {
        final minPeriod = product['tenure_min_period'] as int?;
        if (minPeriod != null) {
          setState(() {
            _selectedTenure = minPeriod;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildTenureDropdown(Map<String, dynamic>? product) {
    if (product == null) {
      return const SizedBox.shrink();
    }

    final controller = Provider.of<FixedDepositController>(context, listen: false);
    final tenureOptions = controller.getTenureOptions(product);
    final tenureType = controller.getTenureTypeDisplay(product['tenure_type']);

    // Validate selected tenure is within available options
    if (_selectedTenure != null && !tenureOptions.contains(_selectedTenure)) {
      _selectedTenure = tenureOptions.isNotEmpty ? tenureOptions.first : null;
    }

    return DropdownButtonFormField<int>(
      value: _selectedTenure,
      decoration: InputDecoration(
        labelText: 'Investment Period',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: tenureOptions.map((tenure) {
        return DropdownMenuItem<int>(
          value: tenure,
          child: Text('$tenure $tenureType'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTenure = value;
        });
      },
      validator: (value) {
        if (value == null) return 'Please select an investment period';
        final minPeriod = product['tenure_min_period'] as int?;
        final maxPeriod = product['tenure_max_period'] as int?;

        if (minPeriod != null && value < minPeriod) {
          return 'Minimum period is $minPeriod ${tenureType.toLowerCase()}';
        }
        if (maxPeriod != null && value > maxPeriod) {
          return 'Maximum period is $maxPeriod ${tenureType.toLowerCase()}';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A5D),
        elevation: 0,
        title: const Text('Investment Calculator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfo(),
              const SizedBox(height: 24),
              _buildCalculatorForm(),
              const SizedBox(height: 24),
              _buildResults(),
              const SizedBox(height: 24),
              _buildCalculateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Consumer<FixedDepositController>(
        builder: (context, controller, child) {
          final product = controller.selectedProduct;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Changed to stretch
            children: [
              Row(
                children: [
                  Expanded( // Wrap Text in Expanded
                    child: Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (product != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity, // Added full width
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [ // Removed mainAxisSize: MainAxisSize.min
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded( // Wrap Text in Expanded
                        child: Text(
                          '${product['tenure_min_period']} - ${product['tenure_max_period'] ?? 'No Limit'} ' +
                          controller.getTenureTypeDisplay(product['tenure_type']).toLowerCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalculatorForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3A5D),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Investment Amount',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              prefixText: '₦ ',
              prefixStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF667EEA),
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Consumer<FixedDepositController>(
            builder: (context, controller, child) {
              return _buildTenureDropdown(controller.selectedProduct);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Consumer<FixedDepositController>(
      builder: (context, controller, child) {
        if (controller.isCalculating) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = controller.calculatorResult;
        if (result == null) {
          return const SizedBox.shrink();
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultSection('Product Terms', [
                  _buildResultRow(
                    'Tenure',
                    '${result['product_terms']['tenure_periods']} ' +
                    result['product_terms']['tenure_unit']
                  ),
                  _buildResultRow(
                    'Interest Rate',
                    '${result['product_terms']['interest_rate']}%'
                  ),
                  _buildResultRow(
                    'Payout Frequency',
                    result['product_terms']['payout_frequency']
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase()
                  ),
                ]),
                _buildResultSection('Amount Summary', [
                  _buildResultRow(
                    'Principal',
                    '₦${_formatAmount(result['amount_summary']['principal'])}'
                  ),
                  _buildResultRow(
                    'Total Interest',
                    '₦${_formatAmount(result['amount_summary']['total_interest'])}'
                  ),
                  _buildResultRow(
                    'Final Amount',
                    '₦${_formatAmount(result['amount_summary']['final_amount_on_maturity'])}'
                  ),
                ]),
                if (result['amount_summary']['early_withdrawal_penalty'] != null)
                  _buildResultSection('Early Withdrawal', [
                    _buildResultRow(
                      'Penalty Type',
                      result['amount_summary']['early_withdrawal_penalty']['type']
                          .toString()
                          .replaceAll('_', ' ')
                          .toUpperCase()
                    ),
                    _buildResultRow(
                      'Penalty Amount',
                      '₦${_formatAmount(result['amount_summary']['early_withdrawal_penalty']['calculated_amount'])}'
                    ),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667EEA),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: _calculateAndProceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calculate_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Calculate Returns',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateAndProceed() async {
    if (!_formKey.currentState!.validate() || _selectedTenure == null) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final controller = Provider.of<FixedDepositController>(context, listen: false);
    
    final success = await controller.calculateInterest(
      productId: widget.productId,
      depositAmount: amount,
      desiredTenure: _selectedTenure!,
    );

    if (!mounted) return;

    if (success) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FixedDepositContractPage(
            productId: widget.productId,
            productName: widget.productName,
            depositAmount: amount,
            tenure: _selectedTenure!,
            calculationResult: controller.calculatorResult!,
          ),
        ),
      );

      if (result == true) {
        Navigator.pop(context, true); // Close calculator page if contract was created
      }
    }
  }

  Widget _buildResultRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value is num ? '₦${_formatAmount(value)}' : value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }

  void _calculate() {
    if (!_formKey.currentState!.validate() || _selectedTenure == null) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final controller = Provider.of<FixedDepositController>(context, listen: false);
    
    controller.calculateInterest(
      productId: widget.productId,
      depositAmount: amount,
      desiredTenure: _selectedTenure!,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B3A5D),
        ),
      ),
    );
  }
}