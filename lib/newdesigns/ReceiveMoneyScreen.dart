import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/wallet_transfer_controller.dart';
import '../models/Beneficiary.dart';
import '../models/Wallet.dart';
import '../service/MobileMoneyService.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  final Map<String, dynamic> wallet;


  const ReceiveMoneyScreen({Key? key, required this.wallet}) : super(key: key);

  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final networkController = TextEditingController();

  final _descriptionController = TextEditingController();
  final _pinController = TextEditingController();
  String? selectedSourceWallet;

  List<Wallet> _wallets = [];
  List<Beneficiary> _beneficiaries = [];
  Beneficiary? _selectedBeneficiary;
  bool _isLoading = false;
  bool _saveToBeneficiaries = true;
  Color? _primaryColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });
    _loadBeneficiaries();
    _fetchThemeColors();
    selectedSourceWallet=widget.wallet['wallet_number']??"---";

  }
  Future<void> _fetchThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};
      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }


  Future<void> _loadBeneficiaries() async {
    try {
      final response = await MobileMoneyService.fetchBeneficiaries();

      print("*******************************\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+response.toString());

      if (response['status'] == true && response['data'] != null) {
        _beneficiaries = (response['data'] as List)
            .map((e) => Beneficiary.fromJson(e))
            .toList();
      } else {
        debugPrint("⚠️ No beneficiaries found.");
        _beneficiaries = [];
      }
    } catch (e) {
      debugPrint('❌ Failed to load beneficiaries: $e');
      _beneficiaries = [];
    }
  }


  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate() || selectedSourceWallet == null) {
      return;
    }

    setState(() => _isLoading = true);

    SmartDialog.showLoading(msg:"Just a moment...");

    try {
      final recipient = _selectedBeneficiary?.telephone ?? _phoneController.text;

      final response = await MobileMoneyService.createMobileMoneyContract(
        walletUuid: selectedSourceWallet!,
        contractType: 'deposit',
        amount: double.parse(_amountController.text),
     //   networkProvider: networkController.text,
        recipientPhoneOrUuid: recipient,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'Mobile Money Transfer',
        transactionPin: _pinController.text,
        saveToBeneficiaries: _saveToBeneficiaries && _selectedBeneficiary == null,
      );

      SmartDialog.dismiss();

      if (response['status'] == true) {
        Navigator.pushNamed(
          context,
          '/mobile_money_result',
          arguments: {
            'success': response['success'],
            'message': response['message'],
            'data': response['data'],
          },
        );
        SmartDialog.dismiss();

      } else {
        Navigator.pushNamed(
          context,
          '/mobile_money_result',
          arguments: {
            'success': response['success'],
            'message': response['message'],
            'data': response['data'],
          },
        );
        SmartDialog.dismiss();

      }
    } catch (e) {
      _showErrorSnackBar('Transaction failed: $e');
      SmartDialog.dismiss();

    } finally {
      setState(() => _isLoading = false);
      SmartDialog.dismiss();

    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text('Money sent successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  bool _isPinHidden = true;
  final List<Map<String, String>> networks = [
    {"value": "MTN", "image": "assets/airtime_data/mtn-logo.svg"},
    {"value": "Airtel", "image": "assets/airtime_data/airtel-logo.svg"},
    {"value": "Glo", "image": "assets/airtime_data/glo-logo.svg"},
    {"value": "9Mobile", "image": "assets/airtime_data/9mobile-logo.svg"},
  ];
  String? selectedNetwork;

  @override
  Widget build(BuildContext context) {
    final transferController = Provider.of<WalletTransferController>(context);



    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Via Mobile Money'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet Selection Card
              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(color: Colors.grey[200]!),

                ),

                child: Column(

                  children: [

                    Text(

                      "Source Wallet",

                      style: TextStyle(

                        fontSize: 16,

                        color: Colors.grey[600],

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                    const SizedBox(height: 8),

                    Text(



                        widget.wallet['currency']+ NumberFormat("#,##0.00")

                          .format(double.tryParse(widget.wallet['balance'].toString())),





                      style: const TextStyle(

                        fontSize: 32,

                        fontWeight: FontWeight.bold,

                        color: Colors.black87,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      'Account: '+ widget.wallet['wallet_number'],textAlign: TextAlign.center,

                      style: TextStyle(

                        fontSize: 18,

                        color: Colors.grey[600],

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 30),

              // Send To Section
              const Text(
                'Recipient Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              if (_beneficiaries.isNotEmpty) ...[
                DropdownButtonFormField<Beneficiary?>(
                  value: _selectedBeneficiary,
                  decoration: const InputDecoration(
                    labelText: 'Select Beneficiary (Optional)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<Beneficiary?>(
                      value: null,
                      child: Text('Enter new phone number'),
                    ),
                    ..._beneficiaries.map((beneficiary) {
                      return DropdownMenuItem(
                        value: beneficiary,
                        child: Text('${beneficiary.nickname} (${beneficiary.telephone})'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBeneficiary = value;
                      if (value != null) {
                        _phoneController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),
              ],

              if (_selectedBeneficiary == null) ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Phone Number eg: 254748**',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
              ],
              /*

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: networks.map((provider) {
                  final isSelected = selectedNetwork == provider['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedNetwork = provider['value'];
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


               */



              TextFormField(
                controller: networkController,
                decoration: const InputDecoration(
                  labelText: 'Network Provider (OPTIONAL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: Icon(Icons.network_cell),
                ),

              ),


              const SizedBox(height: 30),

              // Transaction Details Section
              const Text(
                'Transaction Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _pinController,
                obscureText: _isPinHidden,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "PIN",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isPinHidden ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPinHidden = !_isPinHidden),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) => value!.length != 4 ? "Enter a valid 4-digit PIN" : null,
              ),
              const SizedBox(height: 20),

              // Save to Beneficiaries Checkbox
              if (_selectedBeneficiary == null) ...[
                Row(
                  children: [
                    Checkbox(
                      value: _saveToBeneficiaries,
                      onChanged: (value) => setState(() => _saveToBeneficiaries = value ?? true),
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const Text('Save recipient to beneficiaries'),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Send Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMoney,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    :  Text(
                  'Deposit Money',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    networkController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}