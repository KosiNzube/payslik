import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/controller/login_controller.dart'; // ✅ Imported
import 'package:gobeller/pages/success/dashboard_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/utils/biometric_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controller/create_wallet_controller.dart';
import '../../controller/kyc_controller.dart';
import '../../controller/organization_controller.dart';
import '../../pages/navigation/base_layout.dart';
import '../auth/forgot_password_page.dart';
import '../registration/OtpVerificationPage.dart';
import '../webview/register_webview.dart'; // Import the Forgot Password page


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final LoginController _loginController = LoginController(); // ✅ Added
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _hideUsernameField = false;
  bool _isBiometricLoading = false;
  bool _isPasswordResetEnabled = false;

  bool showOTP =false;
  bool display_facial_recognition_menu=false;
  bool display_otp_verification_option=false;
  bool display_ussd_otp_verification_option=false;


  String? _storedUsername;
  String? _displayName;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;

  String identityCode="";
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadPrimaryColorAndLogo();
    _checkPasswordResetEnabled();
    _checkStoredUsername();
    _autoBiometricLogin();

    final orgController = Provider.of<OrganizationController>(context, listen: false);
    final orgData = orgController.organizationData?['data'] ?? {};
     identityCode = orgData['org_identity_code'] ?? '';// <- Call here
  }
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: _logoUrl != null
            ? AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: CachedNetworkImage(
                  imageUrl: _logoUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            );
          },
        )
            : const CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _autoBiometricLogin() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasUsername = prefs.getString('saved_username') != null;
    final hasPassword = prefs.getString('saved_password') != null;

    if (hasUsername && hasPassword) {
      if (!mounted) return;

      setState(() => _isBiometricLoading = true);
      if (!mounted) return;

      _showLoadingDialog();
      final didAuth = await BiometricHelper.authenticate();

      if (!mounted) return;

      if (didAuth) {
        final result = await _loginController.loginUser(useStoredCredentials: true);

        if (!mounted) return;
        _hideLoadingDialog();

        if (result['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BaseLayout(initialIndex: 0)),
          );
        } else {
          String x= await result['message'] ?? 'Login failed';

          if(x.contains("gobeller")||x.contains("FormatException")){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login failed. Please check your internet connection and try again")),
            );
          }else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Login failed')),
            );
          }
        }
      } else {
        if (!mounted) return;
        _hideLoadingDialog();

//ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric authentication failed')),);
      }

      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }
  Future<void> _checkPasswordResetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final orgJson = prefs.getString('organizationData');

    if (orgJson != null) {
      try {
        final orgData = json.decode(orgJson);
        setState(() {
          _isPasswordResetEnabled = orgData['data']?['customized_app_displayable_menu_items']?['display-password-reset-menu'] ?? false;
          display_facial_recognition_menu=orgData['data']?['customized_app_displayable_menu_items']?['display-facial-recognition-menu'] ?? false;

          display_otp_verification_option=orgData['data']?['customized_app_displayable_menu_items']?['display-otp-verification-option'] ?? false;

          display_ussd_otp_verification_option=orgData['data']?['customized_app_displayable_menu_items']?['display-ussd-otp-verification-option'] ?? false;

          if(display_facial_recognition_menu || display_otp_verification_option || display_facial_recognition_menu ){
            showOTP=true;
          }

        });
      } catch (e) {
        // Handle JSON parsing error
        setState(() {
          _isPasswordResetEnabled = false;

          display_facial_recognition_menu=false;

          display_otp_verification_option=false;

          display_ussd_otp_verification_option=false;

          showOTP =false;

        });
      }
    }
  }




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

  Future<void> _checkStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final test = prefs.getString('first_name');
    final userData = prefs.getString('user');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      String? firstName;

      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        firstName = userMap['first_name'];
      }

      setState(() {
        _storedUsername = savedUsername;
        _displayName = test ;
        _usernameController.text = savedUsername;
        _hideUsernameField = true;
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    _showLoadingDialog();

    final username = _storedUsername ?? _usernameController.text.trim();
    final password = _passwordController.text;

    final result = await _loginController.loginUser(
      username: username,
      password: password,
    );

    if (!mounted) return;
    _hideLoadingDialog();

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();


      // ✅ Check if phone is verified



      /*
      final isPhoneVerified = prefs.getBool('is_phone_verified') ?? false;
      if (!isPhoneVerified && showOTP) {
        // 🚨 Redirect to OTP verification page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  OtpVerificationPage(username:username)),
        );
      } else {
        // ✅ Continue setup if phone is verified

        // ✅ Fetch and cache KYC
        final kycData = await KycVerificationController.fetchKycVerifications();
        if (kycData != null) {
          debugPrint("✅ KYC data successfully fetched and cached.");
        }

        // ✅ Fetch and cache currencies
        await CurrencyController.fetchCurrencies();

        // ✅ Fetch and cache banks
        final banks = await CurrencyController.fetchBanks();
        await prefs.setString('cached_banks', json.encode(banks));
        debugPrint("✅ Banks saved to SharedPreferences.");

        // ✅ Redirect to dashboard
        Future.delayed(const Duration(milliseconds: 1000), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const BaseLayout(initialIndex: 0)),
          );
        });
      }



       */




      // ✅ Continue setup if phone is verified




      // ✅ Fetch and cache KYC
      final kycData = await KycVerificationController.fetchKycVerifications();
      if (kycData != null) {
        debugPrint("✅ KYC data successfully fetched and cached.");
      }

      // ✅ Fetch and cache currencies
      await CurrencyController.fetchCurrencies();

      // ✅ Fetch and cache banks
      final banks = await CurrencyController.fetchBanks();
      await prefs.setString('cached_banks', json.encode(banks));
      debugPrint("✅ Banks saved to SharedPreferences.");

      // ✅ Redirect to dashboard
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const BaseLayout(initialIndex: 0)),(route)=>false,
        );
      });






      }




    else {
      // ❌ Handle login error
      String x = result['message'] ?? 'Login failed';

      if (x.contains("gobeller") || x.contains("FormatException")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              "Login failed. Please check your internet connection and try again")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    }

    setState(() => _isLoading = false);
  }




  Future<void> _switchAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('first_name');

    setState(() {
      _storedUsername = null;
      _displayName = null;
      _usernameController.clear();
      _hideUsernameField = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo Section
                if (_logoUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey[50],
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _logoUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          httpHeaders: const {
                            'User-Agent': 'Flutter App',
                            'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
                          },
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[100],
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('Failed to load image: $url');
                            print('Error: $error');
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[100],
                              ),
                              child: const Center(
                                child: Text(
                                  'Getting Data...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Welcome Text
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      if (_hideUsernameField && _displayName != null)
                        const SizedBox(height: 8),
                      if (_hideUsernameField && _displayName != null)

                        Text(
                          _hideUsernameField
                              ? "Welcome back, "+_displayName!
                              : "Sign in to your account",
                          style:  GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),


                      if (!_hideUsernameField)
                        const SizedBox(height: 8),
                      if (!_hideUsernameField)
                        const Text(
                          "Enter your credentials to access your account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                // Form Section
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      if (!_hideUsernameField)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username Or Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your username or email',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Password Field
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isPasswordObscured,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF667085),
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordObscured = !_isPasswordObscured);
                                  },
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Login Button
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor ?? const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: const Color(0xFFD0D5DD),
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
                            'Sign in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Biometric Login Section
                      if (_storedUsername != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Expanded(child: Divider(color: Color(0xFFEAECF0))),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Color(0xFF667085),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Color(0xFFEAECF0))),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEAECF0)),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.fingerprint,
                                    size: 28,
                                    color: _isBiometricLoading
                                        ? const Color(0xFFD0D5DD)
                                        : const Color(0xFF667EEA),
                                  ),
                                  onPressed: _isBiometricLoading
                                      ? null
                                      : () async {
                                    setState(() => _isBiometricLoading = true);
                                    _showLoadingDialog();

                                    final didAuth = await BiometricHelper.authenticate();

                                    if (didAuth) {
                                      final result = await _loginController.loginUser(useStoredCredentials: true);

                                      if (!mounted) return;

                                      if (result['success'] == true) {
                                        // ✅ Fetch and save KYC verifications
                                        final kycData = await KycVerificationController.fetchKycVerifications();
                                        if (kycData != null) {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('cached_kyc_data', json.encode(kycData));
                                          debugPrint("✅ Biometric: KYC data cached successfully.");
                                        } else {
                                          debugPrint("⚠️ Biometric: Failed to fetch or cache KYC data.");
                                        }

                                        _hideLoadingDialog();

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => const BaseLayout(initialIndex: 0)),
                                        );
                                      } else {
                                        _hideLoadingDialog();

                                        String x = await result['message'] ?? 'Biometric Login failed';

                                        if(x.contains("gobeller")||x.contains("FormatException")){
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Login failed. Please check your internet connection and try again")),
                                          );
                                        }else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(result['message'] ?? 'Biometric Login failed')),
                                          );
                                        }
                                      }
                                    } else {
                                      _hideLoadingDialog();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Fingerprint authentication failed')),
                                      );
                                    }

                                    if (mounted) setState(() => _isBiometricLoading = false);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Use biometric authentication',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF667085),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Forgot Password & Register Links
                      Column(
                        children: [
                          if (_isPasswordResetEnabled)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF667EEA),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),


                          if(identityCode!="0053")
                            TextButton(
                              onPressed: () {
                                final orgController = Provider.of<OrganizationController>(context, listen: false);
                                final orgData = orgController.organizationData?['data'] ?? {};
                                final identityCode = orgData['org_identity_code'] ?? '';

                                if (identityCode == '0053') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>  RegisterWebView(link: 'https://app.easy-buyandowncooperative.com/register',),
                                    ),
                                  );
                                } else if(identityCode == '0068'){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>  RegisterWebView(link: 'https://fxoracleaiglobal.com/',),
                                    ),
                                  );
                                }


                                else {
                                  Navigator.pushNamed(context, '/register');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF667085),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF667085),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sign up",
                                      style: TextStyle(
                                        color: Color(0xFF667EEA),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Switch Account Button
                      if (_hideUsernameField)
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          child: TextButton(
                            onPressed: _switchAccount,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF667085),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Switch Account",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

}