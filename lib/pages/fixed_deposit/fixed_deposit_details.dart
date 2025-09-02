import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controller/fixed_deposit_controller.dart';
import 'fixed_deposit_calculator.dart';

class FixedDepositDetailsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const FixedDepositDetailsPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<FixedDepositDetailsPage> createState() => _FixedDepositDetailsPageState();
}

class _FixedDepositDetailsPageState extends State<FixedDepositDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FixedDepositController>(context, listen: false)
          .getProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A5D),
        elevation: 0,
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<FixedDepositController>(
        builder: (context, controller, child) {
          if (controller.isLoadingDetails) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.detailsError.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    controller.detailsError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.getProductDetails(widget.productId),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final product = controller.selectedProduct;
          if (product == null) {
            return const Center(child: Text('No product details available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Product Details'),
                _buildDetailCard(
                  title: 'Product Information',
                  content: [
                    _buildDetailRow('Name', product['name'] ?? 'N/A'),
                    _buildDetailRow('Code', product['code'] ?? 'N/A'),
                    _buildDetailRow('Status', product['status']?['label'] ?? 'N/A'),
                    if (product['description'] != null)
                      _buildDetailRow('Description', product['description']),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Investment Terms'),
                _buildDetailCard(
                  title: 'Interest Details',
                  content: [
                    _buildDetailRow('Interest Rate', '${product['interest_rate']}% P.A.'),
                    _buildDetailRow(
                        'Interest Payout',
                        _formatDisplayText(product['interest_payout'] ?? 'on_maturity')
                    ),
                    _buildDetailRow(
                        'Compound Interest',
                        product['is_interest_compounded'] == true ? 'Yes' : 'No'
                    ),
                    _buildDetailRow(
                        'Recurring Interest',
                        product['is_reoccuring_interest'] == true ? 'Yes' : 'No'
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailCard(
                  title: 'Amount & Tenure',
                  content: [
                    _buildDetailRow('Minimum Amount', '₦${_formatAmount(product['min_amount'])}'),
                    _buildDetailRow(
                        'Maximum Amount',
                        product['max_amount'] != null
                            ? '₦${_formatAmount(product['max_amount'])}'
                            : 'No Limit'
                    ),
                    _buildDetailRow(
                        'Tenure Type',
                        _formatDisplayText(product['tenure_type'] ?? '')
                    ),
                    _buildDetailRow(
                        'Minimum Period',
                        '${product['tenure_min_period'] ?? 0} ${product['tenure_type'] ?? 'days'}'
                    ),
                    _buildDetailRow(
                        'Maximum Period',
                        product['tenure_max_period'] != null
                            ? '${product['tenure_max_period']} ${product['tenure_type']}'
                            : 'No Limit'
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailCard(
                  title: 'Fees & Charges',
                  content: [
                    _buildDetailRow(
                        'Management Fee',
                        '${product['management_fee_amount'] ?? '0.00'} ' +
                            '(${_formatDisplayText(product['management_fee_type'] ?? 'flat')})'
                    ),
                    _buildDetailRow(
                        'Processing Fee',
                        '${product['processing_fee_amount'] ?? '0.00'} ' +
                            '(${_formatDisplayText(product['processing_fee_type'] ?? 'flat')})'
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailCard(
                  title: 'Additional Features',
                  content: [
                    _buildDetailRow(
                        'KYC Required',
                        product['is_kyc_required'] == true ? 'Yes' : 'No'
                    ),
                    _buildDetailRow(
                        'Auto Rollover',
                        product['auto_rollover_on_maturity'] == true ? 'Yes' : 'No'
                    ),
                    _buildDetailRow(
                        'Maturity Notification',
                        product['send_maturity_notification'] == true ? 'Yes' : 'No'
                    ),
                    _buildDetailRow(
                        'Premature Withdrawal',
                        product['allow_premature_withdrawal'] == true ? 'Allowed' : 'Not Allowed'
                    ),
                    if (product['allow_premature_withdrawal'] == true) ...[
                      _buildDetailRow(
                          'Withdrawal Penalty',
                          '${product['premature_withdrawal_penalty_value'] ?? '0.00'} ' +
                              '(${_formatDisplayText(product['premature_withdrawal_penalty_type'] ?? 'none')})'
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FixedDepositCalculatorPage(
                              productId: widget.productId,
                              productName: widget.productName,
                            ),
                          ),
                        );
                      },
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
                        children: [
                          const Icon(Icons.calculate_rounded, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Calculate & Invest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section with Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(children: content),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B3A5D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    double value = double.tryParse(amount.toString()) ?? 0.0;
    final format = NumberFormat("#,##0.00", "en_US");
    return format.format(value);
  }

  // Helper method to format display text
  String _formatDisplayText(String text) {
    if (text.isEmpty) return text;
    return text
        .split('_')
        .map((word) => word.isNotEmpty
        ? "${word[0].toUpperCase()}${word.substring(1)}"
        : word)
        .join(' ');
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String titleCase() {
    return split('_')
        .map((word) => word.capitalize())
        .join(' ');
  }
}