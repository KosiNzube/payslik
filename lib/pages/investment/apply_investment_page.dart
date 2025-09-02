import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controller/investment_controller.dart';

class ApplyInvestmentPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double amount;
  final String tenure;
  final String payoutDuration;
  final bool autoRollover;
  final Map<String, dynamic> calculationResult;

  const ApplyInvestmentPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.tenure,
    required this.payoutDuration,
    required this.autoRollover,
    required this.calculationResult,
  }) : super(key: key);

  @override
  State<ApplyInvestmentPage> createState() => _ApplyInvestmentPageState();
}

class _ApplyInvestmentPageState extends State<ApplyInvestmentPage> {
  @override
  Widget build(BuildContext context) {
    final summary = widget.calculationResult['investment_summary'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Investment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Summary Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3A5D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      'Investment Amount',
                      '₦${NumberFormat('#,##0.00').format(widget.amount)}',
                    ),
                    _buildSummaryRow(
                      'Tenure',
                      '${widget.tenure} ${summary['tenure']?.split(' ').last}',
                    ),
                    _buildSummaryRow(
                      'Interest Rate',
                      '${summary['interest_rate']}% P.A.',
                    ),
                    _buildSummaryRow(
                      'Interest Payout',
                      widget.payoutDuration.replaceAll('_', ' ').toUpperCase(),
                    ),
                    _buildSummaryRow(
                      'Auto Rollover',
                      widget.autoRollover ? 'Yes' : 'No',
                    ),
                    _buildSummaryRow(
                      'Total Returns',
                      '₦${NumberFormat('#,##0.00').format(summary['total_payout'])}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<InvestmentController>(
        builder: (context, controller, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: controller.isApplying ? null : () => _submitApplication(controller),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isApplying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirm & Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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

  Future<void> _submitApplication(InvestmentController controller) async {
    final success = await controller.applyForInvestment(
      productId: widget.productId,
      investmentAmount: widget.amount,
      desiredMaturityTenure: widget.tenure,
      preferredInterestPayoutDuration: widget.payoutDuration,
      autoRolloverOnMaturity: widget.autoRollover,
    );

    if (success) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context)..pop()..pop(); // Pop twice to return to product list
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