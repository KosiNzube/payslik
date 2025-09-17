import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/TargetSavingsController.dart';
import 'TargetSavingsCalculatorPage.dart';

class TargetSavingsDetailsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const TargetSavingsDetailsPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<TargetSavingsDetailsPage> createState() => _TargetSavingsDetailsPageState();
}

class _TargetSavingsDetailsPageState extends State<TargetSavingsDetailsPage>
    with SingleTickerProviderStateMixin {
  Color? _primaryColor;
  Color? _secondaryColor;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadThemeColors();
    _fetchProductDetails();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');
    if (settingsJson == null) return;

    try {
      final settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};
      setState(() {
        _primaryColor = _parseColor(data['customized-app-primary-color']);
        _secondaryColor = _parseColor(data['customized-app-secondary-color']);
      });
    } catch (_) {}
  }

  Color? _parseColor(String? hexColor) {
    return hexColor != null
        ? Color(int.parse(hexColor.replaceAll('#', '0xFF')))
        : null;
  }

  void _fetchProductDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TargetSavingsController>().getProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _primaryColor ?? theme.primaryColor;
    final secondaryColor = _secondaryColor ?? theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(primaryColor, secondaryColor),
      body: Consumer<TargetSavingsController>(
        builder: (context, controller, _) {
          if (controller.isLoadingProductDetails) {
            return _buildLoadingState(primaryColor);
          }

          if (controller.productDetailsError.isNotEmpty) {
            return _buildErrorState(controller, primaryColor);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(controller, primaryColor, secondaryColor),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, Color secondaryColor) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        widget.productName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading product details...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TargetSavingsController controller, Color primaryColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.productDetailsError,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => controller.getProductDetails(widget.productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      TargetSavingsController controller,
      Color primaryColor,
      Color secondaryColor,
      ) {
    final product = controller.productDetails;
    if (product == null) {
      return const Center(
        child: Text(
          'No product details available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildProductHeader(product, primaryColor, secondaryColor),
                const SizedBox(height: 24),
                _buildSavingsDetails(product, controller, primaryColor),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
        _buildStartSavingButton(product, primaryColor, secondaryColor),
      ],
    );
  }

  Widget _buildProductHeader(
      Map<String, dynamic> product,
      Color primaryColor,
      Color secondaryColor,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.savings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? widget.productName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target Savings Plan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product['interest_rate']}% P.A.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }

  Widget _buildSavingsDetails(
      Map<String, dynamic> product,
      TargetSavingsController controller,
      Color primaryColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDetailSection(
            title: 'Basic Information',
            icon: Icons.info_outline,
            color: primaryColor,
            children: [
              _buildDetailRow('Product Code', product['code']),
              _buildDetailRow('Description', product['description']),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            title: 'Savings Terms',
            icon: Icons.account_balance_wallet,
            color: primaryColor,
            children: [
              _buildDetailRow(
                'Minimum Target',
                '₦${controller.formatCurrency(product['min_target_amount'])}',
              ),
              _buildDetailRow(
                'Maximum Target',
                product['max_target_amount'] != null
                    ? '₦${controller.formatCurrency(product['max_target_amount'])}'
                    : 'No limit',
              ),
              _buildDetailRow(
                'Lock Period',
                '${product['lock_min_period']} - ${product['lock_max_period'] ?? '∞'} '+product['saving_recursive_cycle'],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            title: 'Product Features',
            icon: Icons.star_outline,
            color: primaryColor,
            children: [
              _buildDetailRow(
                'Auto Debit',
                product['allow_auto_debit'] ? 'Available' : 'Not Available',
                isEnabled: product['allow_auto_debit'],
              ),
              _buildDetailRow(
                'Recurring Cycle',
                product['saving_recursive_cycle']?.toString().toUpperCase() ?? 'N/A',
              ),
              _buildDetailRow(
                'Early Withdrawal',
                product['allow_early_withdrawal'] ? 'Allowed' : 'Not Allowed',
                isEnabled: product['allow_early_withdrawal'],
              ),
            ],
          ),
          if (product['allow_early_withdrawal']) ...[
            const SizedBox(height: 16),
            _buildDetailSection(
              title: 'Withdrawal Penalty',
              icon: Icons.warning_amber,
              color: Colors.orange.shade600,
              children: [
                _buildDetailRow(
                  'Penalty Type',
                  product['early_withdrawal_penalty_type']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Penalty Amount',
                  product['early_withdrawal_penalty_type'] == 'percentage'
                      ? '${product['early_withdrawal_penalty_value']}%'
                      : '₦${controller.formatCurrency(product['early_withdrawal_penalty_value'])}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool? isEnabled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEnabled != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnabled ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: isEnabled ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          value ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: Text(
                      value ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSavingButton(
      Map<String, dynamic> product,
      Color primaryColor,
      Color secondaryColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TargetSavingsCalculatorPage(
                    productId: product['id'],
                    productName: product['name'] ?? widget.productName,
                    product: product,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'START SAVING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}