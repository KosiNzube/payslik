import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/cable_tv_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/routes.dart';

class CableTVPage extends StatefulWidget {
  const CableTVPage({super.key});

  @override
  State<CableTVPage> createState() => _CableTVPageState();
}

class _CableTVPageState extends State<CableTVPage> {
  bool isProcessing = false; // 🔥 Add this line

  final TextEditingController smartCardController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedProvider;
  String? selectedPlan;
  String? selectedApiKey;

  final List<Map<String, dynamic>> cableProviders = [
    {"name": "DStv", "image": "assets/cable/dstv.png", "apiKey": "dstv"},
    {"name": "GOtv", "image": "assets/cable/gotv.png", "apiKey": "gotv"},
    {"name": "StarTimes", "image": "assets/cable/startimes.png", "apiKey": "startimes"},
    {"name": "Showmax", "image": "assets/cable/showmax.png", "apiKey": "showmax"},
  ];


  // Dynamically gotten colors

  Color? _primaryColor;
  Color? _secondaryColor;
  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }


  @override
  void dispose() {
    smartCardController.dispose();
    pinController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void clearForm() {
    setState(() {
      smartCardController.clear();
      pinController.clear();
      phoneController.clear();
      selectedProvider = null;
      selectedPlan = null;
      selectedApiKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cableTVController = Provider.of<CableTVController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Cable TV Subscription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select Provider:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: cableProviders.map((provider) {
                final isSelected = selectedProvider == provider['name'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedProvider = provider['name'];
                        selectedApiKey = provider['apiKey'];
                        selectedPlan = null;
                      });

                      cableTVController.fetchSubscriptionPlans(selectedApiKey!);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Image.asset(provider['image']!, width: 50, height: 50),
                          const SizedBox(height: 4),
                          Text(provider['name']!, style: TextStyle(color: isSelected ? Colors.blue : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: smartCardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Smart Card/IUC Number",
                prefixIcon: const Icon(Icons.credit_card),
                border: const OutlineInputBorder(),
                suffixIcon: TextButton(
                  onPressed: selectedApiKey == null
                      ? null
                      : () {
                    cableTVController.verifySmartCard(
                      selectedApiKey!,
                      smartCardController.text.trim(),
                      context,
                    );
                  },
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // ✅ Green text
                    ),
                  ),
                ),

              ),
            ),


            const SizedBox(height: 24),
            Consumer<CableTVController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (selectedProvider == null || controller.subscriptionPlans.isEmpty) {
                  return const Text("No plans available. Select a provider first.");
                }
                return DropdownButtonFormField<String>(
                  value: selectedPlan,
                  hint: const Text("Choose a plan"),
                  isExpanded: true,  // ✅ FIXES OVERFLOW ISSUE
                  items: controller.subscriptionPlans.map((plan) {
                    return DropdownMenuItem<String>(
                      value: plan["variation_code"],
                      child: Text("${plan["name"]} - ₦${plan["variation_amount"]}"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPlan = value),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Enter Phone Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Transaction PIN",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cableTVController.isLoading || isProcessing
                    ? null
                    : () async {
                  if (selectedApiKey == null ||
                      selectedPlan == null ||
                      smartCardController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      pinController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Please fill all fields correctly!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() => isProcessing = true);

                  final result = await cableTVController.subscribeToCableTV(
                    cableTvType: selectedApiKey!,
                    smartCardNumber: smartCardController.text.trim(),
                    subscriptionPlan: selectedPlan!,
                    phoneNumber: phoneController.text.trim(),
                    transactionPin: pinController.text.trim(),
                    context: context,
                  );

                  if (!context.mounted) return;

                  Navigator.pushNamed(
                    context,
                    Routes.cable_result,
                    arguments: {
                      'success': result['success'],
                      'message': result['message'],
                    },
                  );

                  setState(() => isProcessing = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: cableTVController.isLoading || isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Subscribe",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
