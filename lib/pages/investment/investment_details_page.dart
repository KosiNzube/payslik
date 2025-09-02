import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/investment_controller.dart';
import 'investment_calculator_page.dart';

class InvestmentDetailsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const InvestmentDetailsPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<InvestmentDetailsPage> createState() => _InvestmentDetailsPageState();
}

class _InvestmentDetailsPageState extends State<InvestmentDetailsPage> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestmentController>().getProductDetails(widget.productId);
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
    final primaryColor = _primaryColor ?? Colors.blue;
    final secondaryColor = _secondaryColor ?? Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
      ),
      body: Consumer<InvestmentController>(
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
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.detailsError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.getProductDetails(widget.productId),
                    style: ElevatedButton.styleFrom(
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

          final details = controller.productDetails;
          if (details == null) {
            return const Center(
              child: Text('No details available'),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[100]!,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Header Card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details['name'] ?? widget.productName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${details['interest_rate']}% P.A.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Update the sections with enhanced styling
                        ...buildEnhancedSections(details, controller, primaryColor),
                      ],
                    ),
                  ),
                ),
                // Enhanced Invest Now Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: details['id'] != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvestmentCalculatorPage(
                                    productId: details['id'],
                                    productName: details['name'] ?? widget.productName,
                                    product: details,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Invest Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

  // Add this helper method
  List<Widget> buildEnhancedSections(
    Map<String, dynamic> details,
    InvestmentController controller,
    Color primaryColor,
  ) {
    return [
      _buildEnhancedSection(
        'Basic Information',
        [
          _buildEnhancedDetailRow('Name', details['name'], primaryColor),
          _buildEnhancedDetailRow('Code', details['code'], primaryColor),
          _buildEnhancedDetailRow(
            'Risk Level',
            details['risk_level']?.toUpperCase(),
            primaryColor,
          ),
          _buildEnhancedDetailRow('Description', details['description'], primaryColor),
        ],
        primaryColor,
        Icons.info_outline_rounded,
      ),
      _buildEnhancedSection(
        'Investment Terms',
        [
          _buildEnhancedDetailRow('Interest Rate', '${details['interest_rate']}% P.A.', primaryColor),
          _buildEnhancedDetailRow(
            'Investment Range',
            '₦${controller.formatCurrency(details['min_investment_amount'])} - ₦${controller.formatCurrency(details['max_investment_amount'])}',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Tenure',
            '${details['tenure_min_period']} - ${details['tenure_max_period']} ${controller.getTenureTypeDisplay(details['tenure_type'])}',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Interest Payout',
            details['interest_payout']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A',
            primaryColor,
          ),
        ],
        primaryColor,
        Icons.access_time_rounded,
      ),
      _buildEnhancedSection(
        'Features',
        [
          _buildEnhancedDetailRow(
            'Recurring Interest',
            details['is_reoccuring_interest'] ? 'Yes' : 'No',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Compound Interest',
            details['is_interest_compounded'] ? 'Yes' : 'No',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Auto Rollover',
            details['auto_rollover_on_maturity'] ? 'Yes' : 'No',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Maturity Notification',
            details['send_maturity_notification'] ? 'Yes' : 'No',
            primaryColor,
          ),
        ],
        primaryColor,
        Icons.star_outline_rounded,
      ),
      if (details['allow_early_exit']) _buildEnhancedSection(
        'Early Exit Terms',
        [
          _buildEnhancedDetailRow('Early Exit Allowed', 'Yes', primaryColor),
          _buildEnhancedDetailRow(
            'Penalty Type',
            details['early_exit_penalty_type']?.toString().toUpperCase() ?? 'N/A',
            primaryColor,
          ),
          _buildEnhancedDetailRow(
            'Penalty Value',
            '${details['early_exit_penalty_value']}%',
            primaryColor,
          ),
        ],
        primaryColor,
        Icons.exit_to_app_rounded,
      ),
    ];
  }

  // Update the section building method
  Widget _buildEnhancedSection(
    String title,
    List<Widget> children,
    Color primaryColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          ...children,
        ],
      ),
    );
  }

  // Update the detail row building method
  Widget _buildEnhancedDetailRow(String label, String? value, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}