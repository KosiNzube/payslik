import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/fixed_deposit_controller.dart';
import '../../models/interest_payout_duration.dart';

class FixedDepositContractPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double depositAmount;
  final int tenure;
  final Map<String, dynamic> calculationResult;

  const FixedDepositContractPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.depositAmount,
    required this.tenure,
    required this.calculationResult,
  }) : super(key: key);

  @override
  State<FixedDepositContractPage> createState() => _FixedDepositContractPageState();
}

class _FixedDepositContractPageState extends State<FixedDepositContractPage> {
  InterestPayoutDuration _selectedPayout = InterestPayoutDuration.on_maturity;
  bool _autoRollover = true;

  // Add color variables
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  String _formatAmount(num amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A5D),
        elevation: 0,
        title: const Text('Create Investment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildOptionsCard(),
            const SizedBox(height: 24),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final terms = widget.calculationResult['product_terms'];
    final summary = widget.calculationResult['amount_summary'];
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Container(
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
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${terms['tenure_periods']} ${terms['tenure_unit']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Summary Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Investment Amount',
                  '₦${_formatAmount(summary['principal'])}',
                  const Color(0xFF059669),
                ),
                _buildSummaryRow(
                  'Interest Rate',
                  '${terms['interest_rate']}% P.A.',
                  const Color(0xFF667EEA),
                ),
                _buildSummaryRow(
                  'Total Return',
                  '₦${_formatAmount(summary['final_amount_on_maturity'])}',
                  const Color(0xFF7C3AED),
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: isHighlighted ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3A5D),
            ),
          ),
          const SizedBox(height: 20),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF667EEA).withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            child: DropdownButtonFormField<InterestPayoutDuration>(
              value: _selectedPayout,
              decoration: const InputDecoration(
                labelText: 'Interest Payout',
                labelStyle: TextStyle(fontSize: 14),
              ),
              items: InterestPayoutDuration.values.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(
                    duration.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPayout = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.2),
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text(
                'Auto Rollover',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B3A5D),
                ),
              ),
              subtitle: Text(
                'Automatically renew investment on maturity',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: _autoRollover,
              activeColor: const Color(0xFF667EEA),
              onChanged: (value) {
                setState(() {
                  _autoRollover = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final primaryColor = _primaryColor ?? const Color(0xFF667EEA);
    final secondaryColor = _secondaryColor ?? const Color(0xFF764BA2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Consumer<FixedDepositController>(
        builder: (context, controller, child) {
          return ElevatedButton(
            onPressed: controller.isCreatingContract ? null : () => _createContract(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isCreatingContract
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Investment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _createContract(FixedDepositController controller) async {
    final success = await controller.createFixedDepositContract(
      productId: widget.productId,
      depositAmount: widget.depositAmount,
      desiredTenure: widget.tenure,
      preferredPayout: _selectedPayout,
      autoRollover: _autoRollover,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to success page or show success dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.contractError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}