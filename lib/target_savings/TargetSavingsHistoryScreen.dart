import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/TargetSavingsController.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TargetSavingsHistoryScreen extends StatefulWidget {
  const TargetSavingsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TargetSavingsHistoryScreen> createState() => _TargetSavingsHistoryScreenState();
}

class _TargetSavingsHistoryScreenState extends State<TargetSavingsHistoryScreen> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TargetSavingsController>(context, listen: false)
          .getContracts();
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
        setState(() {
          _primaryColor = const Color(0xFF667EEA);
          _secondaryColor = const Color(0xFF764BA2);
        });
      }
    } else {
      setState(() {
        _primaryColor = const Color(0xFF667EEA);
        _secondaryColor = const Color(0xFF764BA2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Target Savings History',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<TargetSavingsController>(
        builder: (context, controller, child) {
          if (controller.isLoadingContracts && controller.contracts.isEmpty) {
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
                    onPressed: () => controller.getContracts(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
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

          if (controller.contracts.isEmpty) {
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
                    'No target savings found',
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
            onRefresh: () => controller.getContracts(),
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.contracts.length,
              itemBuilder: (context, index) {
                final contract = controller.contracts[index];
                return _buildSavingsCard(contract);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavingsCard(Map<String, dynamic> contract) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    // Determine funding source
    final savingSourceChannel = contract['saving_source_channel'] ?? '';
    final isWalletFunding = savingSourceChannel == 'wallet';
    final isBankTransfer = savingSourceChannel == 'bank-transfer';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract['ref_name'] ?? 'Target Savings',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ref: ${contract['target_saving_reference'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(
                              contract['status']?['slug']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          contract['status']?['label'] ?? 'Unknown',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Target Amount',
                    '₦${_formatAmount(contract['target_amount'])}',
                  ),
                  _buildDetailRow(
                    'Amount Saved',
                    '₦${_formatAmount(contract['total_saved_amount'])}',
                  ),
                  _buildDetailRow(
                    'Interest Rate',
                    '${contract['ref_interest_rate'] ?? 'N/A'}% P.A.',
                  ),
                  _buildDetailRow(
                    'Interest Payout',
                    '${contract['ref_interest_payout'] ?? 'N/A'}',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Saving Cycle',
                    '${contract['ref_saving_recursive_cycle'] ?? 'N/A'}',
                  ),

                  // Conditional rendering based on funding source
                  if (isBankTransfer) ...[
                    _buildDetailRow(
                      'Funding Source',
                      'Bank Transfer',
                    ),
                    _buildDetailRow(
                      'Bank Account',
                      '${contract['bank_account_name'] ?? 'N/A'}',
                    ),
                    _buildDetailRow(
                      'Account Number',
                      '${contract['bank_account_number'] ?? 'N/A'}',
                    ),
                  ] else if (isWalletFunding) ...[
                    _buildDetailRow(
                      'Funding Source',
                      'Wallet',
                    ),
                    _buildDetailRow(
                      'Account Number',
                      '${contract['bank_account_number'] ?? 'N/A'}',
                    ),
                  ] else ...[
                    _buildDetailRow(
                      'Funding Source',
                      savingSourceChannel.toUpperCase(),
                    ),
                  ],

                  // Show dates if available
                  if (contract['saving_start_date'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Start Date',
                      _formatDate(contract['saving_start_date']),
                    ),
                  ],
                  if (contract['saving_maturity_date'] != null) ...[
                    _buildDetailRow(
                      'Maturity Date',
                      _formatDate(contract['saving_maturity_date']),
                    ),
                  ],
                  if (contract['most_recent_saving_date'] != null) ...[
                    _buildDetailRow(
                      'Last Saving Date',
                      _formatDate(contract['most_recent_saving_date']),
                    ),
                  ],
                  if (contract['next_saving_date'] != null) ...[
                    _buildDetailRow(
                      'Next Saving Date',
                      _formatDate(contract['next_saving_date']),
                    ),
                  ],

                  // Show interest information
                  if (contract['expected_interest_amount'] != null &&
                      contract['expected_interest_amount'] != '0.00') ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Expected Interest',
                      '₦${_formatAmount(contract['expected_interest_amount'])}',
                    ),
                  ],
                  if (contract['total_interest_earned'] != null &&
                      contract['total_interest_earned'] != '0.00000000') ...[
                    _buildDetailRow(
                      'Interest Earned',
                      '₦${_formatAmount(contract['total_interest_earned'])}',
                    ),
                  ],

                  // Show saving range
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Min Target Amount',
                    '₦${_formatAmount(contract['ref_min_target_amount'])}',
                  ),
                  _buildDetailRow(
                    'Max Target Amount',
                    '₦${_formatAmount(contract['ref_max_target_amount'])}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Color _getStatusBackgroundColor(String? statusSlug) {
    switch (statusSlug?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'completed':
        return const Color(0xFF2196F3); // Blue
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1B3A5D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    try {
      final formatter = NumberFormat("#,##0.00", "en_US");
      return formatter.format(double.parse(amount.toString()));
    } catch (e) {
      return '0.00';
    }
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

}