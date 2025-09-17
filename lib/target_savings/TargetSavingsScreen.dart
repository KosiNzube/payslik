import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/TargetSavingsController.dart';
import 'TargetSavingsDetailsPage.dart';
import 'TargetSavingsHistoryScreen.dart';


class TargetSavingsScreen extends StatefulWidget {
  const TargetSavingsScreen({Key? key}) : super(key: key);

  @override
  State<TargetSavingsScreen> createState() => _TargetSavingsScreenState();
}

class _TargetSavingsScreenState extends State<TargetSavingsScreen> {
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TargetSavingsController>().getProducts();
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
                  'Target Savings',
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
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TargetSavingsHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.rectangle_expand_vertical),
                tooltip: 'Savings History',
              ),
              Consumer<TargetSavingsController>(
                builder: (context, controller, child) {
                  return IconButton(
                    onPressed: () => controller.getProducts(),
                    icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                  );
                },
              ),
            ],
          ),
          Consumer<TargetSavingsController>(
            builder: (context, controller, child) {
              if (controller.isLoadingProducts && controller.products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.productsError.isNotEmpty) {
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
                      controller.productsError,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => controller.getProducts(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ), child:  Text('Try Again'),


                    )
                      ],
                    ),
                  ),
                );
              }

              if (controller.products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No target savings products available'),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = controller.products[index];
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
                                builder: (context) => TargetSavingsDetailsPage(
                                  productId: product['id'],
                                  productName: product['name'] ?? 'Savings Details',
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
                                      'Lock Period',
                                      '${product['lock_min_period']} - ${product['lock_max_period'] ?? '∞'} '+product['saving_recursive_cycle'],
                                      primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoItem(
                                      'Min Target',
                                      '₦${controller.formatCurrency(product['min_target_amount'])}',
                                      const Color(0xFF64748B),
                                    ),
                                    _buildInfoItem(
                                      'Auto Debit',
                                      product['allow_auto_debit'] ? 'Available' : 'Not Available',
                                      const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                                if (product['max_target_amount'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _buildInfoItem(
                                      'Max Target',
                                      '₦${controller.formatCurrency(product['max_target_amount'])}',
                                      const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: controller.products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Removed the floatingActionButton since it should be on the dashboard
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