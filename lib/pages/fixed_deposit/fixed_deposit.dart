import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/fixed_deposit_controller.dart';
import 'fixed_deposit_details.dart';
import 'fixed_deposit_history.dart'; // Import the history page

class FixedDepositScreen extends StatefulWidget {
  const FixedDepositScreen({Key? key}) : super(key: key);

  @override
  State<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends State<FixedDepositScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;



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
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Fetch products when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FixedDepositController>(context, listen: false)
          .getFixedDepositProducts();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor ?? const Color(0xFF667EEA),
                    _secondaryColor ?? const Color(0xFF764BA2),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text(
                  'Fixed Deposits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor ?? const Color(0xFF667EEA),
                        _secondaryColor ?? const Color(0xFF764BA2),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Floating shapes for visual interest
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 30,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // History Button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FixedDepositHistoryPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              // Existing refresh button
              Consumer<FixedDepositController>(
                builder: (context, controller, child) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: controller.isLoading
                          ? Container(
                        key: const ValueKey('loading'),
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : IconButton(
                        key: const ValueKey('refresh'),
                        onPressed: () => controller.refreshProducts(),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  );
                },
              )
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Consumer<FixedDepositController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.fixedDepositProducts.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (controller.errorMessage.isNotEmpty) {
                      return _buildErrorState(controller);
                    }

                    if (controller.fixedDepositProducts.isEmpty) {
                      return _buildEmptyState(controller);
                    }

                    return _buildProductsList(controller);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF667EEA),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading fixed deposit products...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(FixedDepositController controller) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => controller.getFixedDepositProducts(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FixedDepositController controller) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 48,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Products Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No fixed deposit products found at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => controller.getFixedDepositProducts(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(FixedDepositController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshProducts(),
      color: const Color(0xFF667EEA),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        itemCount: controller.fixedDepositProducts.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 100)),
            curve: Curves.easeOutCubic,
            child: _buildProductCard(controller.fixedDepositProducts[index], context, index),
          );
        },
      ),
    ); // <-- Properly closes RefreshIndicator
  }


  Widget _buildProductCard(Map<String, dynamic> product, BuildContext context, int index) {
    final status = product['status'];
    final isActive = status?['slug'] == 'active';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FixedDepositDetailsPage(
                    productId: product['id'],
                    productName: product['name'] ?? 'Product Details',
                  ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Code: ${product['code'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
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
                          color: isActive
                              ? const Color(0xFF10B981).withOpacity(0.9)
                              : const Color(0xFFEF4444).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status?['label'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Compact Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Increased vertical padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Interest Rate
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${product['interest_rate']}% P.A.',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount Range
                          Expanded(
                            flex: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: _buildCompactAmountCard(
                                    'Min: ₦${_formatAmount(product['min_amount'])}',
                                    const Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: _buildCompactAmountCard(
                                    product['max_amount'] != null
                                        ? 'Max: ₦${_formatAmount(product['max_amount'])}'
                                        : 'No Limit',
                                    const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Increased spacing
                      // Highlighted Tenure Information
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF667EEA).withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: const Color(0xFF667EEA).withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${product['tenure_min_period'] ?? '0'}-${product['tenure_max_period'] ?? 'No Limit'} ' +
                              _getTenureUnit(product['tenure_type']),
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF667EEA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAmountCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reduced horizontal padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: FittedBox( // Added to ensure text fits
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10, // Reduced from 11
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    double value = double.tryParse(amount.toString()) ?? 0.0;

    final format = NumberFormat("#,##0.00", "en_US");
    return format.format(value);
  }

  String _getTenureUnit(dynamic tenureType) {
    switch (tenureType?.toString().toLowerCase()) {
      case 'daily':
        return 'days';
      case 'monthly':
        return 'months';
      case 'yearly':
        return 'years';
      default:
        return 'days';
    }
  }
}