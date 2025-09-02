import 'package:flutter/material.dart';
import 'package:gobeller/controller/property_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PropertyHistoryPage extends StatefulWidget {
  const PropertyHistoryPage({Key? key}) : super(key: key);

  @override
  _PropertyHistoryPageState createState() => _PropertyHistoryPageState();
}

class _PropertyHistoryPageState extends State<PropertyHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<PropertyController>(context, listen: false);
    final subscriptions = await controller.fetchAllPropertySubscriptions();
    
    if (mounted) {
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No subscription history found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubscriptions,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final subscription = _subscriptions[index];
                      final status = subscription['status']?['label'] ?? 'Unknown';
                      final statusColor = subscription['status']?['color'] ?? '#dc3545';
                      final currency = subscription['currency'];
                      final property = subscription['property'];
                      
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: ExpansionTile(
                          title: Text(
                            subscription['name_referenced'] ?? 'Unknown Property',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(statusColor.replaceAll('#', '0xFF'))),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(subscription['created_at']),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${subscription['quantity']} ${subscription['uom']}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    'Expected Amount',
                                    _formatAmount(
                                      subscription['expected_amount'],
                                      currency?['symbol'],
                                    ),
                                  ),
                                  _buildInfoRow(
                                    'Paid Amount',
                                    _formatAmount(
                                      subscription['paid_amount'],
                                      currency?['symbol'],
                                    ),
                                  ),
                                  _buildInfoRow(
                                    'Balance',
                                    _formatAmount(
                                      subscription['balance_amount'],
                                      currency?['symbol'],
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    'Payment Method',
                                    _formatPaymentOption(subscription['preferred_payment_option']),
                                  ),
                                  _buildInfoRow(
                                    'Payment Cycle',
                                    (subscription['payment_cycle_referenced'] ?? '').toString().toUpperCase(),
                                  ),
                                  _buildInfoRow(
                                    'Interest Rate',
                                    '${subscription['interest_referenced']}%',
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    'Start Date',
                                    _formatDate(subscription['start_date']),
                                  ),
                                  _buildInfoRow(
                                    'Next Payment',
                                    _formatDate(subscription['next_payment_date']),
                                  ),
                                  _buildInfoRow(
                                    'End Date',
                                    _formatDate(subscription['actual_end_date']),
                                  ),
                                  if (property != null) ...[
                                    const Divider(height: 24),
                                    _buildInfoRow(
                                      'Category',
                                      property['property_category']?['label'] ?? 'N/A',
                                    ),
                                    if (property['description'] != null)
                                      _buildInfoRow(
                                        'Description',
                                        property['description'],
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
} 