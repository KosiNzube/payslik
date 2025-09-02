import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/investment_controller.dart';
import 'investment_details_page.dart'; // Import the InvestmentDetailsPage
import 'investment_history_widget.dart'; // Import the InvestmentHistoryScreen

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestmentController>().getInvestmentProducts();
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
  Widget build(BuildContext context) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text(
                  'Investments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Add this IconButton before the refresh button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvestmentHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                tooltip: 'Investment History',
              ),
              Consumer<InvestmentController>(
                builder: (context, controller, child) {
                  return IconButton(
                    onPressed: controller.refreshProducts,
                    icon: const Icon(Icons.refresh),
                  );
                },
              ),
            ],
          ),
          Consumer<InvestmentController>(
            builder: (context, controller, child) {
              if (controller.isLoading && controller.investmentProducts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.errorMessage.isNotEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                          controller.errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: controller.refreshProducts,
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
                  ),
                );
              }

              if (controller.investmentProducts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No investment products available'),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = controller.investmentProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvestmentDetailsPage(
                                  productId: product['id'],
                                  productName: product['name'] ?? 'Investment Details',
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'] ?? 'Unknown Product',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B3A5D),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            (product['status']?['color'] ?? '#28a745')
                                                .replaceAll('#', '0xFF'),
                                          ),
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        product['code'] ?? '',
                                        style: TextStyle(
                                          color: Color(
                                            int.parse(
                                              (product['status']?['color'] ?? '#28a745')
                                                  .replaceAll('#', '0xFF'),
                                            ),
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoItem(
                                      'Interest Rate',
                                      '${product['interest_rate']}% P.A.',
                                      primaryColor,
                                    ),
                                    _buildInfoItem(
                                      'Tenure',
                                      '${product['tenure_min_period']} - ${product['tenure_max_period']} ${controller.getTenureTypeDisplay(product['tenure_type'])}',
                                      primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoItem(
                                      'Min Amount',
                                      '₦${controller.formatCurrency(product['min_investment_amount'])}',
                                      const Color(0xFF64748B),
                                    ),
                                    _buildInfoItem(
                                      'Risk Level',
                                      product['risk_level']?.toString().toUpperCase() ?? 'N/A',
                                      const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: controller.investmentProducts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}