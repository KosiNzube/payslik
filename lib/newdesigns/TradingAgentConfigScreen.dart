import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../utils/api_service.dart';

class TradingAgentConfigScreen extends StatefulWidget {

  final Map<String, dynamic> wallet;

  const TradingAgentConfigScreen({super.key, required this.wallet});


  @override
  State<TradingAgentConfigScreen> createState() => _TradingAgentConfigScreenState();
}

class _TradingAgentConfigScreenState extends State<TradingAgentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for text inputs
  final TextEditingController _buyRateController = TextEditingController();
  final TextEditingController _sellRateController = TextEditingController();
  final TextEditingController _buyMinLimitController = TextEditingController();
  final TextEditingController _buyMaxLimitController = TextEditingController();
  final TextEditingController _sellMinLimitController = TextEditingController();
  final TextEditingController _sellMaxLimitController = TextEditingController();
  Color _primaryColor=Colors.orange;
  Color _secondaryColor=Colors.purple;

  Future<void> _loadSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? '#171E3B'; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ?? '#EB6D00'; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  @override
  void dispose() {
    _buyRateController.dispose();
    _sellRateController.dispose();
    _buyMinLimitController.dispose();
    _buyMaxLimitController.dispose();
    _sellMinLimitController.dispose();
    _sellMaxLimitController.dispose();
    super.dispose();
  }

  Future<void> _submitTradingConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        "wallet_number_or_uuid": widget.wallet["wallet_number"],
        'wallet_currency_trading_buy_rate': int.parse(_buyRateController.text),
        'wallet_currency_trading_sell_rate': int.parse(_sellRateController.text),
        'wallet_currency_trading_buy_min_limit': int.parse(_buyMinLimitController.text),
        'wallet_currency_trading_buy_max_limit': int.parse(_buyMaxLimitController.text),
        'wallet_currency_trading_sell_min_limit': int.parse(_sellMinLimitController.text),
        'wallet_currency_trading_sell_max_limit': int.parse(_sellMaxLimitController.text),
      };

      final response = await ApiService.postRequest(
        '/customized-currency-mgt/trading-agents',
        formData,
      );

      if (response['status'] == true || response['status'] == 'success') {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Request sent successfully!'),
            backgroundColor: _primaryColor,
          ),
        );
        // Navigate back or to next screen
        Navigator.of(context).pop();
      } else {
        // Handle API error
        String errorMessage = response['message'] ?? 'Failed to save configuration';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:  BorderSide(color: _primaryColor!, width: 2.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  @override
  void initState() {
    _loadSecondaryColor();
    // TODO: implement initState
    super.initState();
  }

  @override

  Widget build(BuildContext context) {
    // Assuming _formKey, controllers, _isLoading, _submitTradingConfig, and _secondaryColor are defined elsewhere
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Request To Become An Agent',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

                    const SizedBox(height: 20),


                    Text(
                      'Configure Your Trading Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter accurate rates and limits to get started.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSectionCard(
                context,
                title: 'Trading Rates',
                icon: Icons.trending_up,
                children: [
                  _buildProfessionalTextField(
                    context,
                    controller: _buyRateController,
                    label: 'Buy Rate',
                    hint: 'e.g., 163',
                    icon: Icons.arrow_downward,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  _buildProfessionalTextField(
                    context,
                    controller: _sellRateController,
                    label: 'Sell Rate',
                    hint: 'e.g., 178',
                    icon: Icons.arrow_upward,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _buildSectionCard(
                context,
                title: 'Buy Limits',
                icon: Icons.shopping_cart,
                children: [
                  _buildProfessionalTextField(
                    context,
                    controller: _buyMinLimitController,
                    label: 'Minimum Buy Limit',
                    hint: 'e.g., 1000',
                    icon: Icons.swap_horiz_sharp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  _buildProfessionalTextField(
                    context,
                    controller: _buyMaxLimitController,
                    label: 'Maximum Buy Limit',
                    hint: 'e.g., 3000',
                    icon: Icons.swap_horiz_sharp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _buildSectionCard(
                context,
                title: 'Sell Limits',
                icon: Icons.sell,
                children: [
                  _buildProfessionalTextField(
                    context,
                    controller: _sellMinLimitController,
                    label: 'Minimum Sell Limit',
                    hint: 'e.g., 1000',
                    icon: Icons.swap_horiz_sharp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  _buildProfessionalTextField(
                    context,
                    controller: _sellMaxLimitController,
                    label: 'Maximum Sell Limit',
                    hint: 'e.g., 4000',
                    icon: Icons.swap_horiz_sharp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitTradingConfig,
                  icon: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.arrow_forward, size: 20),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Continue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context,
      {required String title, required IconData icon, required List<Widget> children}
      ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _secondaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalTextField(
      BuildContext context,
      {
        required TextEditingController controller,
        required String label,
        required String hint,
        required IconData icon,
        TextInputType? keyboardType,

      }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: _secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.1),
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        // Add financial validation, e.g., for numbers
        if (keyboardType == const TextInputType.numberWithOptions(decimal: true)) {
          final numValue = double.tryParse(value);
          if (numValue == null || numValue <= 0) {
            return 'Enter a valid positive number';
          }
        }
        return null;
      },
    );
  }}