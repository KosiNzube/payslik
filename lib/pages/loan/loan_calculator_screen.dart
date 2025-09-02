import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/loan_controller.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loan_form.dart';

class LoanCalculatorPage extends StatefulWidget {
  final String productId;
  final double minAmount;
  final double maxAmount;
  final String productName;

  const LoanCalculatorPage({
    super.key,
    required this.productId,
    required this.minAmount,
    required this.maxAmount,
    required this.productName,
  });

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Map<String, dynamic>? repaymentData;
  DateTime? selectedDate;
  late double _selectedAmount;
  bool _isLoading = false;
  String? _amountError;
  bool _isAmountValid = true;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    _selectedAmount = widget.minAmount;
    _amountController.text = _selectedAmount.toStringAsFixed(0);

    // Sync text input changes to slider
    _amountController.addListener(() {
      final text = _amountController.text;
      if (text.isEmpty) {
        setState(() {
          _isAmountValid = false;
          _amountError = null;
        });
        return;
      }

      final value = double.tryParse(text);
      if (value == null) {
        setState(() {
          _amountError = "Invalid number entered.";
          _isAmountValid = false;
        });
        return;
      }

      if (value > widget.maxAmount) {
        setState(() {
          _amountError = "Amount exceeds maximum allowed value.";
          _isAmountValid = false;
        });
      } else if (value < widget.minAmount) {
        setState(() {
          _amountError = "Amount is below minimum allowed value.";
          _isAmountValid = false;
        });
      } else {
        setState(() {
          _selectedAmount = value;
          _amountError = null;
          _isAmountValid = true;
        });
      }
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
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoanController>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.productName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select desired loan amount',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _selectedAmount,
                  min: widget.minAmount,
                  max: widget.maxAmount,
                  divisions: (widget.maxAmount - widget.minAmount).toInt(),
                  label: _selectedAmount.toStringAsFixed(0),
                  onChanged: (value) {
                    setState(() {
                      _selectedAmount = value;
                      _amountController.text = value.toStringAsFixed(0);
                      _amountController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _amountController.text.length),
                      );
                    });
                  },
                ),
                // Amount input field
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Loan Amount',
                    prefixText: '₦',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      if (val != null) {
                        if (val >= widget.minAmount && val <= widget.maxAmount) {
                          setState(() {
                            _selectedAmount = val;
                          });
                        }
                      }
                    }

                ),

                const SizedBox(height: 16),

                // Slider

                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Desired Disbursement date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime today = DateTime.now();
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: today,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isAmountValid)
                        ? null
                        : () async {
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Select a valid repayment date")),
                        );
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      final repaymentDateStr =
                      DateFormat('yyyy-MM-dd').format(selectedDate!);

                      final result = await controller.calculateLoanRepayment(
                        loanProductId: widget.productId,
                        loanAmount: _selectedAmount,
                        repaymentStartDate: repaymentDateStr,
                      );

                      setState(() {
                        _isLoading = false;
                      });

                      if (result['success']) {
                        setState(() {
                          repaymentData = {
                            ...result['data'],
                            'repayment_start_date': repaymentDateStr,
                          };
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
                        );
                      }
                    },

                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Calculate Repayment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),

                if (repaymentData != null) ...[
                  const SizedBox(height: 32),
                  _buildRepaymentSummary(repaymentData!),
                ],

                const SizedBox(height: 24),

                repaymentData == null
                    ? Container()
                    : Container(
                  color: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanFormPage(
                            productId: widget.productId,
                            amount: _selectedAmount,
                            repaymentStartDate: repaymentData!['repayment_start_date'],
                            repaymentData: repaymentData!,
                            productName: widget.productName,
                          ),
                        ),
                      );

                    },
                    child: const Text(
                      'Proceed',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),

                  ),
                ),
                const SizedBox(height: 50),

              ],
            ),
          ),
        ),
      ),


    );
  }

  String formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
    return formatter.format(amount);
  }

  Widget _buildRepaymentSummary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🧾 Loan Repayment Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _summaryRow("Payment Cycle", data["payment_cycle"]?.toString() ?? "N/A"),
        _summaryRow("Duration", "${data["payment_duration"] ?? 'N/A'} months"),
        _summaryRow("Start Date", data["payment_start_date"]?.toString() ?? "N/A"),
        _summaryRow(
            "Actual End Date",
            data["payment_actual_end_date"]?.toString() ?? "N/A"),
        _summaryRow(
            "Extension End Date",
            data["payment_extension_end_date"]?.toString() ?? "N/A"),
        _summaryRow(
            "Principal Amount",
            data["principal_amount"] != null
                ? formatCurrency(data["principal_amount"])
                : "N/A"),
        _summaryRow(
            "Interest",
            data["payment_interest"] != null
                ? formatCurrency(data["payment_interest"])
                : "N/A"),
        _summaryRow(
            "Total Payable",
            data["total_payable_amount"] != null
                ? formatCurrency(data["total_payable_amount"])
                : "N/A"),
        _summaryRow(
            "Recurring Payment",
            data["recursive_payment_amount"] != null
                ? formatCurrency(data["recursive_payment_amount"])
                : "N/A"),
        const SizedBox(height: 20),
        const Text("📅 Payment Schedule",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(height: 10),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: (data['full_payment_schedule'] as List?)?.length ?? 0,
          itemBuilder: (context, index) {
            final payment = data['full_payment_schedule'][index];
            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              title: Text("Payment ${payment['payment_number'] ?? 'N/A'}"),
              subtitle: Text(
                  "Due: ${payment['payment_due_date'] ?? 'N/A'} • ${payment['payment_period'] ?? 'N/A'}"),
              trailing: Text(
                payment['payment_amount'] != null
                    ? formatCurrency(payment['payment_amount'])
                    : "N/A",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
