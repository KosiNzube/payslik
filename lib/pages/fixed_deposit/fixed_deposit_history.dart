import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/fixed_deposit_controller.dart';

class FixedDepositHistoryPage extends StatefulWidget {
  const FixedDepositHistoryPage({Key? key}) : super(key: key);

  @override
  State<FixedDepositHistoryPage> createState() => _FixedDepositHistoryPageState();
}

class _FixedDepositHistoryPageState extends State<FixedDepositHistoryPage> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FixedDepositController>(context, listen: false)
          .getFixedDepositContracts();
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
              : const Color(0xFF667EEA);

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : const Color(0xFF764BA2);

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {
        // Use default colors if there's an error
        setState(() {
          _primaryColor = const Color(0xFF667EEA);
          _secondaryColor = const Color(0xFF764BA2);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title:  Text('Investment History',style:TextStyle(color:Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Consumer<FixedDepositController>(
        builder: (context, controller, child) {
          if (controller.isLoadingContracts) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }
          if (controller.contractsError.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.contractsError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.getFixedDepositContracts(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }
          if (controller.fixedDepositContracts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No investments found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => controller.getFixedDepositContracts(),
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.fixedDepositContracts.length,
              itemBuilder: (context, index) {
                final contract = controller.fixedDepositContracts[index];
                return _buildContractCard(contract);
              },
            ),
          );

        },
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: primaryColor.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header with Reference
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    secondaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract['ref_name'] ?? 'Unknown Product',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ref: ${contract['fixed_deposit_reference']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          contract['status']['label'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Investment Amount',
                    '₦${_formatAmount(contract['deposit_amount'])}',
                  ),
                  _buildDetailRow(
                    'Expected Interest',
                    '₦${_formatAmount(contract['expected_interest_amount'])}',
                  ),
                  _buildDetailRow(
                    'Interest Rate',
                    '${contract['ref_interest_rate']}% P.A.',
                  ),
                  _buildDetailRow(
                    'Interest Earned',
                    '₦${_formatAmount(contract['total_interest_amount_earned'])}',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Start Date',
                    _formatDate(contract['deposit_date']),
                  ),
                  _buildDetailRow(
                    'Maturity Date',
                    _formatDate(contract['maturity_date']),
                  ),
                  if (contract['last_payout_date'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Last Payout',
                      '₦${_formatAmount(contract['last_payout_amount'])}',
                    ),
                    _buildDetailRow(
                      'Payout Date',
                      _formatDate(contract['last_payout_date']),
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Tenure',
                    '${contract['ref_tenure_min_period']} ${_formatTenureType(contract['ref_tenure_type'])}',
                  ),
                  _buildDetailRow(
                    'Principal Returned',
                    contract['is_principal_returned'] ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            value,
            style: const TextStyle(
              color: Color(0xFF1B3A5D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(double.parse(amount.toString()));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  // Add helper method for formatting tenure type
  String _formatTenureType(String? type) {
    if (type == null) return '';
    final formatted = type.replaceAll('_', ' ');
    return '${formatted[0].toUpperCase()}${formatted.substring(1).toLowerCase()}';
  }
}