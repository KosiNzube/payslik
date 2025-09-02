import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart'; // 👈 Add this
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/registration_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/create_wallet_controller.dart';
import '../../controller/organization_controller.dart';
import '../../models/Country.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isTransactionPinObscured = true; // Add this line
  bool _isTermsAccepted = false;
  String selectedCurrencyId = '';

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _azanumberController = TextEditingController();
  final TextEditingController bvnController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _transactionPinController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _referralNumberController = TextEditingController();


  final TextEditingController ledger_number = TextEditingController();
  final TextEditingController ippis_number = TextEditingController();
  final TextEditingController pf_number = TextEditingController();


  String? _selectedIdType;
  bool _showIdInput = false;
  bool _showFullForm = false;
  bool _hasPopulatedFields = false;
  bool _showFullForm_no_KYC = false;
  String? _selectedGender;
  Color? _primaryColor;
  Color? _secondaryColor;
  Color? _tertiaryColor;
  String? _logoUrl;  // Variable to store the logo URL

  // Fetch the primary color and logo URL from SharedPreferences
  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final tertiaryColorHex = data['customized-app-tertiary-color'] ?? '#ffffff';
      final logoUrl = data['customized-app-logo-url'];  // Fetch logo URL

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _tertiaryColor = Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')));

        _logoUrl = logoUrl;  // Save the logo URL
      });
    }
  }

  late VideoPlayerController _videoController;

  bool _isBvnOptionEnabled = false;
  bool _isNinOptionEnabled = false;
  bool _isPassportOptionEnabled = false;
  bool _isdisplay_register_no_kyc = false;
  bool _isdisplay_thirdparty = false;

  bool should_create_virtual_wallet = false;
  List<dynamic> currencies = [];


// Add this method to load the organization settings
  Future<void> _loadRegistrationOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        final menuItems = orgData['data']?['customized_app_displayable_menu_items'];

        setState(() {
          _isBvnOptionEnabled = menuItems?['display-register-with-bvn-option'] ?? false;
          _isNinOptionEnabled = menuItems?['display-register-with-nin-option'] ?? false;
          _isPassportOptionEnabled = menuItems?['display-register-with-passport-option'] ?? false;
          _isdisplay_register_no_kyc = menuItems?['display-register-with-no-kyc-option'] ?? false;
          _isdisplay_thirdparty = menuItems?['display-register-with-thirdparty-provider-option'] ?? false;

          should_create_virtual_wallet= menuItems?['display-create-wallet-option-at-registration'] ?? false;


        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _isBvnOptionEnabled = false;
          _isNinOptionEnabled = false;
          _isPassportOptionEnabled = false;
          _isdisplay_register_no_kyc=false;
        });
      }
    }
  }
  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  Country? _selectedCountry;
  bool _isLoadingCountries = true;
  bool isCurrencyLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadCountries();
    _loadCurrencies();
    _loadPrimaryColorAndLogo();
    _loadRegistrationOptions();

  }
  Future<void> _loadCurrencies() async {
    try {
      if (!mounted) return;
      setState(() => isCurrencyLoading = true);

      final response = await CurrencyController.fetchCurrencieX();
      debugPrint("Currencies loaded: $response");

      if (response.isNotEmpty) {
        setState(() => currencies = response);
      }
    } catch (e) {
      debugPrint("Failed to load currencies: $e");
    } finally {
      if (!mounted) return;
      setState(() => isCurrencyLoading = false);
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      final result = await CountryService.fetchCountries();
      if (mounted) {
        setState(() {
          _countries = result;
          _filteredCountries = List.from(_countries); // Initialize filtered list
          _selectedCountry = _countries.first;
          _isLoadingCountries = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to load countries: $e");
      if (mounted) {
        setState(() => _isLoadingCountries = false);
      }
      // Optionally show error toast or fallback UI
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('');
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(0.0);
    _videoController.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _populateFieldsFromVerificationData(Map<String, dynamic> data) {
    _firstNameController.text = data['first_name'] ?? '';
    _middleNameController.text = data['middle_name'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _usernameController.text = data['username'] ?? '';
    _emailController.text = data['email'] ?? '';
    _telephoneController.text = data['phone_number1'] ?? data['telephone'] ?? '';
    _addressController.text = data['physical_address'] ?? '';
    _dobController.text = data['date_of_birth'] ?? '';
  }

  void _resetFormState() {
    _formKey.currentState?.reset();
    _idNumberController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _usernameController.clear();
    _emailController.clear();
    _telephoneController.clear();
    _addressController.clear();
    pf_number.clear();
    ippis_number.clear();
    pf_number.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _transactionPinController.clear();
    _dobController.clear();

    setState(() {
      _selectedIdType = null;
      _showIdInput = false;
      _showFullForm = false;
      _hasPopulatedFields = false;
      _isTermsAccepted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ninController = Provider.of<NinVerificationController>(context);
    final no_kyc_controller = Provider.of<No_KYC_Controller>(context);

    if (ninController.ninData != null && !_hasPopulatedFields) {
      _populateFieldsFromVerificationData(ninController.ninData!);
      _hasPopulatedFields = true;
      _showFullForm = true;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        fit: StackFit.expand,
        children: [

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // Logo Container with better styling
                      if (_logoUrl != null)
                        Image.network(
                          _logoUrl!,
                          width: 128,
                          height: 128,
                          fit: BoxFit.contain,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return SizedBox(
                                width: 128,
                                height: 128,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                ),
                              );
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Getting Data...',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),

                      // Header Section with improved typography
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Create Your Account",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Join us today and get started",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              "Already have an account? Sign in",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ID Type Selection with modern card design
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Verification Method",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedIdType,
                                decoration: InputDecoration(
                                  labelText: "Select ID Type",
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                dropdownColor: Colors.white,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: [
                                  if (_isNinOptionEnabled)
                                    DropdownMenuItem<String>(
                                      value: "nin",
                                      child: Row(
                                        children: [
                                          Icon(Icons.badge_outlined, color: Colors.grey[600], size: 20),
                                          const SizedBox(width: 12),
                                          const Text("Register with NIN"),
                                        ],
                                      ),
                                    ),
                                  if (_isBvnOptionEnabled)
                                    DropdownMenuItem<String>(
                                      value: "bvn",
                                      child: Row(
                                        children: [
                                          Icon(Icons.account_balance_outlined, color: Colors.grey[600], size: 20),
                                          const SizedBox(width: 12),
                                          const Text("Register with BVN"),
                                        ],
                                      ),
                                    ),
                                  if (_isPassportOptionEnabled)
                                    DropdownMenuItem<String>(
                                      value: "passport-number",
                                      child: Row(
                                        children: [
                                          Icon(Icons.description_outlined, color: Colors.grey[600], size: 20),
                                          const SizedBox(width: 12),
                                          const Text("Register with Passport"),
                                        ],
                                      ),
                                    ),


                                  if (_isdisplay_register_no_kyc)
                                    DropdownMenuItem<String>(
                                      value: "no-kyc",
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
                                          const SizedBox(width: 12),
                                          const Text("Register without KYC"),
                                        ],
                                      ),
                                    ),


                                  if(_isdisplay_thirdparty)
                                      DropdownMenuItem<String>(
                                        value: "existing-account",
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, color: Colors.grey[600], size: 20),
                                            const SizedBox(width: 12),
                                            const Text("Have existing account?"),
                                          ],
                                        ),
                                      ),


                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedIdType = value;
                                    _showIdInput = value == "no-kyc" || value == "existing-account" ? false : true;
                                    _showFullForm = false;
                                    _showFullForm_no_KYC = value == "no-kyc" || value == "existing-account"  ? true : false;
                                    _hasPopulatedFields = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ID Input Section
                      if (_showIdInput) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Enter Verification Details",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _idNumberController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Enter ID Number",
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) =>
                                  value == null || value.isEmpty ? "ID number is required" : null,
                                ),
                                const SizedBox(height: 20),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_idNumberController.text.isNotEmpty) {
                                        ninController.verifyId(_idNumberController.text.trim(), _selectedIdType!);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: ninController.isVerifying
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(
                                      'Verify Identity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Verification Message
                                if (ninController.verificationMessage.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: ninController.verificationMessage.contains('Success')
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: ninController.verificationMessage.contains('Success')
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ninController.verificationMessage.contains('Success')
                                              ? Icons.check_circle_outline
                                              : Icons.error_outline,
                                          color: ninController.verificationMessage.contains('Success')
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ninController.verificationMessage,
                                            style: TextStyle(
                                              color: ninController.verificationMessage.contains('Success')
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Full Form Sections
                      if (_showFullForm)
                        _buildFullForm(ninController),

                      if (_showFullForm_no_KYC)
                        _buildFullForm_no_KYC(no_kyc_controller),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullForm(NinVerificationController ninController) {
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final orgData = orgController.organizationData?['data'] ?? {};
    final identityCode = orgData['org_identity_code'] ?? '';


    final data = ninController.ninData;
    String gender = (data?['gender'] ?? 'unspecified').toString().toLowerCase();

    // Professional styling constants
    const primaryColor = Color(0xFFEB6D00);
    const textColor = Color(0xFF2D3748);
    const borderColor = Color(0xFFE2E8F0);
    const focusedBorderColor = Color(0xFFEB6D00);
    const backgroundColor = Color(0xFFFAFAFA);

    const labelStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    const inputTextStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );

    OutlineInputBorder _buildInputBorder(Color color, {double width = 1.0}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon, String? helperText}) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        helperText: helperText,
        helperStyle: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _buildInputBorder(borderColor),
        focusedBorder: _buildInputBorder(focusedBorderColor, width: 2.0),
        errorBorder: _buildInputBorder(Colors.red.shade300),
        focusedErrorBorder: _buildInputBorder(Colors.red.shade400, width: 2.0),
        suffixIcon: suffixIcon,
      );
    }

    Widget _buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 24),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      );
    }

    Widget _buildFormSection(String title, List<Widget> children) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }
    Widget _buildDropdown({
      required String label,
      required List<DropdownMenuItem<String>> items,
      String? value,
      void Function(String?)? onChanged,
    }) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: items,
        value: value,
        onChanged: onChanged,
      );
    }
    Widget _buildPasswordField({
      required TextEditingController controller,
      required String label,
      required bool obscureText,
      required VoidCallback onToggleVisibility,
      String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: inputTextStyle,
        decoration: _buildInputDecoration(
          label,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textColor.withOpacity(0.6),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
        validator: validator,
      );
    }

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _buildFormSection("Personal Information", [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      style: inputTextStyle,
                      decoration: _buildInputDecoration("First Name"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _middleNameController,
                      style: inputTextStyle,
                      decoration: _buildInputDecoration("Middle Name"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Last Name"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                style: inputTextStyle,
                decoration: _buildInputDecoration(
                  "Date of Birth",
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                onTap: () async {
                  DateTime initialDate;
                  try {
                    initialDate = DateTime.parse(_dobController.text);
                  } catch (_) {
                    initialDate = DateTime(2000);
                  }

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: textColor,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    _dobController.text = picked.toIso8601String().split('T').first;
                  }
                },
              ),
            ]),

            // Account Information Section
            _buildFormSection("Account Information", [
              TextFormField(
                controller: _usernameController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Username"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: inputTextStyle,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("Email Address"),
              ),
              const SizedBox(height: 16),
              _isLoadingCountries
                  ?   CircularProgressIndicator()
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showCountryBottomSheet(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCountry != null
                                ? "${_selectedCountry!.name} (${_selectedCountry!.phoneCode})"
                                : "Select Country",
                            style: TextStyle(
                              color: _selectedCountry != null ? Colors.black : Colors.grey[600],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedCountry?.phoneCode ?? "+",
                          style: inputTextStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          style: inputTextStyle,
                          decoration: _buildInputDecoration("Phone Number"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: inputTextStyle,
                maxLines: 2,
                decoration: _buildInputDecoration("Address"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address cannot be empty';
                  }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referralNumberController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Referral Code", helperText: "Optional"),
              ),


              if(identityCode=='0061')
                isCurrencyLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDropdown(
                  label: "Currency",
                  items: currencies.map<DropdownMenuItem<String>>((currency) {
                    return DropdownMenuItem<String>(
                      value: currency["code"],
                      child: Text(
                        currency["name"],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  value: selectedCurrencyId.isNotEmpty ? selectedCurrencyId : null,
                  onChanged: (value) {
                    setState(() {
                      selectedCurrencyId = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),


              if(identityCode=="0075")
                  const SizedBox(height: 16),
                  TextFormField(
                  controller: pf_number,
                  style: inputTextStyle,
                  decoration: _buildInputDecoration("PF Number"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'PF Number cannot be empty';
                    }
                    return null; // Return null if valid
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: ledger_number,
                  style: inputTextStyle,
                  decoration: _buildInputDecoration("Ledger Number"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ledger Number cannot be empty';
                    }
                    return null; // Return null if valid
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: ippis_number,
                  style: inputTextStyle,
                  decoration: _buildInputDecoration("IPPIS Number"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'IPPIS Number cannot be empty';
                    }
                    return null; // Return null if valid
                  },
                ),


            ]),

            // Security Section
            _buildFormSection("Security", [
              _buildPasswordField(
                controller: _passwordController,
                label: "Password",
                obscureText: _isPasswordObscured,
                onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                validator: (value) => value != null && value.length < 6 ? "Minimum 6 characters required" : null,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                obscureText: _isConfirmPasswordObscured,
                onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                validator: (value) => value != _passwordController.text ? "Passwords don't match" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _transactionPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: _isTransactionPinObscured,
                style: inputTextStyle,
                decoration: _buildInputDecoration(
                  "Transaction PIN",
                  helperText: "4-digit PIN for transactions",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isTransactionPinObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textColor.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isTransactionPinObscured = !_isTransactionPinObscured),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 4) return "Enter a 4-digit PIN";
                  if (int.tryParse(value) == null) return "Only digits allowed";
                  return null;
                },
              ),
            ]),

            // Terms and Conditions
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                      activeColor: primaryColor,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                        });
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _isTermsAccepted
                    ? const LinearGradient(
                  colors: [primaryColor, Color(0xFFFF8A00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: _isTermsAccepted ? null : borderColor,
                boxShadow: _isTermsAccepted
                    ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isTermsAccepted
                    ? () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final controller = Provider.of<NinVerificationController>(context, listen: false);

                    if(identityCode=="0075"){
                      await controller.submitRegistration(
                        idType: _selectedIdType!,
                        idNumber: _idNumberController.text.trim(),
                        firstName: _firstNameController.text.trim(),
                        middleName: _middleNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        email: _emailController.text.trim(),
                        username: _usernameController.text.trim(),
                        telephone: _telephoneController.text.trim(),
                        address: _addressController.text.trim(),
                        countryId: _selectedCountry!.id,
                        telPrefix: _selectedCountry!.phoneCode,
                        gender: gender,
                        password: _passwordController.text.trim(),
                        referral: _referralNumberController.text.trim(),
                          ledger_number:ledger_number.text.trim(),
                          ippis_number:ippis_number.text.trim(),
                          pf_number:pf_number.text.trim(),
                        transactionPin: int.parse(_transactionPinController.text
                            .trim()),
                        dateOfBirth: _dobController.text.trim(),
                        should_create_virtual_wallet: should_create_virtual_wallet,
                        identityCode:identityCode,
                      );
                    }else {
                      await controller.submitRegistration(
                        idType: _selectedIdType!,
                        idNumber: _idNumberController.text.trim(),
                        firstName: _firstNameController.text.trim(),
                        middleName: _middleNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        email: _emailController.text.trim(),
                        username: _usernameController.text.trim(),
                        telephone: _telephoneController.text.trim(),
                        address: _addressController.text.trim(),
                        countryId: _selectedCountry!.id,
                        telPrefix: _selectedCountry!.phoneCode,
                        gender: gender,
                        password: _passwordController.text.trim(),
                        referral: _referralNumberController.text.trim(),
                        transactionPin: int.parse(_transactionPinController.text
                            .trim()),
                        dateOfBirth: _dobController.text.trim(),
                        should_create_virtual_wallet: should_create_virtual_wallet,
                        identityCode:identityCode,
                        currency_code: selectedCurrencyId,

                      );
                    }
                    if (controller.submissionMessage.contains("successful")) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Awaiting email verification"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      _resetFormState();
                      Navigator.pushReplacementNamed(context, '/reg_success');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(controller.submissionMessage),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                }
                    : null,
                child: ninController.isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Create Account',
                  style: TextStyle(
                    color: _isTermsAccepted ? Colors.white : textColor.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  void _showCountryBottomSheet(BuildContext context) {
    // Reset filtered countries to show all initially
    _filteredCountries = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      _filteredCountries = _countries
                          .where((country) => country.name
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),

              SizedBox(height: 16),

              // Countries list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final isSelected = _selectedCountry?.name == country.name;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            country.phoneCode,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      title: Text(country.name),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullForm_no_KYC(No_KYC_Controller no_kyc_controller) {
    // Professional styling constants
    const primaryColor = Color(0xFFEB6D00);
    const textColor = Color(0xFF2D3748);
    const borderColor = Color(0xFFE2E8F0);
    const focusedBorderColor = Color(0xFFEB6D00);
    const backgroundColor = Color(0xFFFAFAFA);
    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final orgData = orgController.organizationData?['data'] ?? {};
    final identityCode = orgData['org_identity_code'] ?? '';

    const labelStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    const inputTextStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );

    OutlineInputBorder _buildInputBorder(Color color, {double width = 1.0}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon, String? helperText}) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        helperText: helperText,
        helperStyle: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _buildInputBorder(borderColor),
        focusedBorder: _buildInputBorder(focusedBorderColor, width: 2.0),
        errorBorder: _buildInputBorder(Colors.red.shade300),
        focusedErrorBorder: _buildInputBorder(Colors.red.shade400, width: 2.0),
        suffixIcon: suffixIcon,
      );
    }

    Widget _buildFormSection(String title, List<Widget> children) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }
    Widget _buildDropdown({
      required String label,
      required List<DropdownMenuItem<String>> items,
      String? value,
      void Function(String?)? onChanged,
    }) {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: items,
        value: value,
        onChanged: onChanged,
      );
    }
    Widget _buildPasswordField({
      required TextEditingController controller,
      required String label,
      required bool obscureText,
      required VoidCallback onToggleVisibility,
      String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: inputTextStyle,
        decoration: _buildInputDecoration(
          label,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textColor.withOpacity(0.6),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
        validator: validator,
      );
    }

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _buildFormSection("Personal Information", [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      style: inputTextStyle,
                      decoration: _buildInputDecoration("First Name"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _middleNameController,
                      style: inputTextStyle,
                      decoration: _buildInputDecoration("Middle Name"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Last Name"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration("Gender"),
                value: _selectedGender,
                style: inputTextStyle,
                items: ['male', 'female'].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(
                      gender.toUpperCase(),
                      style: inputTextStyle,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                style: inputTextStyle,
                decoration: _buildInputDecoration(
                  "Date of Birth",
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                onTap: () async {
                  DateTime initialDate;
                  try {
                    initialDate = DateTime.parse(_dobController.text);
                  } catch (_) {
                    initialDate = DateTime(2000);
                  }

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: textColor,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    _dobController.text = picked.toIso8601String().split('T').first;
                  }
                },
              ),
            ]),

            // Account Information Section
            _buildFormSection("Account Information", [

              if(_selectedIdType=="existing-account")

                  TextFormField(
                        controller: _azanumberController,
                        keyboardType: TextInputType.phone,

                        style: inputTextStyle,
                        decoration: _buildInputDecoration("Account Number"),
                      ),
                  const SizedBox(height: 16),


              if(_selectedIdType=="existing-account")
                    TextFormField(
                      controller: bvnController,
                      keyboardType: TextInputType.phone,

                      style: inputTextStyle,
                      decoration: _buildInputDecoration("BVN"),
                    ),
                    const SizedBox(height: 16),


              if(identityCode=='0061')
                  isCurrencyLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDropdown(
                    label: "Currency",
                    items: currencies.map<DropdownMenuItem<String>>((currency) {
                      return DropdownMenuItem<String>(
                        value: currency["code"],
                        child: Text(
                          currency["name"],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    value: selectedCurrencyId.isNotEmpty ? selectedCurrencyId : null,
                    onChanged: (value) {
                      setState(() {
                        selectedCurrencyId = value!;
                      });
                    },
                  ),
                 const SizedBox(height: 16),



              TextFormField(
                controller: _usernameController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Username"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: inputTextStyle,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("Email Address"),
              ),
              const SizedBox(height: 16),
              _isLoadingCountries
                  ? CircularProgressIndicator()
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showCountryBottomSheet(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCountry != null
                                ? "${_selectedCountry!.name} (${_selectedCountry!.phoneCode})"
                                : "Select Country",
                            style: TextStyle(
                              color: _selectedCountry != null ? Colors.black : Colors.grey[600],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedCountry?.phoneCode ?? "+",
                          style: inputTextStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          style: inputTextStyle,
                          decoration: _buildInputDecoration("Phone Number"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: inputTextStyle,
                maxLines: 2,
                decoration: _buildInputDecoration("Address"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address cannot be empty';
                  }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referralNumberController,
                style: inputTextStyle,
                decoration: _buildInputDecoration("Referral Code", helperText: "Optional"),
              ),
            ]),

            // Security Section
            _buildFormSection("Security", [
              _buildPasswordField(
                controller: _passwordController,
                label: "Password",
                obscureText: _isPasswordObscured,
                onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                validator: (value) => value != null && value.length < 6 ? "Minimum 6 characters required" : null,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                obscureText: _isConfirmPasswordObscured,
                onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                validator: (value) => value != _passwordController.text ? "Passwords don't match" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _transactionPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: _isTransactionPinObscured,
                style: inputTextStyle,
                decoration: _buildInputDecoration(
                  "Transaction PIN",
                  helperText: "4-digit PIN for transactions",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isTransactionPinObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textColor.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isTransactionPinObscured = !_isTransactionPinObscured),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 4) return "Enter a 4-digit PIN";
                  if (int.tryParse(value) == null) return "Only digits allowed";
                  return null;
                },
              ),
            ]),

            // Terms and Conditions
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                      activeColor: primaryColor,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),



                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                        });
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _isTermsAccepted
                    ? const LinearGradient(
                  colors: [primaryColor, Color(0xFFFF8A00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: _isTermsAccepted ? null : borderColor,
                boxShadow: _isTermsAccepted
                    ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isTermsAccepted
                    ? () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Additional validation for required fields
                    if (_selectedGender == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Please select a gender"),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    await no_kyc_controller.submitRegistration(
                      firstName: _firstNameController.text.trim(),
                      middleName: _middleNameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                      identityCode:identityCode,

                      email: _emailController.text.trim(),
                      username: _usernameController.text.trim(),
                      azanumber:_azanumberController.text.trim(),
                      bvn:bvnController.text.trim(),
                      telephone: _telephoneController.text.trim(),
                      countryId: _selectedCountry!.id,
                      telPrefix: _selectedCountry!.phoneCode,
                      address: _addressController.text.trim(),
                      gender: _selectedGender!,
                      existing_account: _selectedIdType=="existing-account"?true:false,
                      password: _passwordController.text.trim(),
                      referral: _referralNumberController.text.trim(),
                      transactionPin: int.parse(_transactionPinController.text.trim()),
                      dateOfBirth: _dobController.text.trim(),

                      currency_code: selectedCurrencyId,

                      should_create_virtual_wallet: should_create_virtual_wallet,
                    );

                    if (no_kyc_controller.submissionMessage.contains("successful")) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Awaiting email verification"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2));
                      _resetFormState();
                      Navigator.pushReplacementNamed(context, '/reg_success');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(no_kyc_controller.submissionMessage),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                }
                    : null,
                child: no_kyc_controller.isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Create Account',
                  style: TextStyle(
                    color: _isTermsAccepted ? Colors.white : textColor.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


}


























/*
[04:28, 30/06/2025] Wired Banking Technologies: /* WALLET CREATION OPTIONS */
  /* Optional | Defaults to false if not set */
"should_create_virtual_wallet": true,
"virtual_wallet_type": "virtual-account",    /**
                                              * Optional | Defaults to organization's standard virtual account type
                                              * Possible values: virtual-account | internal-account | crypto-account
                                              **/

"virtual_wallet_currency_code": "USDT",     /**
                                             * Optional | Defaults to organization's primary currency
                                             * For crypto-account: USDT | USDC | BTC
                                             * For virtual-account: NGN | others as defined by the organization
                                             * For internal-account: USD | others as defined by the organization
                                             **/

"virtual_wallet_currency_network": "ERC20",     /**
                                                 * Optional | Only relevant for crypto-account creation
                                                 * For USDT: TRC20 | ERC20
                                                 * For USDC: POL
                                                 * For BTC: ---
                                                 * Defaults to organization's preset crypto network if not provided
                                                 **/




 */
