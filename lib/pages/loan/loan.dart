import 'dart:convert';
import 'dart:ui';  // Add this import for ImageFilter

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/loan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'loan_balance.dart';
import 'loan_calculator_screen.dart'; // adjust import
import 'package:gobeller/utils/routes.dart'; // Add this import at the top

// Ensure this exists

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> with SingleTickerProviderStateMixin {
  String? selectedLoanProduct;
  double? selectedLoanAmount;
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool showLoanForm = false;
  bool showSummary = false;
  double _minAmount = 0.0;
  double _maxAmount = 0.0;
  double _selectedLoanAmount = 0.0;
  List<Map<String, dynamic>> loanBalanceList = [];
  String? errorMessage;
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrimaryColorAndLogo();
      fetchLoanBalance();
      Provider.of<LoanController>(context, listen: false).getEligibleLoanProducts();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
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
          final tertiaryColorHex = data['customized-app-tertiary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;
          _tertiaryColor = tertiaryColorHex != null
              ? Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')))
              : Colors.grey[200];

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }

  Future<void> fetchLoanBalance() async {
    final loanController = Provider.of<LoanController>(context, listen: false);
    final result = await loanController.getLoanBalanceInfo();

    if (mounted) {
      setState(() {
        if (result['success']) {
          final loans = result['data'] as List<dynamic>;
          if (loans.isNotEmpty) {
            loanBalanceList = loans.cast<Map<String, dynamic>>();
            errorMessage = null;
          } else {
            loanBalanceList = [];
            errorMessage = "No loan balance available.";
          }
        } else {
          loanBalanceList = [];
          errorMessage = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoanController>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(),
      body: SafeArea(
        child: controller.isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor ?? Colors.blue),
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildLoanBalanceCard(),
                      const SizedBox(height: 32),
                      _buildLoanProductsHeader(),
                    ],
                  ),
                ),
              ),
              _buildLoanProductsList(controller.loanProducts),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.money,
              color: _primaryColor ?? Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Loan Center",
            style: GoogleFonts.poppins(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.dashboard_rounded,
            color: Colors.grey[700],
            size: 24,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, Routes.dashboard);
          },
          tooltip: 'Go to Dashboard',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (_primaryColor ?? Colors.blue).withOpacity(0.05),
            (_secondaryColor ?? Colors.blue.shade700).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Loans",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Get instant access to flexible loan options tailored for you",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanBalanceCard() {
    final totalOutstanding = loanBalanceList.fold<num>(
      0,
          (sum, loan) => sum + (num.tryParse(loan['repayment_amount_per_cycle'].toString()) ?? 0),
    );

    final totalDisbursed = loanBalanceList.fold<num>(
      0,
          (sum, loan) => sum + (num.tryParse(loan['loan_amount'].toString()) ?? 0),
    );

    final String loanStatus = loanBalanceList.isNotEmpty
        ? (loanBalanceList.first['loan_status']?['label'] ?? 'N/A')
        : 'N/A';

    String formatCurrency(num amount) {
      return "₦${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
      )}";
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (_primaryColor ?? Colors.blue).withOpacity(0.9),
            (_secondaryColor ?? Colors.blue.shade700),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_primaryColor ?? Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Loan Balance",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        loanStatus,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  formatCurrency(totalDisbursed),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Outstanding Balance",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  formatCurrency(totalOutstanding),
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanHistoryPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 20),
                  label: Text(
                    "My Loan",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanProductsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Loans",
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.filter_list,
                color: _primaryColor ?? Colors.blue,
                size: 20,
              ),
              label: Text(
                "Filter",
                style: GoogleFonts.nunito(
                  color: _primaryColor ?? Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Text(
          "Select the best loan option for your needs",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanProductsList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLoanProductCard(products[index]),
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_loans.png', // Add this image to your assets
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            "No Loan Products Available",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new loan offers",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanProductCard(Map<String, dynamic> product) {
    final isSelected = selectedLoanProduct == product['id'];

    String formatAmount(dynamic amount) {
      if (amount == null) return "0";
      final numValue = num.tryParse(amount.toString()) ?? 0;
      return numValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
              (match) => ',');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedLoanProduct = product['id']?.toString();
              _minAmount = double.tryParse(product['min_amount'].toString()) ?? 0.0;
              _maxAmount = double.tryParse(product['max_amount'].toString()) ?? 0.0;
              _selectedLoanAmount = _minAmount;
              _amountController.text = _minAmount.toStringAsFixed(0);
              showSummary = false;
              showLoanForm = false;
            });

            if (selectedLoanProduct != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoanCalculatorPage(
                    productId: selectedLoanProduct!,
                    minAmount: _minAmount,
                    maxAmount: _maxAmount,
                    productName: product['product_name'] ?? 'Unknown Product',
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (_primaryColor ?? Colors.blue)
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_primaryColor ?? Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.wallet,
                        color: _primaryColor ?? Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product_name'] ?? 'Unknown Product',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (product['description'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              product['description'],
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_primaryColor ?? Colors.blue).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: _primaryColor ?? Colors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.money,
                        "Amount Range",
                        "₦${formatAmount(product['min_amount'])} - ₦${formatAmount(product['max_amount'])}",
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.percent,
                        "Interest Rate",
                        "${product['interest_rate_pct']}%",
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.sync,
                        "Interest Type",
                        product['is_interest_rate_reoccuring'] == true
                            ? "Recurring Interest"
                            : "One-time Interest",
                        Colors.purple,
                      ),
                      if (product['allow_internal_loan_rollover'] == true ||
                          product['allow_external_loan_rollover'] == true) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.repeat,
                          "Rollover",
                          (product['allow_internal_loan_rollover'] == true ? "Internal" : "") +
                              (product['allow_external_loan_rollover'] == true ? " & External" : ""),
                          Colors.blue,
                        ),
                      ],
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
}