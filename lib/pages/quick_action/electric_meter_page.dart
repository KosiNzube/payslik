import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/electricity_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/routes.dart';

class ElectricityPaymentPage extends StatefulWidget {
  const ElectricityPaymentPage({super.key});

  @override
  State<ElectricityPaymentPage> createState() => _ElectricityPaymentPageState();
}

class _ElectricityPaymentPageState extends State<ElectricityPaymentPage> {
  String? selectedDisco;
  String? selectedMeterType;
  bool isProcessingPurchase = false;
  final TextEditingController meterNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  Color? _primaryColor;
  Color? _secondaryColor;

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? '#2196F3'; // default blue
      final secondaryColorHex = data['customized-app-secondary-color'] ?? '#FF5722'; // default deep orange

      try {
        setState(() {
          _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
          _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        });
      } catch (e) {
        // Fallback to defaults in case of parse error
        setState(() {
          _primaryColor = const Color(0xFF2196F3);
          _secondaryColor = const Color(0xFFFF5722);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ElectricityController>(context, listen: false).fetchMeterServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final electricityController = Provider.of<ElectricityController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Electricity Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Disco Dropdown
              const Text("Select Electricity Disco:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              electricityController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : electricityController.electricityDiscos.isEmpty
                  ? const Text("No Electricity Discos available")
                  : DropdownButtonFormField<String>(
                value: selectedDisco,
                hint: const Text("Choose a provider"),
                items: electricityController.electricityDiscos.map((disco) {
                  return DropdownMenuItem<String>(
                    value: disco["id"],
                    child: Text(disco["name"]!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedDisco = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),

              /// Meter Type Dropdown
              const Text("Select Meter Type:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              electricityController.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : electricityController.meterTypes.isEmpty
                  ? const Text("No Meter Types available")
                  : DropdownButtonFormField<String>(
                value: selectedMeterType,
                hint: const Text("Choose a meter type"),
                items: electricityController.meterTypes.map((meter) {
                  return DropdownMenuItem<String>(
                    value: meter["id"],
                    child: Text(meter["name"]!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedMeterType = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),

              /// Meter Number + Verify
              const Text("Enter Meter Number:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: meterNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter meter number",
                  border: const OutlineInputBorder(),
                  suffixIcon: electricityController.isVerifying
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : TextButton(
                    onPressed: () {
                      if (selectedDisco != null &&
                          selectedMeterType != null &&
                          meterNumberController.text.isNotEmpty) {
                        electricityController.verifyMeterNumber(
                          electricityDisco: selectedDisco!,
                          meterType: selectedMeterType!,
                          meterNumber: meterNumberController.text,
                          context: context,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("⚠️ Please fill all fields!")),
                        );
                      }
                    },
                    child: Text(
                      "Verify",
                      style: TextStyle(
                        color: _primaryColor ?? Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (electricityController.meterOwnerName != null) ...[
                Text(
                  "✅ Meter Owner: ${electricityController.meterOwnerName}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
              ],

              if (electricityController.meterOwnerName != null) ...[
                /// Amount Input
                const Text("Enter Amount:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter amount",
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                /// Phone Number
                const Text("Enter Phone Number:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneNumberController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter phone number",
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                /// PIN
                const Text("Enter Transaction PIN:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter PIN",
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),

                /// Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: electricityController.isPurchasing
                        ? null
                        : () async {
                      if (selectedDisco == null ||
                          selectedMeterType == null ||
                          meterNumberController.text.isEmpty ||
                          amountController.text.isEmpty ||
                          phoneNumberController.text.isEmpty ||
                          pinController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("⚠️ Please fill all fields!")),
                        );
                        return;
                      }

                      setState(() => isProcessingPurchase = true);

                      final result = await electricityController.purchaseElectricity(
                        meterNumber: meterNumberController.text.trim(),
                        electricityDisco: selectedDisco!,
                        meterType: selectedMeterType!,
                        amount: amountController.text.trim(),
                        phoneNumber: phoneNumberController.text.trim(),
                        pin: pinController.text.trim(),
                      );

                      if (!context.mounted) return;

                      Navigator.pushNamed(
                        context,
                        Routes.electricity_result,
                        arguments: {
                          'success': result['success'],
                          'message': result['message'],
                        },
                      );

                      setState(() => isProcessingPurchase = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: electricityController.isPurchasing || isProcessingPurchase
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Purchase Electricity",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ]

            ],
          ),
        ),
      ),
    );
  }
}
