import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gobeller/controller/loan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoanHistoryPage extends StatefulWidget {
  const LoanHistoryPage({super.key});

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> loanBalanceList = [];
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;

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
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          loanBalanceList = loans.cast<Map<String, dynamic>>();
          errorMessage = loanBalanceList.isEmpty ? "No loan history available." : null;
        } else {
          loanBalanceList = [];
          errorMessage = result['message'];
        }
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    final num value = num.tryParse(amount.toString()) ?? 0;
    return "₦${NumberFormat('#,##0').format(value)}";
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanController = Provider.of<LoanController>(context);

    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Loan History",
          style: GoogleFonts.poppins(
            color: _primaryColor ?? Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loanController.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor ?? Colors.blue),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Loan History",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Track all your loan activities",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loanBalanceList.isNotEmpty
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: loanBalanceList.length,
                              itemBuilder: (context, index) {
                                final loan = loanBalanceList[index];
                                return _buildLoanCard(loan, index);
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_2_circlepath,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage ?? "No loan history found",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Apply for a loan to get started",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
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

  Widget _buildLoanCard(Map<String, dynamic> loan, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_primaryColor ?? Colors.blue).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wallet,
                            color: _primaryColor ?? Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                            "Loan ID: ${loan['application_number'] ?? 'N/A'}",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Applied on ${_formatDate(loan['created_at'])}",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(loan['loan_status']),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          "Amount Disbursed",
                          _formatCurrency(loan['loan_amount']),
                          Icons.payments_outlined,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          "Outstanding Balance",
                          _formatCurrency(loan['repayment_amount_per_cycle']),
                          Icons.account_balance_outlined,
                          Colors.orange,
                    ),
                    const SizedBox(height: 12),
                        _buildInfoRow(
                          "Next Repayment",
                          _formatDate(loan['next_repayment_date']),
                          Icons.event_outlined,
                          Colors.purple,
                        ),
                  ],
                ),
              ),
                ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
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

  Widget _buildStatusChip(dynamic status) {
    final label = status?['label'] ?? 'N/A';
    final color = _statusColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'overdue':
        return Colors.redAccent;
      case 'completed':
      case 'closed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
