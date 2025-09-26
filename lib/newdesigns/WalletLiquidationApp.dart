import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../controller/wallet_to_bank_controller.dart';
import '../controller/wallet_transfer_controller.dart';
import '../utils/api_service.dart';



class WalletLiquidationScreen extends StatefulWidget {

  final Map<String, dynamic> wallet;

  const WalletLiquidationScreen({super.key, required this.wallet});


  @override
  _WalletLiquidationScreenState createState() => _WalletLiquidationScreenState();
}

class _WalletLiquidationScreenState extends State<WalletLiquidationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pinController = TextEditingController();
  final _walletNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String _accountName="";
  final _phoneNumberController = TextEditingController();
  final _cryptoAddressController = TextEditingController();
  bool saveBeneficiary = false;
  List<Map<String, dynamic>> filteredSuggestions = [];
  bool showSuggestions = false;
  final formatter = NumberFormat('#,###');


  // State variables
  String _liquidationType = 'full-wallet-balance';
  String _destinationType = 'wallet';
  String? selectedBank;
  String? selectedBankId;
  String? _selectedMobileNetwork;
  String? _selectedCrypto;
  String? _selectedCryptoNetwork;
  bool _showPin = false;
  bool _isLoading = false;



  /*
  // Data
  final List<Map<String, String>> _banks = [
    {'id': '88349504-2331-47a4-98e0-473cb9e2968f', 'name': 'First Bank Nigeria', 'code': 'FBN'},
    {'id': '12345678-1234-1234-1234-123456789012', 'name': 'GTBank', 'code': 'GTB'},
    {'id': '87654321-4321-4321-4321-210987654321', 'name': 'Access Bank', 'code': 'ACC'},
    {'id': '11111111-1111-1111-1111-111111111111', 'name': 'Zenith Bank', 'code': 'ZEN'},
  ];


   */
  final List<String> _mobileNetworks = ['MTN', 'Airtel', '9mobile', 'Glo'];
  final List<String> _cryptoTypes = ['USDT', 'BTC', 'ETH'];
  final List<String> _cryptoNetworks = ['TRC20', 'ERC20'];
  Color? _primaryColor;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _pinController.dispose();
    _walletNumberController.dispose();
    _accountNumberController.dispose();
    _phoneNumberController.dispose();
    _cryptoAddressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();

    final controller = Provider.of<WalletToBankTransferController>(context, listen: false);
    controller.fetchBanks();
    controller.fetchSourceWallets();
    controller.fetchSavedBeneficiaries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });

    _fetchThemeColors();

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquidate'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(

              children: [
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _scrollController,
                      children: [
                        SizedBox(height: 10),
                        _buildLiquidationTypeCard(),
                        SizedBox(height: 16),
                        _buildDestinationSelectionCard(),
                        SizedBox(height: 16),
                        _buildDestinationDetailsCard(),
                        SizedBox(height: 16),
                        _buildDescriptionCard(),
                        SizedBox(height: 16),
                        _buildTransactionPinCard(),
                        SizedBox(height: 16),
                        _buildSubmitButton(),
                        SizedBox(height: 16),
                        _buildSecurityNotice(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildLiquidationTypeCard() {
    return Container(
      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[200]!),

      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liquidation Type',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            _buildLiquidationOption(
              'full-wallet-balance',
              'Full Balance',
              '${widget.wallet['balance'].toStringAsFixed(2)}',
            ),
            SizedBox(height: 12),
            _buildLiquidationOption(
              'partial-wallet-balance',
              'Partial Amount',
              'Specify custom amount',
            ),
            if (_liquidationType == 'partial-wallet-balance') ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount to Liquidate',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                  ),
                ),
                validator: (value) {
                  if (_liquidationType == 'partial-wallet-balance') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    double amount = double.tryParse(value) ?? 0;
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }

                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidationOption(String value, String title, String subtitle) {
    bool isSelected = _liquidationType == value;
    return GestureDetector(
      onTap: () => setState(() => _liquidationType = value),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.indigo.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _liquidationType,
              onChanged: (String? newValue) {
                setState(() => _liquidationType = newValue!);
              },
              activeColor: Colors.indigo.shade500,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSelectionCard() {
    return Container(
      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[200]!),

      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Funds To',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildDestinationOption('wallet', Icons.account_balance_wallet, 'Another Wallet', Colors.blue),
                _buildDestinationOption('nip', Icons.credit_card, 'Bank Account', Colors.green),
                _buildDestinationOption('mobilemoney', Icons.phone_android, 'Mobile Money', Colors.purple),
                _buildDestinationOption('crypto', Icons.currency_bitcoin, 'Crypto Address', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationOption(String value, IconData icon, String label, Color color) {
    bool isSelected = _destinationType == value;
    return GestureDetector(
      onTap: () => setState(() => _destinationType = value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.indigo.shade50 : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationDetailsCard() {
    return Container(
      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[200]!),

      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination Details',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            _buildDestinationFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationFields() {
    final controller = Provider.of<WalletToBankTransferController>(context);
    final transferController = Provider.of<WalletTransferController>(context);

    switch (_destinationType) {
      case 'wallet':
        return Column(
          children: [

            /*
            TextFormField(
              controller: _walletNumberController,
              decoration: InputDecoration(
                labelText: 'Wallet Number',
                hintText: 'Enter wallet number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter wallet number';
                }
                return null;
              },
            ),

             */

            const Text("Destination wallet number"),
            TextFormField(
              controller: _walletNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (value) {
                if (value.length == 10) {
                  transferController.verifyWalletNumber(value);
                }
              },
              validator: (value) => value!.isEmpty ? "Wallet number is required" : null,
            ),
            const SizedBox(height: 8),

            Consumer<WalletTransferController>(builder: (context, controller, _) {
              if (controller.isVerifyingWallet) {
                return const Center(child: CircularProgressIndicator());
              } else if (controller.beneficiaryName.isNotEmpty) {
                return Text("Beneficiary: ${controller.beneficiaryName}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
              } else {
                return const Text("Enter destination wallet number", style: TextStyle(color: Colors.red));
              }
            }),

          ],
        );

      case 'nip':
        return Column(
          children: [

            /*
            DropdownButtonFormField<String>(
              value: _selectedBank,
              decoration: InputDecoration(
                labelText: 'Select Bank',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              items: _banks.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank['id'],
                  child: Text(bank['name']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedBank = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a bank';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Account Number',
                hintText: '0000000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                if (value.length != 10) {
                  return 'Account number must be 10 digits';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _accountNameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'Account holder name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account name';
                }
                return null;
              },
            ),

             */


            const Text("Account Number"),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                // labelText: "Account Number",
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],

              onChanged: (value) {
                final controller = Provider.of<WalletToBankTransferController>(context, listen: false);

                if (value.length >= 3) {
                  final suggestions = controller.savedBeneficiaries.where((b) {
                    return b['account_number'] != null &&
                        b['account_number'].toString().contains(value);
                  }).toList();

                  setState(() {
                    filteredSuggestions = suggestions;
                    showSuggestions = suggestions.isNotEmpty;
                  });
                } else {
                  setState(() {
                    showSuggestions = false;
                  });
                }

                if (value.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                  controller.verifyBankAccount(
                    accountNumber: value,
                    bankId: selectedBankId!,
                  );
                }
              },


            ),
            const SizedBox(height: 16),
            const Text("Select Bank"),
            DropdownSearch<Map<String, String>>(
              items: controller.banks.map<Map<String, String>>((bank) => {
                "bank_code": bank["bank_code"].toString(),
                "bank_name": bank["bank_name"].toString(),
              }).toList(),
              itemAsString: (bank) => bank["bank_name"]!,
              selectedItem: controller.banks
                  .map<Map<String, String>>((bank) => {
                "bank_code": bank["bank_code"].toString(),
                "bank_name": bank["bank_name"].toString(),
              })
                  .firstWhere(
                    (bank) => bank["bank_code"] == selectedBank,
                orElse: () => {"bank_code": "", "bank_name": "Select Bank"},
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  border: OutlineInputBorder(),
                  // labelText: "Select Bank",
                ),
              ),

              onChanged: (value) async {
                setState(() {
                  selectedBank = value?["bank_code"];

                  selectedBankId = controller.banks.firstWhere(
                        (bank) => bank['bank_code'].toString() == selectedBank,
                    orElse: () => {'id': null},
                  )['id']?.toString();
                });

                // ✅ Trigger verification if account number is already 10 digits
                final accountNumber = _accountNumberController.text;
                if (accountNumber.length == 10 && selectedBankId != null && selectedBankId != 'Unknown') {
                  await controller.verifyBankAccount(
                    accountNumber: accountNumber,
                    bankId: selectedBankId!,
                  );
                  _accountName=controller.beneficiaryName;

                }
              },



              validator: (value) => value == null ? "Please select a bank" : null,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(labelText: "Search Bank"),
                ),
              ),
            ),



            /*
            if (showSuggestions)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredSuggestions.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = filteredSuggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        suggestion['beneficiary_name'] ?? suggestion['account_number'],
                        style: TextStyle(color: Color(0xFFEB6D00)),
                      ),
                      subtitle: Text(
                        "${suggestion['bank_name']} - ${suggestion['account_number']}",
                        style: TextStyle(color: Color(0xFFEB6D00)),
                      ),

                      onTap: () {
                        setState(() {
                          _accountNumberController.text = suggestion['account_number'];
                          selectedBankId = suggestion['bank_id'];
                          showSuggestions = false;



                          final bank = controller.banks.firstWhere(
                                (bk) => bk['id'].toString() == suggestion['bank_id'],
                            orElse: () => {'bank_code': '', 'bank_name': ''},
                          );
                          selectedBank = bank['bank_code'];
                        });

                        controller.verifyBankAccount(
                          accountNumber: suggestion['account_number'],
                          bankId: suggestion['bank_id'],
                        );
                      },
                    );
                  },
                ),
              ),


             */
            const SizedBox(height: 8),

            controller.isVerifyingWallet
                ? const CircularProgressIndicator()
                : Text(
              controller.beneficiaryName.isNotEmpty
                  ? "Beneficiary: ${controller.beneficiaryName}"
                  : "Enter account number to verify",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),


            const SizedBox(height: 16),
          ],
        );

      case 'mobilemoney':
        return Column(
          children: [
            Text(
              'Mobile Network',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: _mobileNetworks.map((network) {
                bool isSelected = _selectedMobileNetwork == network;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMobileNetwork = network),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.indigo.shade50 : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        network,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '--- --------',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (_selectedMobileNetwork == null) {
                  return 'Please select mobile network';
                }
                return null;
              },
            ),
          ],
        );

      case 'crypto':
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCrypto,
              decoration: InputDecoration(
                labelText: 'Cryptocurrency',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              items: _cryptoTypes.map((crypto) {
                return DropdownMenuItem<String>(
                  value: crypto,
                  child: Text(crypto),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCrypto = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select cryptocurrency';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _cryptoAddressController,
              decoration: InputDecoration(
                labelText: 'Wallet Address',
                hintText: 'Enter wallet address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
              ),
              style: TextStyle(fontSize: 12),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter wallet address';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Text(
              'Network',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: _cryptoNetworks.map((network) {
                bool isSelected = _selectedCryptoNetwork == network;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: network == _cryptoNetworks.last ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCryptoNetwork = network),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.indigo.shade50 : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            network,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      default:
        return Container();
    }
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[200]!),

      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Add a note for this transaction',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionPinCard() {
    return Container(
      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[200]!),

      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey.shade700),
                SizedBox(width: 4),
                Text(
                  'Transaction PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPin = !_showPin),
                ),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter transaction PIN';
                }
                if (value.length != 4) {
                  return 'PIN must be 4 digits';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor!.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitLiquidationRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Submit Liquidation Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.amber.shade800, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This action cannot be undone. Please verify all details before submitting.',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> _submitLiquidationRequest() async {

    String _transactionMessage = "";


    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for crypto network
    if (_destinationType == 'crypto' && _selectedCryptoNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select crypto network')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestBody = _buildRequestBody();

      final String? token = await _getAuthToken();
      if (token == null) {
        _transactionMessage = "❌ You are not logged in. Please log in to continue.";
       // return {"success": false, "message": _transactionMessage};
      }

      final response = await ApiService.postRequest(
        "/request-mgt/liquidation-requests/wallet/submit",
        requestBody,
        extraHeaders: {'Authorization': 'Bearer $token'},

      );



      if (response["status"] == true) {
        _transactionMessage = response["message"] ?? "✅ Your transfer was successful! Funds have been sent to the bank.";
        _showSuccessDialog(response);

      } else {
        try {
          final errorData = jsonDecode(response['message']);
          _transactionMessage = errorData['message'] ?? 'Request failed';
        } catch (jsonError) {
          _transactionMessage = response['message'] ?? 'Request failed';
        }

        throw ApiException(_transactionMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_transactionMessage),
          backgroundColor: Colors.red,
        ),
      );


    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    Map<String, dynamic> body = {
      'liquidatble_wallet_number_or_uuid': widget.wallet['wallet_number'], // This should be dynamic
      'liquidation_type': _liquidationType,
      'liquidated_fund_destination': _destinationType,
      'liquidatble_description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Wallet liquidation request',
      'transaction_pin': _pinController.text,
    };

    if (_liquidationType == 'partial-wallet-balance') {
      body['liquidatble_amount'] = double.parse(_amountController.text);
    }

    switch (_destinationType) {
      case 'wallet':
        body['fund_destination_wallet_number_or_uuid'] = _walletNumberController.text;
        break;
      case 'nip':
        body['fund_destination_bank_uuid'] = selectedBankId;
        body['fund_destination_bank_account_number'] = _accountNumberController.text;
        body['fund_destination_bank_account_name'] = _accountName;
        break;
      case 'mobilemoney':
        body['destination_mobile_network'] = _selectedMobileNetwork?.toLowerCase();
        body['destination_mobile_number'] = _phoneNumberController.text;
        break;
      case 'crypto':
        body['destination_crypto_type'] = _selectedCrypto;
        body['destination_crypto_address'] = _cryptoAddressController.text;
        body['destination_crypto_network'] = _selectedCryptoNetwork;
        break;
    }

    return body;
  }

  void _showSuccessDialog(Map<String, dynamic> responseData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your liquidation request has been submitted successfully.'),
              SizedBox(height: 16),
              if (responseData['transaction_id'] != null) ...[
                Text(
                  'Transaction ID:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SelectableText(
                  responseData['transaction_id'].toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (responseData['status'] != null) ...[
                Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  responseData['status'].toString(),
                  style: TextStyle(color: Colors.green.shade600),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _descriptionController.clear();
    _pinController.clear();
    _walletNumberController.clear();
    _accountNumberController.clear();
    _phoneNumberController.clear();
    _cryptoAddressController.clear();

    setState(() {
      _liquidationType = 'full-wallet-balance';
      _destinationType = 'wallet';
      selectedBankId = null;
      _selectedMobileNetwork = null;
      _selectedCrypto = null;
      _selectedCryptoNetwork = null;
      _showPin = false;
    });

    // Scroll to top
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}