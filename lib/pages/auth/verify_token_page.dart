import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controller/forgot_password_controller.dart';
import '../../utils/validators.dart';
import 'reset_password_page.dart'; // Import the ResetPasswordPage

class VerifyTokenPage extends StatefulWidget {
  const VerifyTokenPage({Key? key}) : super(key: key);

  @override
  State<VerifyTokenPage> createState() => _VerifyTokenPageState();
}

class _VerifyTokenPageState extends State<VerifyTokenPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = 
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTokenComplete(BuildContext context, String token) async {
    if (_formKey.currentState!.validate()) {
      final email = context.read<ForgotPasswordController>().requestedEmail;
      if (email != null) {
        final success = await context
            .read<ForgotPasswordController>()
            .verifyResetToken(email, token);

        if (mounted) {
          if (success) {
            // Show success and navigate to reset password page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Token verified successfully'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(
                  email: email,
                  token: token,
                ),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3A5D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Reset Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A5D),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ForgotPasswordController>(
                builder: (context, controller, child) {
                  return Text(
                    'Enter the 6-digit code sent to ${controller.requestedEmail}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF667EEA).withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF667EEA).withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        
                        if (value.isNotEmpty && index == 5) {
                          final token = _controllers
                              .map((c) => c.text)
                              .join();
                          if (token.length == 6) {
                            _onTokenComplete(context, token);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<ForgotPasswordController>(
                builder: (context, controller, child) {
                  if (controller.verificationError.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        controller.verificationError,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(
                width: double.infinity,
                child: Consumer<ForgotPasswordController>(
                  builder: (context, controller, child) {
                    return ElevatedButton(
                      onPressed: controller.isVerifyingToken
                          ? null
                          : () {
                              final token = _controllers
                                  .map((c) => c.text)
                                  .join();
                              _onTokenComplete(context, token);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isVerifyingToken
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}