import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/airtime_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/routes.dart';

class BuyAirtimePage extends StatefulWidget {
  const BuyAirtimePage({super.key});

  @override
  State<BuyAirtimePage> createState() => _BuyAirtimePageState();
}

class _BuyAirtimePageState extends State<BuyAirtimePage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  String? selectedNetwork;
  bool isProcessing = false;
  bool isPinVisible = false;
  bool get _canAccessPinField {
    return selectedNetwork != null &&
        phoneController.text.trim().isNotEmpty &&
        amountController.text.trim().isNotEmpty;
  }
  bool get _isFormValid {
    final phone = phoneController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final pin = pinController.text.trim();

    return selectedNetwork != null &&
        phone.isNotEmpty &&
        phone.length == 11 &&
        amount >= 50 &&
        pin.length == 4;
  }

  Color? _primaryColor;
  Color? _secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    phoneController.addListener(_onInputChanged);
    amountController.addListener(_onInputChanged);
    pinController.addListener(_onInputChanged);

  }
  void _onInputChanged() {
    setState(() {}); // Triggers rebuild so _canAccessPinField re-evaluates
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  final List<Map<String, String>> networks = [
    {"value": "MTN", "image": "assets/airtime_data/mtn-logo.svg"},
    {"value": "Airtel", "image": "assets/airtime_data/airtel-logo.svg"},
    {"value": "Glo", "image": "assets/airtime_data/glo-logo.svg"},
    {"value": "9mobile", "image": "assets/airtime_data/9mobile-logo.svg"},
  ];

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    pinController.removeListener(_onInputChanged);
    phoneController.removeListener(_onInputChanged);
    amountController.removeListener(_onInputChanged);
    super.dispose();
  }

  void _buyAirtime() async {
    if (selectedNetwork == null ||
        phoneController.text.isEmpty ||
        amountController.text.isEmpty ||
        pinController.text.isEmpty) {
      _navigateToResultPage(false, "⚠️ Please fill all fields");
      return;
    }

    final double amount = double.tryParse(amountController.text) ?? 0;
    if (amount < 50) {
      _navigateToResultPage(false, "💰 Minimum airtime amount is ₦50.");
      return;
    }

    if (pinController.text.length != 4) {
      _navigateToResultPage(false, "🔒 PIN must be exactly 4 digits");
      return;
    }

    setState(() => isProcessing = true);

    final result = await Provider.of<AirtimeController>(context, listen: false).buyAirtime(
      networkProvider: selectedNetwork!,
      phoneNumber: phoneController.text,
      amount: amountController.text,
      pin: pinController.text,
    );

    setState(() {
      isProcessing = false;
      phoneController.clear();
      amountController.clear();
      pinController.clear();
      selectedNetwork = null;
    });

    _navigateToResultPage(result['success'], result['message']);
  }

  void _navigateToResultPage(bool success, String message) {
    Navigator.pushNamed(
      context,
      Routes.airtime_result,
      arguments: {
        'success': success,
        'message': message,
      },
    );
  }






  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buy Airtime")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select Network:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: networks.map((provider) {
                final isSelected = selectedNetwork == provider['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedNetwork = provider['value']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            provider['image']!,
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          Text(provider['value']!,
                              style: TextStyle(
                                  color: isSelected ? Colors.blue : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text("Phone Number:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Enter phone number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),

            const SizedBox(height: 24),

            const Text("Amount (₦):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter amount (min ₦50)",
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),


            const SizedBox(height: 24),

            Text("Transaction PIN:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            IgnorePointer(
              ignoring: !_canAccessPinField,
              child: Opacity(
                opacity: _canAccessPinField ? 1.0 : 0.5,
                child: TextFormField(
                  controller: pinController,
                  obscureText: !isPinVisible,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _canAccessPinField
                        ? "Enter your PIN"
                        : "Fill other fields to unlock",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isPinVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: _canAccessPinField
                          ? () => setState(() => isPinVisible = !isPinVisible)
                          : null,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isProcessing || !_isFormValid ? null : _buyAirtime,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: _isFormValid
                    ? (_primaryColor ?? Theme.of(context).primaryColor)
                    : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Buy Airtime",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

          ],
        ),
      ),
    );
  }
}
