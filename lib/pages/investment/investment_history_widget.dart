import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/investment_controller.dart';

class InvestmentHistoryScreen extends StatefulWidget {
  const InvestmentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentHistoryScreen> createState() => _InvestmentHistoryScreenState();
}

class _InvestmentHistoryScreenState extends State<InvestmentHistoryScreen> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvestmentController>(context, listen: false)
          .getInvestmentHistory();
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
          'Investment History',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<InvestmentController>(
        builder: (context, controller, child) {
          if (controller.isLoadingHistory && controller.investmentHistory.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (controller.historyError.isNotEmpty) {
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
                    controller.historyError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.getInvestmentHistory(),
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

          if (controller.investmentHistory.isEmpty) {
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
            onRefresh: () => controller.getInvestmentHistory(),
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.investmentHistory.length,
              itemBuilder: (context, index) {
                final investment = controller.investmentHistory[index];
                return _buildInvestmentCard(investment);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);
    final metadata = _parseMetadata(investment['product_metadata']);

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
                              investment['ref_name'] ?? 'Unknown Product',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ref: ${investment['investment_reference'] ?? 'N/A'}',
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
                              investment['status']?['slug']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          investment['status']?['label'] ?? 'Unknown',
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
                    'Investment Amount',
                    '₦${_formatAmount(investment['invested_amount'])}',
                  ),
                  if (metadata != null) ...[
                    _buildDetailRow(
                      'Expected Interest',
                      '₦${_formatAmount(metadata['total_interest'])}',
                    ),
                    _buildDetailRow(
                      'Total Payout',
                      '₦${_formatAmount(metadata['total_payout'])}',
                    ),
                  ],
                  _buildDetailRow(
                    'Interest Rate',
                    '${investment['ref_interest_rate'] ?? 'N/A'}% P.A.',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Start Date',
                    _formatDate(investment['start_date']),
                  ),
                  _buildDetailRow(
                    'Maturity Date',
                    _formatDate(investment['maturity_date']),
                  ),
                  if (investment['last_payout_date'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Last Payout',
                      '₦${_formatAmount(investment['last_payout_amount'])}',
                    ),
                    _buildDetailRow(
                      'Payout Date',
                      _formatDate(investment['last_payout_date']),
                    ),
                  ],
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

  Map<String, dynamic>? _parseMetadata(String? metadataStr) {
    if (metadataStr == null) return null;
    try {
      final decoded = json.decode(metadataStr);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('investment_summary')) {
        return Map<String, dynamic>.from(decoded['investment_summary']);
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing metadata: $e');
      return null;
    }
  }

  Color _getStatusBackgroundColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}