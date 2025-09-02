import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/data_bundle_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/routes.dart';

class DataPurchasePage extends StatefulWidget {
  const DataPurchasePage({super.key});

  @override
  _DataPurchasePageState createState() => _DataPurchasePageState();
}



class _DataPurchasePageState extends State<DataPurchasePage> {
  String? selectedNetwork;
  String? selectedPlan;
  List<Map<String, dynamic>> dataPlans = [];
  bool isLoadingPlans = false;
  bool isProcessingPurchase = false;
  bool _pinVisible = false; // Visibility toggle for PIN
  bool showErrorMessage = false; // Flag for showing error message

  bool get _canAccessPinField {
    return selectedNetwork != null &&
        selectedPlan != null &&
        phoneController.text.trim().isNotEmpty;
  }

  bool get _isFormValid {
    return selectedNetwork != null &&
        selectedPlan != null &&
        phoneController.text.trim().isNotEmpty &&
        pinController.text.trim().length == 4;
  }


  final TextEditingController phoneController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  // Networks configuration
  final List<Map<String, String>> networks = [
    {"value": "MTN", "image": "assets/airtime_data/mtn-logo.svg"},
    {"value": "Airtel", "image": "assets/airtime_data/airtel-logo.svg"},
    {"value": "Glo", "image": "assets/airtime_data/glo-logo.svg"},
    {"value": "9Mobile", "image": "assets/airtime_data/9mobile-logo.svg"},
  ];
  Color? _primaryColor;
  Color? _secondaryColor;
  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    phoneController.addListener(_onInputChanged);
    pinController.addListener(_onInputChanged); // Add this line
  }
  void _onInputChanged() {
    setState(() {}); // Triggers rebuild so _canAccessPinField re-evaluates
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

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


  @override
  void dispose() {
    phoneController.removeListener(_onInputChanged);
    pinController.removeListener(_onInputChanged); // Add this line
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }


  Future<void> _fetchDataPlans(String network) async {
    setState(() {
      isLoadingPlans = true;
      dataPlans = [];
      selectedPlan = null;
      showErrorMessage = false; // Reset the error message flag
    });

    try {
      List<Map<String, dynamic>>? fetchedPlans = await DataBundleController.fetchDataBundles(network);

      setState(() {
        isLoadingPlans = false;
        if (fetchedPlans == null || fetchedPlans.isEmpty) {
          showErrorMessage = true; // Show error if no data plans are returned
        } else {
          dataPlans = fetchedPlans;
        }
      });
    } catch (e) {
      setState(() {
        isLoadingPlans = false;
        showErrorMessage = true; // Show error message in case of any API error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Failed to fetch data plans.")),
      );
    }
  }

  void _purchaseData() async {
    if (selectedNetwork == null || selectedPlan == null || phoneController.text.isEmpty || pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    setState(() => isProcessingPurchase = true);

    final result = await Provider.of<DataBundleController>(context, listen: false).buyDataBundle(
      networkProvider: selectedNetwork!,
      dataPlan: selectedPlan!,
      phoneNumber: phoneController.text,
      pin: pinController.text,
    );

    Navigator.pushNamed(
      context,
      Routes.data_result,
      arguments: {
        'success': result['success'],
        'message': result['message'],
      },
    );

    setState(() => isProcessingPurchase = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buy Data")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // **Network Selection**
            const Text(
              "Select Network:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: networks.map((provider) {
                final isSelected = selectedNetwork == provider['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedNetwork = provider['value'];
                        _fetchDataPlans(provider['value']!);
                      });
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

            // **Data Plan Selection**
            // **Data Plan Selection**
            const Text("Select Data Plan:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (isLoadingPlans)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: selectedPlan,
                items: dataPlans.map((plan) {
                  return DropdownMenuItem<String>(
                    value: plan["variation_code"].toString(),
                    child: Text(
                      "${plan["name"]} - ₦${plan["variation_amount"]}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedPlan = value),
                decoration: const InputDecoration(
                  labelText: "Select Data Plan",
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
              ),


            // **Error message if no data bundles available**
            if (showErrorMessage)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  "⚠️ VTU Services are currently not available. Please try again later.",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),

            // **Phone Number Input**
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter phone number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),

            const SizedBox(height: 24),

            // **Transaction PIN Input with Visibility Toggle**
            Text("Transaction PIN:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            IgnorePointer(
              ignoring: !_canAccessPinField,
              child: Opacity(
                opacity: _canAccessPinField ? 1.0 : 0.5,
                child: TextFormField(
                  controller: pinController,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: _canAccessPinField
                        ? "Transaction PIN"
                        : "Fill all fields to unlock",
                    hintText: "Enter your PIN",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_pinVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: _canAccessPinField
                          ? () => setState(() => _pinVisible = !_pinVisible)
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // **Purchase Button**
            ElevatedButton(
              onPressed: (!isProcessingPurchase && _isFormValid) ? _purchaseData : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // HEX color for background
                foregroundColor: Colors.white, // Text color set to white
                padding: const EdgeInsets.all(15), // Optional: Adds better spacing
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Optional: Rounded corners
              ),
              child: isProcessingPurchase
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Purchase Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
