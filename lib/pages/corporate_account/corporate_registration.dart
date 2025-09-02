import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controller/CacVerificationController.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

// Keep imports the same
class CorporateAccountRegistrationPage extends StatefulWidget {
  const CorporateAccountRegistrationPage({Key? key}) : super(key: key);

  @override
  _CorporateAccountRegistrationPageState createState() =>
      _CorporateAccountRegistrationPageState();
}

class _CorporateAccountRegistrationPageState
    extends State<CorporateAccountRegistrationPage> {
  final GlobalKey<FormState> _initialFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();

  final TextEditingController _corporateIdNumberController = TextEditingController();  // This is for Corporate Business ID
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

// New controllers for the new fields
  final TextEditingController _corporateBusinessIdController = TextEditingController(); // Corporate Business ID
  final TextEditingController _natureOfBusinessController = TextEditingController();  // Nature of Corporate Business


  String? selectedCorporateIdType;




  final _picker = ImagePicker();
  bool isLoading = false;
  int currentStep = 0;
  bool _isPickingFile = false;
  bool hasStartedRegistration = false; // ✅ Add this line

  String? selectedIdType;

  File? _businessCertificateFile;
  File? _cacStatusReport;
  File? _govIssuedId;
  File? _proofOfAddress;
  File? _natureOfBusiness;
  File? _cacMoaFile;
  File? _recentPassportFile;

  Future<void> _pickFile(String fileKey) async {
    FilePickerResult? result;

    // if (fileKey == 'passport') {
    //   // For passport: only allow image files
    //   result = await FilePicker.platform.pickFiles(
    //     type: FileType.image,
    //   );
    // } else {
    //   // For all other files: only allow PDFs
    //   result = await FilePicker.platform.pickFiles(
    //     type: FileType.custom,
    //     allowedExtensions: ['pdf'],
    //   );
    // }
    // result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf',''],
    // );
    result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        switch (fileKey) {
          case 'businessCertificate':
            _businessCertificateFile = file;
            break;
          case 'cacStatusReport':
            _cacStatusReport = file;
            break;
          case 'govIssuedId':
            _govIssuedId = file;
            break;
          case 'proofOfAddress':
            _proofOfAddress = file;
            break;
          case 'natureOfBusiness':
            _natureOfBusiness = file;
            break;
          case 'cacMoa':
            _cacMoaFile = file;
            break;
          case 'passport':
            _recentPassportFile = file;
            break;
        }
      });
    }
  }



  Future<void> _verifyCorporateId(BuildContext context) async {
    final controller = Provider.of<CacVerificationController>(context, listen: false);
    await controller.verifyCacNumber(
      corporateIdType: selectedCorporateIdType!,
      corporateIdNumber: _corporateIdNumberController.text.trim(),
      context: context,
    );

    // Automatically proceed to next step if verification is successful
    if (controller.companyDetails != null) {
      setState(() {
        currentStep = 1;
      });
    }
  }


  void _submitForm(BuildContext context) async {
    if (!(_registrationFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulated API

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Corporate Account Registration Successful!')),
    );
    _registrationFormKey.currentState?.reset();
  }

  @override
  void dispose() {
    _corporateIdNumberController.dispose();
    _phoneNumberController.dispose();
    _tinController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    _corporateBusinessIdController.dispose();  // Dispose of new controller
    _natureOfBusinessController.dispose();    // Dispose of new controller
    super.dispose();
  }
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacVerificationController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Corporate Account Registration')),
        body: Consumer<CacVerificationController>(
          builder: (context, cacController, _) {
            final isVerified = cacController.companyDetails != null;

            return Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (currentStep + 1) / 4,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFFEB6D00),
                ),
                const SizedBox(height: 8),
                // Add this below the LinearProgressIndicator and SizedBox(height: 8)

                if (!hasStartedRegistration)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child:
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.business_center, size: 28, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Full Registered business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Spacer(),
                                Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'This is a business structure for private companies that combines features of a partnership and a corporation.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            const Text('Document Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            _buildBulletPoint('Certificate of Incorporation.'),
                            _buildBulletPoint('Memorandum and Articles of Association.'),
                            _buildBulletPoint('Particulars of Directors'),
                            _buildBulletPoint('Particulars of Shareholders'),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                // Navigate to sample document screen or show dialog
                              },
                              child: const Text(
                                'Tap here to view document sample.',
                                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(Icons.info, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "The CAC number for a Limited Liability Company begins with 'RC'.",
                                      style: TextStyle(fontSize: 13.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    hasStartedRegistration = true;
                                    currentStep = 0;
                                  });
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Start Registration'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEB6D00),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ) else


                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _registrationFormKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (currentStep == 0) ...[
                              const Text('Corporate ID Type'),
                              DropdownButtonFormField<String>(
                                value: selectedCorporateIdType,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'cac-bn-number',
                                    child: Text('CAC BN Number'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cac-rc-number',
                                    child: Text('CAC RC Number'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cac-it-number',
                                    child: Text('CAC IT Number'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedCorporateIdType = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Select Corporate ID Type',
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text('Corporate ID Number'),
                              TextFormField(
                                controller: _corporateIdNumberController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Enter Corporate ID Number',
                                ),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green, // ✅ Green background
                                  ),
                                  onPressed: selectedCorporateIdType == null || cacController.isVerifying
                                      ? null
                                      : () async {
                                    await _verifyCorporateId(context);
                                    if (cacController.companyDetails != null) {
                                      setState(() => currentStep = 1);
                                    }
                                  },
                                  child: cacController.isVerifying
                                      ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                      : const Text('Verify CAC'),
                                ),
                              ),

                              const SizedBox(height: 16),

                              if (isVerified)
                                Text(
                                  "✅ Verified: ${cacController.companyDetails?['company_name'] ?? ''}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                            ] else if (currentStep == 1) ...[
                              const Text('Select Identity Type'),
                              DropdownButtonFormField<String>(
                                value: selectedIdType,
                                items: const [
                                  DropdownMenuItem(value: 'nin', child: Text('NIN')),
                                  DropdownMenuItem(value: 'bvn', child: Text('BVN')),
                                  DropdownMenuItem(value: 'passport-number', child: Text('Passport Number')),
                                ],
                                onChanged: (value) {
                                  setState(() => selectedIdType = value);
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Select Identity Type',
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (selectedIdType != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: selectedIdType == 'nin'
                                            ? _ninController
                                            : selectedIdType == 'bvn'
                                            ? _bvnController
                                            : _passportController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          labelText: 'Enter ${selectedIdType!.toUpperCase()}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    cacController.ninData != null
                                        ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                                        : ElevatedButton(
                                      onPressed: cacController.isVerifying
                                          ? null
                                          : () async {
                                        final idNumber = (selectedIdType == 'nin'
                                            ? _ninController.text
                                            : selectedIdType == 'bvn'
                                            ? _bvnController.text
                                            : _passportController.text)
                                            .trim();
                                        if (idNumber.isEmpty) return;
                                        await cacController.verifyId(idNumber, selectedIdType!);

                                        final data = cacController.ninData;
                                        if (data != null) {
                                          _firstNameController.text = data['first_name'] ?? '';
                                          _middleNameController.text = data['middle_name'] ?? '';
                                          _lastNameController.text = data['last_name'] ?? '';
                                          _emailController.text = data['email'] ?? '';
                                          _phoneNumberController.text =
                                              data['phone_number1'] ?? data['phone_number2'] ?? '';
                                          _dobController.text = data['date_of_birth'] ?? '';
                                          _genderController.text = data['gender'] ?? '';
                                          _addressController.text = data['physical_address'] ?? '';
                                        }
                                      },
                                      child: cacController.isVerifying
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Text("Verify ID"),
                                    )
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Form Fields Pre-filled from ID
                              TextFormField(
                                controller: _tinController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'TIN number *',
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),

                              // New input for Corporate Business ID (corporateBusinessIdValue)
                              TextFormField(
                                controller: _corporateBusinessIdController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Corporate Business ID *',
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),

                              // New input for Nature of Corporate Business (natureOfCorporateBusiness)
                              TextFormField(
                                controller: _natureOfBusinessController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Nature of Corporate Business *',
                                ),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => currentStep = 0),
                                    child: const Text("Back"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_registrationFormKey.currentState?.validate() ?? false) {
                                        setState(() => currentStep = 2);
                                      }
                                    },
                                    child: const Text("Next"),
                                  ),
                                ],
                              ),
                            ]
                            else if (currentStep == 2) ...[
                                ElevatedButton(
                                  onPressed: () => _pickFile('businessCertificate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _businessCertificateFile == null ? null : Colors.green,
                                  ),
                                  child: Text(_businessCertificateFile == null
                                      ? 'Upload Business Certificate'
                                      : 'Business Certificate Selected'),
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () => _pickFile('cacStatusReport'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cacStatusReport == null ? null : Colors.green,
                                  ),
                                  child: Text(_cacStatusReport == null
                                      ? 'Upload CAC Status Report'
                                      : 'CAC Status Report Selected'),
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () => _pickFile('govIssuedId'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _govIssuedId == null ? null : Colors.green,
                                  ),
                                  child: Text(_govIssuedId == null
                                      ? 'Upload Government Issued ID'
                                      : 'Government Issued ID Selected'),
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () => _pickFile('proofOfAddress'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _proofOfAddress == null ? null : Colors.green,
                                  ),
                                  child: Text(_proofOfAddress == null
                                      ? 'Upload Proof Of Address'
                                      : 'Proof Of Address Selected'),
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () => _pickFile('cacMoa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cacMoaFile == null ? null : Colors.green,
                                  ),
                                  child: Text(_cacMoaFile == null
                                      ? 'Upload CAC MOA Document'
                                      : 'MOA Selected'),
                                ),
                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: () => _pickFile('passport'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _recentPassportFile == null ? null : Colors.green,
                                  ),
                                  child: Text(_recentPassportFile == null
                                      ? 'Upload Passport'
                                      : 'Passport Selected'),
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => setState(() => currentStep = 1),
                                      child: const Text("Back"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_registrationFormKey.currentState?.validate() ?? false) {
                                          setState(() => currentStep = 3); // Move to summary
                                        }
                                      },
                                      child: const Text("Review Summary"),
                                    ),
                                  ],
                                ),
                              ]

                              else if (currentStep == 3) ...[
                              const Text(
                                "Summary of Provided Information",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 16),

                              _summaryRow("Corporate ID Type", selectedCorporateIdType ?? ''),
                              _summaryRow("Corporate ID Number", _corporateIdNumberController.text),
                              _summaryRow("Company Name", cacController.companyDetails?['company_name'] ?? ''),
                              _summaryRow("Business ID Number", _corporateBusinessIdController.text),
                              _summaryRow("Nature of Corporate Business", _natureOfBusinessController.text),


                              const Divider(height: 32),

                              _summaryRow("ID Type", selectedIdType?.toUpperCase() ?? ''),
                              _summaryRow(
                                "${selectedIdType?.toUpperCase()} Number",
                                selectedIdType == 'nin'
                                    ? _ninController.text
                                    : selectedIdType == 'bvn'
                                    ? _bvnController.text
                                    : _passportController.text,
                              ),

                              _summaryRow("First Name", _firstNameController.text),
                              _summaryRow("Middle Name", _middleNameController.text),
                              _summaryRow("Last Name", _lastNameController.text),
                              _summaryRow("Username", _usernameController.text),
                              _summaryRow("Email", _emailController.text),
                              _summaryRow("Phone", _phoneNumberController.text),
                              _summaryRow("Gender", _genderController.text),
                              _summaryRow("Date of Birth", _dobController.text),
                              _summaryRow("Address", _addressController.text),

                              const Divider(height: 32),

                              _summaryRow("Business Certificate", _businessCertificateFile != null ? p.basename(_businessCertificateFile!.path) : 'Not uploaded'),
                              _summaryRow("CAC Status Report", _cacStatusReport != null ? p.basename(_cacStatusReport!.path) : 'Not uploaded'),
                              _summaryRow("Govt Issued ID", _govIssuedId != null ? p.basename(_govIssuedId!.path) : 'Not uploaded'),
                              _summaryRow("Proof of Address", _proofOfAddress != null ? p.basename(_proofOfAddress!.path) : 'Not uploaded'),
                              _summaryRow("MOA", _cacMoaFile != null ? p.basename(_cacMoaFile!.path) : 'Not uploaded'),
                              _summaryRow("Passport", _recentPassportFile != null ? p.basename(_recentPassportFile!.path) : 'Not uploaded'),

                              const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => setState(() => currentStep = 2),
                                        child: const Text("Back"),
                                      ),
                                      isLoading
                                          ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : ElevatedButton(
                                        onPressed: () async {
                                          if ([
                                            _businessCertificateFile,
                                            _cacMoaFile,
                                            _cacStatusReport,
                                            _recentPassportFile,
                                            _govIssuedId,
                                            _proofOfAddress
                                          ].any((file) => file == null)) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("📎 Please upload all required documents."),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => isLoading = true);

                                          final success = await Provider.of<CacVerificationController>(context, listen: false)
                                              .registerCorporateBusiness(
                                            corporateBusinessIdType: selectedCorporateIdType!,
                                            corporateBusinessIdValue: _corporateIdNumberController.text.trim(),
                                            natureOfCorporateBusiness: _natureOfBusinessController.text.trim(),
                                            corporateBusinessTinNumber: _tinController.text.trim(),
                                            corporateOwnerIdType: selectedIdType ?? '',
                                            corporateOwnerIdValue: selectedIdType == 'nin'
                                                ? _ninController.text.trim()
                                                : selectedIdType == 'bvn'
                                                ? _bvnController.text.trim()
                                                : _passportController.text.trim(),
                                            businessCertificate: _businessCertificateFile!,
                                            cacMoaDocument: _cacMoaFile!,
                                            cacStatusReport: _cacStatusReport!,
                                            recentPassportPhotograph: _recentPassportFile!,
                                            governmentIssuedId: _govIssuedId!,
                                            proofOfAddress: _proofOfAddress!,
                                            context: context,
                                            corporateIdValue: _corporateIdNumberController.text.trim(),
                                          );

                                          setState(() => isLoading = false);

                                          if (success) {
                                            Navigator.pushReplacementNamed(context, '/corporate_account');
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("❌ Registration failed. Please try again."),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },

                                        child: const Text("Finish"),
                                      ),
                                    ],
                                  ),
                                ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value.isNotEmpty ? value : '—'),
          ),
        ],
      ),
    );
  }


}

