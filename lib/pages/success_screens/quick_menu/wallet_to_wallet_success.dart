import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';

import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../controller/WalletTransactionController.dart';

class TransferResultPage extends StatefulWidget {
  const TransferResultPage({super.key});

  @override
  State<TransferResultPage> createState() => _TransferResultPageState();
}

class _TransferResultPageState extends State<TransferResultPage> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletTransactionController>(context, listen: false)
          .fetchWalletTransactions(refresh: false);
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool success = args?['success'] ?? false;
    final String message = args?['message'] ?? "No message received.";

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Card(
            elevation: 8,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: success
                        ? (_primaryColor ?? Colors.green)
                        : (_secondaryColor ?? Colors.red),
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    success ? "Transaction Successful" : "Transaction Failed",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: success
                          ? (_primaryColor ?? Colors.green[800])
                          : (_secondaryColor ?? Colors.red[800]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
               //   const SizedBox(height: 30),


                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor ?? Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.dashboard,
                              (route) => false,
                        ),
                        icon: const Icon(Icons.dashboard),
                        label: const Text("Dashboard"),
                      ),
                    ],
                  )


                ],
              ),
            ),
          ),
        ),
      ),)
    );
  }

}
