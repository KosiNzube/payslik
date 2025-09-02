import 'package:flutter/material.dart';
import '../../../utils/api_service.dart';

class CryptoSwapPage extends StatefulWidget {
  final Map<String, dynamic> sourceWallet;
  final List<Map<String, dynamic>> allWallets;

  const CryptoSwapPage({super.key, required this.sourceWallet, required this.allWallets});

  @override
  State<CryptoSwapPage> createState() => _CryptoSwapPageState();
}

class _CryptoSwapPageState extends State<CryptoSwapPage> {
  late List<Map<String, dynamic>> destinationWallets;
  Map<String, dynamic>? selectedDestinationWallet;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    destinationWallets = widget.allWallets
        .where((w) => w['wallet_number'] != widget.sourceWallet['wallet_number'])
        .toList();
  }

  Future<void> _handleSwap() async {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (selectedDestinationWallet == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and select a destination wallet.')),
      );
      return;
    }

    final pin = await _promptForPin();
    if (pin == null) return;

    setState(() => _isLoading = true);

    final payload = {
      "source_wallet_number_or_uuid": widget.sourceWallet['wallet_id'],
      "source_wallet_swap_amount": amount,
      "destination_wallet_number_or_uuid": selectedDestinationWallet!['wallet_id'],
      "description": description,
    };

    final initiateRes = await ApiService.postRequest("/customers/wallet-funds-swap/initiate", payload);

    if (!(initiateRes['status'] ?? false)) {
      _showMessage(initiateRes['message'] ?? 'Failed to initiate swap');
      setState(() => _isLoading = false);
      return;
    }

    // Proceed to process
    final processPayload = {
      ...payload,
      "transaction_pin": int.tryParse(pin)
    };

    final processRes = await ApiService.postRequest("/customers/wallet-funds-swap/process", processPayload);
    setState(() => _isLoading = false);

    if (processRes['status'] == true) {
      _showMessage("Swap completed successfully");
      Navigator.pop(context); // Go back after success
    } else {
      _showMessage(processRes['message'] ?? 'Swap failed');
    }
  }

  Future<String?> _promptForPin() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Transaction PIN"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: "PIN"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.sourceWallet['currency_code'] ?? "CRYPTO";
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Swap Crypto"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    widget.sourceWallet['balance']?.toString() ?? "0",
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

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("From Wallet", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      widget.sourceWallet['wallet_number'] ?? currency,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(
                labelText: "Destination Wallet",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              value: selectedDestinationWallet,
              items: destinationWallets.map((wallet) {
                return DropdownMenuItem(
                  value: wallet,
                  child: Text(wallet['currency_code'].toString() +" - "+wallet['balance'].toString()+ " ("+wallet['wallet_number'].toString()+")" ?? wallet['currency_code'].toString() ?? 'Wallet'),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedDestinationWallet = value),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount to Swap",
                prefixText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _handleSwap,
                icon: const Icon(Icons.sync_alt),
                label: const Text("Swap Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
