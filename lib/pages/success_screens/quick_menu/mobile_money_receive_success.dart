import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';

import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../controller/WalletTransactionController.dart';

class MobileMoneyReceiveSuccessPage extends StatefulWidget {
  const MobileMoneyReceiveSuccessPage({super.key});

  @override
  State<MobileMoneyReceiveSuccessPage> createState() => _MobileMoneyReceiveSuccessPageState();
}

class _MobileMoneyReceiveSuccessPageState extends State<MobileMoneyReceiveSuccessPage> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletTransactionController>(context, listen: false)
          .fetchWalletTransactions(refresh: false);
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          _primaryColor = data['customized-app-primary-color'] != null
              ? Color(int.parse(data['customized-app-primary-color'].replaceAll('#', '0xFF')))
              : Colors.green;

          _secondaryColor = data['customized-app-secondary-color'] != null
              ? Color(int.parse(data['customized-app-secondary-color'].replaceAll('#', '0xFF')))
              : Colors.redAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool success = args?['success'] ?? false;
    final String message = args?['message'] ?? 'No message received.';
    final data = args?['data'];

    final String reference = data?['id'] ?? 'N/A';
    final double? amount = data?['amount'] != null ? double.tryParse(data['amount']) : null;
    final String transactionType = data?['transaction_type'] ?? '-';
    final String description = data?['transaction_description'] ?? '';

// Decode owner_request_data
    final Map<String, dynamic> requestData = data?['owner_request_data'] != null
        ? jsonDecode(data['owner_request_data'])
        : {};

    final double? contractAmount = requestData['contract_amount'] != null
        ? (requestData['contract_amount'] as num).toDouble()
        : null;
    final String contractType = requestData['contract_type'] ?? '-';
    final String recipientNumber = requestData['recipient_or_payer_number_or_benf_uuid'] ?? '-';
    final String contractDescription = requestData['contract_description'] ?? '';

    return WillPopScope(
        onWillPop:() async{
      Navigator.popUntil(context, ModalRoute.withName(Routes.dashboard));
      // Return false to prevent the default pop behavior
      return false;
    },

    child: Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Transaction Result"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: _logoUrl != null
            ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(_logoUrl!, fit: BoxFit.contain),
        )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 100,
                    color: success ? _primaryColor ?? Colors.green : _secondaryColor ?? Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    success ? "Success!" : "Transaction Failed",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  if (success && data != null) ...[
                    const Divider(),
                    _detailRow("Reference", reference),
                    _detailRow("Amount", amount != null ? "₦${amount.toStringAsFixed(2)}" : "N/A"),
                    _detailRow("Contract Amount", contractAmount != null ? "₦${contractAmount.toStringAsFixed(2)}" : "N/A"),
                    _detailRow("Type", transactionType),
                    _detailRow("Contract Type", contractType),
                    _detailRow("Recipient", recipientNumber),
                    _detailRow("Description", description.isNotEmpty ? description : contractDescription),
                    const Divider(),
                  ],


                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.dashboard,
                              (route) => false,
                        ),
                        icon: const Icon(Icons.dashboard),
                        label: const Text("Dashboard"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor ?? Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),)
    );
  }


  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
