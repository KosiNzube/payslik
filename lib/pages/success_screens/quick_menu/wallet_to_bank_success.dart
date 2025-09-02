import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';

import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../controller/WalletTransactionController.dart';

class WalletTransferResultPage extends StatefulWidget {
  const WalletTransferResultPage({super.key});

  @override
  State<WalletTransferResultPage> createState() => _WalletTransferResultPageState();
}

class _WalletTransferResultPageState extends State<WalletTransferResultPage> {
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

    final String reference = data?['reference_number'] ?? 'N/A';
    final double? amount = data?['user_amount'];
    final double? charge = data?['user_charge_amount'];
    final String balanceBefore = data?['user_balance_before']?.toString() ?? '-';
    final String balanceAfter = data?['user_balance_after']?.toString() ?? '-';
    final String description = data?['description'] ?? '';

    return WillPopScope(
        onWillPop:() async{
      Navigator.popUntil(context, ModalRoute.withName(Routes.dashboard));
      // Return false to prevent the default pop behavior
      return false;
    },

    child: Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Transfer Result"),
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
                    _detailRow("Charge", charge != null ? "₦${charge.toStringAsFixed(2)}" : "N/A"),
                    _detailRow("Before", "₦$balanceBefore"),
                    _detailRow("After", "₦$balanceAfter"),
                    _detailRow("Note", description),
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
