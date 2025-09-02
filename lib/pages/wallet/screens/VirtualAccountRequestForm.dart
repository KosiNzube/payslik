import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';

import '../../../models/Country.dart';

class VirtualAccountRequestForm extends StatefulWidget {
  final String code;

  const VirtualAccountRequestForm({super.key, required this.code});

  @override
  _VirtualAccountRequestFormState createState() => _VirtualAccountRequestFormState();
}

class _VirtualAccountRequestFormState extends State<VirtualAccountRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controllers for text fields
  final _taxIdentityNumberController = TextEditingController();
  final _identificationNumberController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String? _selectedAD;

  // Dropdown values
  String? _selectedSourceOfIncome;
  String? _selectedEmploymentStatus;
  String? _selectedTaxCountry;
  String? _selectedIdType;
  String? _selectedIdCountry;
  String? _selectedOccupation;

  // Date values
  DateTime? _idIssuedDate;
  DateTime? _idExpirationDate;

  // File values
  File? _bankStatementFile;
  File? _identificationFile;
  File? _utilityBillFile;

  // UI State
  bool _isLoading = false;
  int _currentStep = 0;
  Color _primaryColor = Colors.blue;
  Color _secondaryColor = Colors.blueAccent;
  Color _tertiaryColor = Colors.white;
  String? _logoUrl;

  // Dropdown options
  final List<String> _sourceOfIncomeOptions = [
    'salary', 'business', 'investment', 'inheritance','real_estate','pension','grant','gift','crypto', 'other'
  ];
  final List<String> _sourceOfAD = [
    'Payroll processing',
    'Supplier payments',
    'Customer refunds',
    'Subscription billing',
    'Loan disbursements',
    'Loan repayments',
    'Tax remittance',
    'Utility bill settlements',
    'Marketplace seller payouts',
    'Freelance contractor payments',
    'Tuition fee collection',
    'Membership fee collection',
    'Charity donations',
  ];


  final List<String> _employmentStatusOptions = [
    'employed', 'self_employed', 'unemployed', 'student',
    'retired', 'homemaker', 'freelancer', 'other'
  ];

  final List<String> occupation = [
    'Software Engineer', 'Teacher', 'Nurse', 'Civil Engineer', 'Accountant',
    'Graphic Designer','Electrician','Lawyer','Chef','Data Analyst',
    'Pharmacist','Architect','Pilot','Plumber','Photographer',
    'Mechanical Engineer','Doctor','Journalist','Web Developer',
    'Project Manager','Others'
  ];


  final List<String> _idTypes = [
    'passport', 'drivers_license', 'nationalId', 'voters_card','idCard'
  ];

  List<Country> _countries = [];
  List<Country> _filteredCountries = [];
  Country? _selectedCountry;
  bool _isLoadingCountries = true;


  @override
  void initState() {
    super.initState();
    _loadPrimaryColorAndLogo();
    _loadCountries();

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

  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'];
      final secondaryColorHex = data['customized-app-secondary-color'];
      final tertiaryColorHex = data['customized-app-tertiary-color'] ?? '#ffffff';
      final logoUrl = data['customized-app-logo-url'];

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
        _tertiaryColor = Color(int.parse(tertiaryColorHex.replaceAll('#', '0xFF')));
        _logoUrl = logoUrl;
      });
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString('appId') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    return {
      'AppID': appId,
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _pickFile(String fileType) async {
    final Map<String, List<String>> allowedExtensions = {
      'bank_statement': ['pdf'],
      'identification': ['jpg', 'jpeg', 'png'],
      'utility_bill': ['jpg', 'jpeg', 'png'],
    };

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions[fileType],
    );

    if (result != null) {
      setState(() {
        switch (fileType) {
          case 'bank_statement':
            _bankStatementFile = File(result.files.single.path!);
            break;
          case 'identification':
            _identificationFile = File(result.files.single.path!);
            break;
          case 'utility_bill':
            _utilityBillFile = File(result.files.single.path!);
            break;
        }
      });
    }
  }

  Future<void> _selectDate(String dateType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: _tertiaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (dateType == 'issued') {
          _idIssuedDate = picked;
        } else {
          _idExpirationDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator ?? (value) => value == null ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
        validator: validator ?? (value) => value?.isEmpty ?? true ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildFilePickerField({
    required String label,
    required File? file,
    required String fileType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () => _pickFile(fileType),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
                color: file != null ? _primaryColor.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    file != null ? Icons.check_circle : Icons.upload_file,
                    color: file != null ? _primaryColor : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file != null
                          ? 'File selected: ${file.path.split('/').last}'
                          :fileType=="bank_statement"? "Tap to select file (PDF)":"Tap to select file (PDF, PNG, JPEG)",
                      style: TextStyle(
                        color: file != null ? _primaryColor : Colors.grey[600],
                        fontWeight: file != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required String dateType,
    String? Function(DateTime?)? validator, // Add validator parameter
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: FormField<DateTime>(
        initialValue: date,
        validator: validator ?? (value) {
          if (value == null) {
            return 'Please select a date';
          }
          return null;
        },
        builder: (FormFieldState<DateTime> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDate(dateType),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    errorBorder: field.hasError
                        ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    )
                        : null,
                    focusedErrorBorder: field.hasError
                        ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date != null ? _formatDate(date) : 'Select date',
                        style: TextStyle(
                          color: date != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      Icon(Icons.calendar_today, color: _primaryColor),
                    ],
                  ),
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_bankStatementFile == null || _identificationFile == null || _utilityBillFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_idIssuedDate == null || _idExpirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both issued and expiration dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ConstApi.baseUrl}${ConstApi.basePath}/cross-border-payment-mgt/virtual-account-requests');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(headers);

      request.fields.addAll({
        'virtual_account_currency_code': widget.code!,
        'account_designations':_selectedAD!,
        'source_of_income': _selectedSourceOfIncome!,
        'occupation': _selectedOccupation!,
        'employment_status': _selectedEmploymentStatus!,
        'means_of_identification_type': _selectedIdType!,
        'means_of_identification_number': _identificationNumberController.text,
        'means_of_identification_issued_country_code': _selectedIdCountry!,
        'means_of_identification_issued_date': _formatDate(_idIssuedDate),
        'means_of_identification_expiration_date': _formatDate(_idExpirationDate),
        'address_house_number': _houseNumberController.text,
        'address_street_name': _streetNameController.text,
        'address_city_name': _cityController.text,

        'address_state_name': _stateController.text,
        'address_zip_code': _zipCodeController.text,
      });

      if (_selectedIdCountry == 'US') {
        request.fields.addAll({
          'tax_identity_country': "US",
          'tax_identity_number': _taxIdentityNumberController.text,
        });
      }

      request.files.add(
        await http.MultipartFile.fromPath('bank_statement_document', _bankStatementFile!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('means_of_Identification_document', _identificationFile!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('utility_bill_document', _utilityBillFile!.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Virtual account request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${errorData['message'] ?? 'Something went wrong'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the total number of steps
    final int _totalSteps = _selectedIdCountry == 'US' ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Account Request('+widget.code+")", style: TextStyle(color: Colors.black)),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    if (_selectedIdCountry == 'US') _buildStep3TaxInfo(),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor),
                          foregroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Previous'),
                      ),
                    ),
                  SizedBox(width: _currentStep > 0 ? 10 : 0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_currentStep < _totalSteps - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _submitForm();
                          }
                        }
                      },
                      style:  ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentStep < _totalSteps - 1 ? 'Next' : 'Send Request',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                            country.code,
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
                          _selectedIdCountry=country.code;
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

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1 of ${_selectedIdCountry == 'US' ? 3 : 2}: Personal & Identification Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),

          _buildDropdownField(
            label: 'Account Designations',
            value: _selectedAD,
            options: _sourceOfAD,
            onChanged: (value) => setState(() => _selectedAD = value),
          ),

          _buildDropdownField(
            label: 'Source of Income',
            value: _selectedSourceOfIncome,
            options: _sourceOfIncomeOptions,
            onChanged: (value) => setState(() => _selectedSourceOfIncome = value),
          ),
          _buildDropdownField(
            label: 'Occupation',
            value: _selectedOccupation,
            options: occupation,
            onChanged: (value) => setState(() => _selectedOccupation = value),
          ),
          _buildDropdownField(
            label: 'Employment Status',
            value: _selectedEmploymentStatus,
            options: _employmentStatusOptions,
            onChanged: (value) => setState(() => _selectedEmploymentStatus = value),
          ),
          SizedBox(height: 24),
          Text(
            'Identification Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),
          _buildDropdownField(
            label: 'Identification Type',
            value: _selectedIdType,
            options: _idTypes,
            onChanged: (value) => setState(() => _selectedIdType = value),
          ),
          _buildTextFormField(
            label: 'Identification Number',
            controller: _identificationNumberController,
          ),
          const SizedBox(height: 5),
          _isLoadingCountries
              ?   CircularProgressIndicator(strokeWidth: 1.5,color: Colors.black,)
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
                            ? "${_selectedCountry!.name} (${_selectedCountry!.code})"
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

            ],
          ),

          const SizedBox(height: 16),
          _buildDateField(
            label: 'Issued Date',
            date: _idIssuedDate,
            dateType: 'issued',
            validator: (date) {
              if (date == null) {
                return 'Start date is required';
              }
              return null;
            },
          ),
          _buildDateField(
            label: 'Expiration Date',
            date: _idExpirationDate,
            dateType: 'expiration',
            validator: (date) {
              if (date == null) {
                return 'Start date is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 of ${_selectedIdCountry == 'US' ? 3 : 2}: Address & Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Address Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),
          _buildTextFormField(
            label: 'House Number',
            controller: _houseNumberController,
          ),
          _buildTextFormField(
            label: 'Street Name',
            controller: _streetNameController,
          ),
          _buildTextFormField(
            label: 'City',
            controller: _cityController,
          ),
          _buildTextFormField(
            label: 'State/Province',
            controller: _stateController,
          ),
          _buildTextFormField(
            label: 'ZIP/Postal Code',
            controller: _zipCodeController,
          ),
          SizedBox(height: 24),
          Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),
          _buildFilePickerField(
            label: 'Bank Statement Document *',
            file: _bankStatementFile,
            fileType: 'bank_statement',
          ),
          _buildFilePickerField(
            label: 'Identification Document *',
            file: _identificationFile,
            fileType: 'identification',
          ),
          _buildFilePickerField(
            label: 'Utility Bill Document *',
            file: _utilityBillFile,
            fileType: 'utility_bill',
          ),
        ],
      ),
    );
  }

  Widget _buildStep3TaxInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3 of 3: Tax Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 16),

          _buildTextFormField(
            label: 'Tax Identity Number',
            controller: _taxIdentityNumberController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taxIdentityNumberController.dispose();
    _identificationNumberController.dispose();
    _houseNumberController.dispose();
    _streetNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

// Helper class for API constants
class ConstApi {
  static const String baseUrl = 'https://app.gobeller.cc';
  static const String basePath = '/api/v1';

  /// Dynamically get headers with AppID from SharedPreferences
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString('appId') ?? '';

    return {
      'AppID': appId,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}