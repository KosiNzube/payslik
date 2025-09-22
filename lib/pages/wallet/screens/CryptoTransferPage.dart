import 'package:flutter/material.dart';

import '../../../utils/api_service.dart';

class CryptoTransferPage extends StatefulWidget {
  final Map<String, dynamic> wallet;

  const CryptoTransferPage({super.key, required this.wallet});

  @override
  State<CryptoTransferPage> createState() => _CryptoTransferPageState();
}

class _CryptoTransferPageState extends State<CryptoTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _selectedNetwork = 'ERC20'; // Default network

  final List<String> _availableNetworks = ['ERC20', 'TRC20'];

  bool _isSubmitting = false;

  void _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      "source_wallet_number_or_uuid": widget.wallet["id"],
      "destination_address_code": _destinationController.text.trim(),
      "destination_address_network": _selectedNetwork,
      "amount": double.tryParse(_amountController.text.trim()) ?? 0,
      "description": "Crypto transfer via app",
    };

    final fullPayload = {
      ...payload,
      "transaction_pin": _pinController.text.trim()
    };

    debugPrint("🔁 Initiating transfer with payload: $payload");

    try {
      /// Step 1: INITIATE the transfer
      final initiateResponse = await ApiService.postRequest(
        "/customers/crypto-wallet-transaction/initiate",
        payload,
      );

      debugPrint("✅ Initiate Response: $initiateResponse");

      if (initiateResponse["status"] == true) {
        /// Step 2: PROCESS the transfer
        debugPrint("⚙️ Proceeding to process transfer...");
        final processResponse = await ApiService.postRequest(
          "/customers/crypto-wallet-transaction/process",
          fullPayload,
        );

        debugPrint("✅ Process Response: $processResponse");

        if (processResponse["status"] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Crypto transfer successful")),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception(processResponse["message"] ?? "Transfer processing failed");
        }
      } else {
        throw Exception(initiateResponse["message"] ?? "Transfer initiation failed");
      }
    } catch (e) {
      debugPrint("❌ Crypto transfer failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.wallet["currency_code"] ?? "Crypto";
    final balance = widget.wallet["balance"]?.toString() ?? "0";
    final address = widget.wallet["wallet_address"] ?? widget.wallet["wallet_number"] ?? "Unavailable";
    final network = widget.wallet["currency_network"] ?? "Unknown";
    final name = widget.wallet["label"] ?? "Unnamed Wallet";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Send $currency"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                      "Current Balance",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balance,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),



              // Destination Address
              _buildInputField(
                controller: _destinationController,
                label: "Destination Wallet Address",
                validator: (value) => value == null || value.isEmpty
                    ? "Enter destination address"
                    : null,
              ),
              const SizedBox(height: 20),

              // Network
              _buildDropdownField(
                value: _selectedNetwork,
                label: "Network",
                items: _availableNetworks,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedNetwork = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Amount
              _buildInputField(
                controller: _amountController,
                label: "Amount in $currency",
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  return (num == null || num <= 0)
                      ? "Enter a valid amount"
                      : null;
                },
              ),
              const SizedBox(height: 20),

              // Transaction PIN
              _buildInputFieldPass(
                controller: _pinController,
                label: "Transaction PIN",
                obscureText: true,
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.length < 4 ? "Enter valid PIN" : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );

  }
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldPass({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = true,
    String? Function(String?)? validator,
  }) {
    bool _isObscured = obscureText; // State to track visibility

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: _isObscured,
              validator: validator,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.send, size: 20),
      label: Text(
        _isSubmitting ? "Sending..." : "Send Now",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: _isSubmitting ? null : _submitTransfer,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
