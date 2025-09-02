import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/routes.dart';

import '../../../WalletProviders/General_Wallet_Provider.dart';
import '../../../controller/WalletTransactionController.dart';

class CableTVResultPage extends StatefulWidget {
  const CableTVResultPage({super.key});

  @override
  State<CableTVResultPage> createState() => _CableTVResultPageState();
}

class _CableTVResultPageState extends State<CableTVResultPage> {
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralWalletProvider>().loadWallets();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletTransactionController>(context, listen: false)
          .fetchWalletTransactions(refresh: false);
    });
    _loadTheme();
  }

  Future<void> _loadTheme() async {
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
        title: const Text("Cable TV Subscription Result"),
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
                    success ? Icons.check_circle : Icons.cancel,
                    size: 100,
                    color: success ? _primaryColor : _secondaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
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
