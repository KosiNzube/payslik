import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// You must import the controller method from your provider/service
import 'package:gobeller/controller/loan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/profileControllers.dart';
import 'loan_success_page.dart'; // Adjust this path

class LoanFormPage extends StatefulWidget {
  final String productName;
  final String productId;
  final double amount;
  final String repaymentStartDate;
  final Map<String, dynamic> repaymentData;

  const LoanFormPage({
    super.key,
    required this.productName,
    required this.productId,
    required this.amount,
    required this.repaymentStartDate,
    required this.repaymentData,
  });

  @override
  _LoanFormPageState createState() => _LoanFormPageState();
}

class _LoanFormPageState extends State<LoanFormPage> {
  final _formKey = GlobalKey<FormState>();

  late Future<Map<String, dynamic>?> _userProfileFuture;

  // State variables
  String? loanPurpose, housingStatus, maritalStatus, repaymentPlan, relocateSoon;

  // Controllers
  final _salaryController = TextEditingController();
  final _dependentsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherIncomeController = TextEditingController();
  final _monthlyExpensesController = TextEditingController();
  final _houseAddressController = TextEditingController();
  final _relocationAddressController = TextEditingController();

  // Bank info controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isSubmitting = false;
  String? productName;
  String username = "";
  String? _orgFullName;

  String? _selectedBankId;
  String? _selectedWalletId;

  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

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
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();

    _userProfileFuture =  ProfileController.fetchUserProfile().then((profile) async {
      await _loadAppSettings();

      //  _loadAds();

      if (profile != null) {
        setState(() {
          username = "${profile['first_name']} "+ "${profile['last_name']}";

        });
      }
      return profile;
    });


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<LoanController>(context, listen: false);
      await controller.fetchBanks();
      await controller.fetchSourceWallets();

      // Get product name from productId
      final name = controller.getProductNameById(widget.productId);
      setState(() {
        loanPurpose = name; // Set as selected purpose
        productName = name;  // set local state
      });
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _dependentsController.dispose();
    _descriptionController.dispose();
    _otherIncomeController.dispose();
    _monthlyExpensesController.dispose();
    _houseAddressController.dispose();
    _relocationAddressController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final loanController = Provider.of<LoanController>(context, listen: false);

    final response = await loanController.submitLoanApplication(
      repaymentStartDate: widget.repaymentStartDate,
      loanProductId: widget.productId,
      loanAmount: widget.amount,
      description: _descriptionController.text,
      isEarningMonthlySalary: true,
      monthlySalaryAmount: double.tryParse(_salaryController.text),
      otherIncomeAmount: double.tryParse(_otherIncomeController.text),
      monthlyExpenses: _monthlyExpensesController.text,
      maritalStatus: maritalStatus ?? 'Single',
      isHouseOwner: housingStatus == 'Yes, I own',
      houseAddress: _houseAddressController.text,
      hasDependents: true,
      noOfDependents: int.tryParse(_dependentsController.text),
      isPlanningToRelocate: relocateSoon == 'Yes',
      newRelocationAddress: _relocationAddressController.text,
      preferredRepaymentMethod: repaymentPlan?.toLowerCase() ?? 'wallet',
      repaymentWalletId: repaymentPlan == 'Wallet' ? _selectedWalletId : null,
      repaymentBankId: ( repaymentPlan == 'Direct-Debit') ? _selectedBankId : null,
      repaymentBankAccountName: ( repaymentPlan == 'Direct-Debit') ? _accountNameController.text : null,
      repaymentBankAccountNumber: ( repaymentPlan == 'Direct-Debit') ? _accountNumberController.text : null,
    );

    setState(() => _isSubmitting = false);

    final snackBar = SnackBar(content: Text(response['message']));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    if (response['success']) {
      _formKey.currentState?.reset();
      _salaryController.clear();
      _dependentsController.clear();
      _descriptionController.clear();
      _otherIncomeController.clear();
      _monthlyExpensesController.clear();
      _houseAddressController.clear();
      _relocationAddressController.clear();
      _accountNumberController.clear();
      _accountNameController.clear();
      _bankNameController.clear();

      setState(() {
        loanPurpose = null;
        housingStatus = null;
        maritalStatus = null;
        repaymentPlan = null;
        relocateSoon = null;
        _selectedBankId = null;
        _selectedWalletId = null;
      });

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanSuccessPage(response: response),
          ),
        );
      }
    }
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');



    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};
      _orgFullName = data['full_name'] ?? '';




    }
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(widget.productName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's help you apply for a loan",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              _buildCard([
                _buildTextField(
                    label: 'How much do you want to borrow?',
                    icon:  FontAwesomeIcons.moneyBillWave,
                    initialValue: widget.amount.toString(),
                    readOnly: true),
                _buildTextField(
                  label: 'Purpose of Loan',
                  icon: Icons.assignment,
                  initialValue: widget.productName ?? 'Loading...',
                  readOnly: true,
                ),
                _buildTextField(
                  label: 'Desired Disbursement Date',
                  icon: Icons.date_range,
                  initialValue: widget.repaymentStartDate,
                  readOnly: true,
                ),
                _buildTextField(label: 'Monthly Income', icon: FontAwesomeIcons.moneyBillWave, controller: _salaryController),
                _buildTextField(label: 'Other Income', icon: FontAwesomeIcons.moneyBillWave, controller: _otherIncomeController),
                _buildTextField(label: 'Monthly Expenses', icon: FontAwesomeIcons.moneyBillWave, controller: _monthlyExpensesController),
                _buildTextField(label: 'Description', icon: Icons.edit, controller: _descriptionController),
              ]),

              const SizedBox(height: 20),

              _buildCard([
                _buildDropdownField(
                  label: 'Do you own a house?',
                  items: ['Yes, I own', 'No, I rent'],
                  value: housingStatus,
                  onChanged: (val) => setState(() => housingStatus = val),
                ),
                if (housingStatus == 'Yes, I own')
                  _buildTextField(label: 'House Address', icon: Icons.home, controller: _houseAddressController),
                _buildDropdownField(
                  label: 'Marital Status',
                  items: ['single', 'engaged', 'married', 'divorced', 'widowed'],
                  value: maritalStatus,
                  onChanged: (val) => setState(() => maritalStatus = val),
                ),
              ]),

              const SizedBox(height: 20),

              _buildCard([
                _buildTextField(label: 'Number of dependents', icon: Icons.group, controller: _dependentsController),
                _buildDropdownField(
                  label: 'How do you want to pay back?',
                  items: ['Wallet','Direct-Debit'],
                  value: repaymentPlan,
                  onChanged: (val) {
                    setState(() {
                      repaymentPlan = val;
                      if (val != 'Wallet') {
                        _selectedWalletId = null; // reset wallet id when not wallet plan
                      }
                    });
                  },
                ),

                // Enhanced Wallet Selector
                if (repaymentPlan == 'Wallet')
                  _buildWalletSelector(),

                if ( repaymentPlan == 'Direct-Debit') ...[
                  _buildBankDropdownField(),

                  Consumer<LoanController>(
                    builder: (context, loanController, _) {
                      // Automatically update account name controller when name is fetched
                      if (loanController.beneficiaryName.isNotEmpty &&
                          _accountNameController.text != loanController.beneficiaryName) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _accountNameController.text = loanController.beneficiaryName;
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Account Number',
                            icon: Icons.numbers,
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              if (val.length == 10 && _selectedBankId != null) {
                                loanController.verifyBankAccount(
                                  accountNumber: val,
                                  bankId: _selectedBankId!,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),

                          if (loanController.isVerifyingWallet)
                            const LinearProgressIndicator(minHeight: 2),

                          const SizedBox(height: 10),

                          _buildTextField(
                            label: 'Account Name',
                            icon: Icons.person,
                            controller: _accountNameController,
                            readOnly: true,
                          ),
                        ],
                      );
                    },
                  ),
                ],

                _buildDropdownField(
                  label: 'Do you want to relocate anytime soon?',
                  items: ['Yes', 'No'],
                  value: relocateSoon,
                  onChanged: (val) => setState(() => relocateSoon = val),
                ),
                if (relocateSoon == 'Yes')
                  _buildTextField(label: 'New Relocation Address', icon: Icons.location_on, controller: _relocationAddressController),
              ]),

              const SizedBox(height: 20),

              if (_orgFullName != null && _orgFullName!.isNotEmpty && username != null && username!.isNotEmpty )

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child:  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DECLARATION",
                          style: GoogleFonts.poppins(fontSize: 15,fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 2),

                        Text(
                          "I $username, being a registered user of $_orgFullName, hereby declare that the information provided on this 'Application for Loan' form is true and that the amount applied for, if approved, will be used specifically for that purpose. I also agreed with the $_orgFullName loan application rules which stipulated that my loan request be limited to ONLY double of the amount I have saved.",
                          style: GoogleFonts.poppins(fontSize: 14),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),

                  ),
                ),


              const SizedBox(height: 40),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Application', style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Wallet Selector Widget
  Widget _buildWalletSelector() {
    return Consumer<LoanController>(
      builder: (context, loanController, _) {
        // Show loading state
        if (loanController.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading wallets...'),
                ],
              ),
            ),
          );
        }

        final wallets = loanController.sourceWallets;

        // Debug info (remove in production)
        print('🔹 Wallet selector - wallets count: ${wallets.length}');
        print('🔹 Wallet selector - wallets data: $wallets');

        // Show error/empty state with retry option
        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(Icons.wallet, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No wallets found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please make sure you have a personal wallet set up',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    print('🔄 Retrying wallet fetch...');
                    await loanController.fetchSourceWallets();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          );
        }

        // Show wallet dropdown
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Wallet',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: '${wallets.length} wallet(s) available',
            ),
            value: _selectedWalletId,
            items: wallets.map((wallet) {
              String walletId = wallet['id']?.toString() ?? '';
              String walletType = wallet['wallet_type']?.toString() ?? 'Wallet';
              String walletNumber = wallet['account_number']?.toString() ?? wallet['wallet_number']?.toString() ?? 'N/A';
              String currencySymbol = wallet['currency_symbol']?.toString() ?? '₦';
              String balance = wallet['available_balance']?.toString() ?? wallet['balance']?.toString() ?? '0.00';
              String label = '$walletType - $walletNumber';
              if (balance != '0.00') {
                label += ' ($currencySymbol$balance)';
              } else {
                label += ' ($currencySymbol)';
              }

              return DropdownMenuItem<String>(
                value: walletId,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (wallet['ownership_label'] != null)
                      Text(
                        wallet['ownership_label'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return wallets.map((wallet) {
                String walletType = wallet['wallet_type']?.toString() ?? 'Wallet';
                String walletNumber = wallet['account_number']?.toString() ?? wallet['wallet_number']?.toString() ?? 'N/A';
                String currencySymbol = wallet['currency_symbol']?.toString() ?? '₦';
                String balance = wallet['available_balance']?.toString() ?? wallet['balance']?.toString() ?? '0.00';
                String label = '$walletType - $walletNumber';
                if (balance != '0.00') {
                  label += ' ($currencySymbol$balance)';
                } else {
                  label += ' ($currencySymbol)';
                }

                return Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                );
              }).toList();
            },
            onChanged: (value) {
              print('🔹 Selected wallet ID: $value');
              setState(() => _selectedWalletId = value);
            },
            validator: (value) {
              if (repaymentPlan == 'Wallet' && (value == null || value.isEmpty)) {
                return 'Please select a wallet for repayment';
              }
              return null;
            },
            isExpanded: true,
          ),

        );
      },
    );
  }

  Widget _buildBankDropdownField() {
    return Consumer<LoanController>(
      builder: (context, loanController, _) {
        final banks = loanController.banks;

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Bank',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          value: _selectedBankId,
          items: banks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank['id'].toString(),
              child: Text(bank['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedBankId = value);
          },
          validator: (value) {
            if (( repaymentPlan == 'Direct-Debit') && value == null) {
              return 'Please select a bank';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    IconData? icon,
    String? prefixText,
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: keyboardType ??
            (label == 'Monthly Salary' ||
                label == 'Other Income' ||
                label == 'Number of dependents' ||
                label == 'Account Number' ||
                label == 'Monthly Expenses'
                ? TextInputType.number
                : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon)
              : prefixText != null
              ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(prefixText, style: const TextStyle(fontSize: 16)),
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hint: Text(label.toLowerCase()=="description"?"What do you want this loan for":""),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select' : null,
      ),
    );
  }


}