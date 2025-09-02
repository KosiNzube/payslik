import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/property_controller.dart';

class ProcessSubscriptionScreen extends StatefulWidget {
  final String propertyId;
  final int quantity;
  final String desiredPaymentStartDate;
  final int desiredPaymentDurationInterval;
  final String preferredPaymentOption;
  final String? bankId;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? walletId;
  final String? bankName;
  final String? walletName;

  const ProcessSubscriptionScreen({
    super.key,
    required this.propertyId,
    required this.quantity,
    required this.desiredPaymentStartDate,
    required this.desiredPaymentDurationInterval,
    required this.preferredPaymentOption,
    this.bankId,
    this.bankAccountNumber,
    this.bankAccountName,
    this.walletId,
    this.bankName,
    this.walletName,
  });

  @override
  State<ProcessSubscriptionScreen> createState() => _ProcessSubscriptionScreenState();
}

class _ProcessSubscriptionScreenState extends State<ProcessSubscriptionScreen> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

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
              : Colors.green;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.greenAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {
        // ignore JSON parse errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyController = Provider.of<PropertyController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm & Process Subscription"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Review Subscription Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Property ID", widget.propertyId),
                    _buildDetailRow("Quantity", widget.quantity.toString()),
                    _buildDetailRow("Start Date", widget.desiredPaymentStartDate),
                    _buildDetailRow("Duration Interval", "${widget.desiredPaymentDurationInterval} month(s)"),
                    _buildDetailRow("Payment Option", widget.preferredPaymentOption.toUpperCase()),
                    if (widget.preferredPaymentOption == 'bank' || widget.preferredPaymentOption == 'direct-debit') ...[
                      const Divider(height: 24),
                      _buildDetailRow("Bank", widget.bankName ?? "-"),
                      _buildDetailRow("Account Number", widget.bankAccountNumber ?? "-"),
                      _buildDetailRow("Account Name", widget.bankAccountName ?? "-"),
                    ],
                    if (widget.preferredPaymentOption == 'wallet') ...[
                      const Divider(height: 24),
                      _buildDetailRow("Wallet", widget.walletName ?? "-"),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Confirm and Process"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor ?? Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final result = await propertyController.processSubscriptionRequest(
                  propertyId: widget.propertyId,
                  quantity: widget.quantity,
                  desiredPaymentStartDate: widget.desiredPaymentStartDate,
                  desiredPaymentDurationInterval: widget.desiredPaymentDurationInterval,
                  preferredPaymentOption: widget.preferredPaymentOption,
                  bankId: widget.bankId,
                  bankAccountNumber: widget.bankAccountNumber,
                  bankAccountName: widget.bankAccountName,
                  walletId: widget.walletId,
                  bankName: widget.bankName,
                  walletName: widget.walletName,
                );

                if (result['status'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Subscription processed successfully")),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                        (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed: ${result['message']}")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
