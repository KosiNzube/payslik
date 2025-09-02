import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:gobeller/pages/navigation/base_layout.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/create_wallet_controller.dart';
import '../../controller/kyc_controller.dart';
import '../../controller/profileControllers.dart';
import '../../utils/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

import '../login/login_page.dart';




class OtpVerificationPage extends StatefulWidget {
  final String username;

  const OtpVerificationPage({super.key, required this.username});



  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialLoading = true;
  File? _capturedImage;
  bool display_facial_recognition_menu=false;
  bool display_otp_verification_option=false;
  bool display_ussd_otp_verification_option=false;
  String? _ussdCode;
  late Future<Map<String, dynamic>?> _userProfileFuture;

  bool faceVerify=false;



  Future<void> _loadOTPOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        final menuItems = orgData['data']?['customized_app_displayable_menu_items'];

        setState(() {
          display_facial_recognition_menu=orgData['data']?['customized_app_displayable_menu_items']?['display-facial-recognition-menu'] ?? false;

          display_otp_verification_option=orgData['data']?['customized_app_displayable_menu_items']?['display-otp-verification-option'] ?? false;

          display_ussd_otp_verification_option=orgData['data']?['customized_app_displayable_menu_items']?['display-ussd-otp-verification-option'] ?? false;

        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          display_facial_recognition_menu=false;

          display_otp_verification_option=false;

          display_ussd_otp_verification_option=false;
        });
      }
    }
  }



  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to continue')),
      );
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _userProfileFuture =  ProfileController.fetchUserProfile().then((profile) async {
      await _loadOTPOptions();
      await _requestInitialOtp();
      await _loadUssdCode();

      //  _loadAds();

      if (profile != null) {

        if (profile!['first_kyc_verification'] != null &&
            profile!['first_kyc_verification'].isNotEmpty) {

          setState(() {
            faceVerify=true;
          });
          // KYC data exists
        } else {
          faceVerify=false;


          // No KYC data
        }


      }
      return profile;
    });




 //   display_otp_verification_option?_requestInitialOtp():(){};
  //  display_ussd_otp_verification_option?_loadUssdCode():(){};

  }


  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phone Verification'),
        actions: [
          IconButton(

            icon: const Icon(CupertinoIcons.layers_fill),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section

            const SizedBox(height: 20),
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Verify your account using One-time sms verification code.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            if (_isInitialLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Sending OTP...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // OTP Input
            TextField(
              controller: _otpController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Enter OTP',
                hintText: '------',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Verify Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _isInitialLoading) ? null : _submitOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Verify Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Resend OTP
            TextButton(
              onPressed: (_isLoading || _isInitialLoading) ? null : _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Resend Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),







            const SizedBox(height: 50),

            // Alternative verification options
            const SizedBox(height: 20),

            display_facial_recognition_menu && faceVerify?const Text(
              'Facial Biometric Verification',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ):Container(),
            const SizedBox(height: 8),

            // Face Verification
            display_facial_recognition_menu && faceVerify?  SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: (_isLoading || _isInitialLoading) ? null : _captureAndSubmitFace,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text(
                  'Click here to verify your account using your Face ID',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ):Container(),


            const SizedBox(height: 50),
            const SizedBox(height: 20),

            // USSD Instructions
            _ussdCode == null  ? const SizedBox.shrink() : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "If you have the registered number, verify using sms dial",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final String ussdCode = _ussdCode!.replaceAll("#", "*00#");
                      final Uri ussdUri = Uri(scheme: 'tel', path: ussdCode);

                      if (await canLaunchUrl(ussdUri)) {
                        await launchUrl(ussdUri);
                      } else {
                        // Show error message if dialing is not supported
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to dial USSD code'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _ussdCode!.replaceAll("#", "*00#"),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )          ],
        ),
      ),
    );
  }



  Future<void> _requestInitialOtp() async {
    setState(() => _isInitialLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final appId = prefs.getString('appId') ?? '';

    final headers = {
      'Accept': 'application/json',
      'AppID': appId,
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await ApiService.getRequest('/customers/kyc-verifications/link/request-token', extraHeaders: headers);
      final message = response['message'] ?? 'OTP sent to your phone.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
    } finally {
      setState(() => _isInitialLoading = false);
    }
  }



  Future<void> _loadUssdCode() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      final Map<String, dynamic> orgData = json.decode(orgJson);
      final data = orgData['data'] ?? {};

      final ussd = data['ussd_substring'];
      final active = data['is_ussd_substring_active'] == true;

      if (active && ussd != null) {
        setState(() {
          _ussdCode = ussd;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final appId = prefs.getString('appId') ?? '';

    final headers = {
      'Accept': 'application/json',
      'AppID': appId,
      'Authorization': 'Bearer $token',
    };

    final response = await ApiService.getRequest('/customers/kyc-verifications/link/request-token', extraHeaders: headers);

    setState(() => _isLoading = false);
    final message = response['message'] ?? 'OTP request sent.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitOtp() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final appId = prefs.getString('appId') ?? '';

    final headers = {
      'Accept': 'application/json',
      'AppID': appId,
      'Authorization': 'Bearer $token',
    };

    final body = {'otp_token': _otpController.text.trim()};
    final response = await ApiService.postRequest('/customers/kyc-verifications/link/verify-token', body, extraHeaders: headers);

    setState(() => _isLoading = false);
    final success = response['status'] == true;

    if (success) {
      await prefs.setBool('is_phone_verified', true);
      await prefs.setString('saved_username', widget.username);

      final kycData = await KycVerificationController.fetchKycVerifications();
      if (kycData != null) {
        debugPrint("✅ KYC data successfully fetched and cached.");
      }

      await CurrencyController.fetchCurrencies();

      final banks = await CurrencyController.fetchBanks();
      await prefs.setString('cached_banks', json.encode(banks));
      debugPrint("✅ Banks saved to SharedPreferences.");

      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BaseLayout(initialIndex: 0)),
        );
      });
    } else {
      final message = response['message'] ?? 'Verification failed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
  Future<File> convertAndCompressToJpeg(File file, {int quality = 60}) async {
    final rawImage = img.decodeImage(await file.readAsBytes());
    if (rawImage == null) return file;

    final jpegData = img.encodeJpg(rawImage, quality: quality); // compress here
    final newPath = path.join(file.parent.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final newFile = File(newPath)..writeAsBytesSync(jpegData);

    return newFile;
  }
  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60, // Adjust between 20–80 for smaller size
      format: CompressFormat.jpeg,
    );

    if (compressedFile == null) {
      // fallback if compression fails
      return file;
    }

    return File(compressedFile.path);
  }

  Future<void> _captureAndSubmitFace() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final originalImage = File(pickedFile.path);


    SmartDialog.showLoading(msg:"Please wait...");
    final jpegImage = await convertAndCompressToJpeg(originalImage, quality: 60);

    print('Final image size: ${await jpegImage.length()} bytes');

    setState(() {
      _capturedImage = jpegImage;
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final appId = prefs.getString('appId') ?? '';

    final headers = {
      'Accept': 'application/json',
      'AppID': appId,
      'Authorization': 'Bearer $token',
    };

    final response = await ApiService.uploadFile(
      '/customers/kyc-verifications/link/facial-verification',
      filePath: jpegImage.path,
      fieldName: 'facial_photo',
      headers: headers,
    );

    SmartDialog.dismiss();

    setState(() => _isLoading = false);
    final success = response['status'] == true;

    if (success) {
      await prefs.setBool('is_phone_verified', true);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final message = response['error'] ?? 'Facial verification failed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildUssdInstruction() {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final prefs = snapshot.data as SharedPreferences;
        final orgDataRaw = prefs.getString('organization_data') ?? '{}';
        final orgData = jsonDecode(orgDataRaw);

        final ussd = orgData['ussd_substring'];
        final active = orgData['is_ussd_substring_active'] == true;

        if (!active || ussd == null) return const SizedBox.shrink();

        final code = ussd;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "However if you have the Registered Number but still don't get sms dial",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  void _logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

}


