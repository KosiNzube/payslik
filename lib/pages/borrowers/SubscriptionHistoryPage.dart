import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/property_controller.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  final String propertyId;

  const SubscriptionHistoryPage({super.key, required this.propertyId});

  @override
  State<SubscriptionHistoryPage> createState() => _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  Map<String, dynamic>? subscriptionDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatAmount(String amount, String? symbol) {
    final currencySymbol = symbol ?? '₦';
    final formattedAmount = NumberFormat('#,##0.00').format(double.parse(amount));
    return '$currencySymbol$formattedAmount';
  }

  String _formatPaymentOption(String option) {
    return option.split('-').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _loadSubscriptionDetails() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    
    // First, get all subscriptions to find the one for this property
    final allSubscriptions = await controller.fetchAllPropertySubscriptions();
    
    // Find the subscription for this property
    final propertySubscription = allSubscriptions.firstWhere(
      (sub) => sub['property_id'] == widget.propertyId,
      orElse: () => {},
    );

    if (propertySubscription.isEmpty) {
      setState(() {
        errorMessage = "No subscription found for this property.";
        isLoading = false;
      });
      return;
    }

    // Now fetch the detailed subscription info
    final result = await controller.fetchPropertySubscriptionHistory(propertySubscription['id']);

    setState(() {
      if (result != null) {
        subscriptionDetails = result;
        errorMessage = null;
      } else {
        errorMessage = "Failed to load subscription details.";
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptionDetails,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubscriptionDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                          (subscriptionDetails?['status']?['color'] ?? '#dc3545')
                                              .replaceAll('#', '0xFF'),
                                        )),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        subscriptionDetails?['status']?['label'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Created on ${_formatDate(subscriptionDetails?['created_at'])}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subscriptionDetails?['name_referenced'] ?? 'Unknown Property',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${subscriptionDetails?['quantity']} ${subscriptionDetails?['uom']}',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Financial Details Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Financial Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Expected Amount',
                                  _formatAmount(
                                    subscriptionDetails?['expected_amount'] ?? '0',
                                    subscriptionDetails?['currency']?['symbol'],
                                  ),
                                ),
                                _buildInfoRow(
                                  'Paid Amount',
                                  _formatAmount(
                                    subscriptionDetails?['paid_amount'] ?? '0',
                                    subscriptionDetails?['currency']?['symbol'],
                                  ),
                                ),
                                _buildInfoRow(
                                  'Balance',
                                  _formatAmount(
                                    subscriptionDetails?['balance_amount'] ?? '0',
                                    subscriptionDetails?['currency']?['symbol'],
                                  ),
                                ),
                                _buildInfoRow(
                                  'Interest Rate',
                                  '${subscriptionDetails?['interest_referenced'] ?? '0'}%',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment Details Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Payment Method',
                                  _formatPaymentOption(
                                    subscriptionDetails?['preferred_payment_option'] ?? '',
                                  ),
                                ),
                                _buildInfoRow(
                                  'Payment Cycle',
                                  (subscriptionDetails?['payment_cycle_referenced'] ?? '')
                                      .toString()
                                      .toUpperCase(),
                                ),
                                _buildInfoRow(
                                  'Start Date',
                                  _formatDate(subscriptionDetails?['start_date']),
                                ),
                                _buildInfoRow(
                                  'Next Payment',
                                  _formatDate(subscriptionDetails?['next_payment_date']),
                                ),
                                _buildInfoRow(
                                  'End Date',
                                  _formatDate(subscriptionDetails?['actual_end_date']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

