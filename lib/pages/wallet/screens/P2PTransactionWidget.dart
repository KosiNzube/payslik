import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../controller/WalletController.dart';

class P2PTransactionWidget extends StatefulWidget {
  const P2PTransactionWidget({Key? key}) : super(key: key);

  @override
  State<P2PTransactionWidget> createState() => _P2PTransactionWidgetState();
}

class _P2PTransactionWidgetState extends State<P2PTransactionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _sourceWalletController = TextEditingController();
  final _destinationWalletController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _verifyingWallet = false;
  bool _isVerified = false;
  String _transactionType = 'wallet_transfer';
  String _walletOwnerName = '';

  @override
  void dispose() {
    _sourceWalletController.dispose();
    _destinationWalletController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyWallet() async {
    if (_destinationWalletController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter destination wallet number')),
      );
      return;
    }

    setState(() {
      _verifyingWallet = true;
      _isVerified = false;
    });

    try {
      final response = await WalletController.verifyWalletAddress(
        _destinationWalletController.text.trim(),
      );

      if (response['status'] == true) {
        setState(() {
          _isVerified = true;
          _walletOwnerName = response['data']?['owner_name'] ?? 'Unknown';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet verified! Owner: $_walletOwnerName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _verifyingWallet = false);
    }
  }

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (_transactionType == 'wallet_transfer') {
        response = await WalletController.completeWalletTransaction(
          sourceWalletNumber: _sourceWalletController.text.trim(),
          destinationWalletNumber: _destinationWalletController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          description: _descriptionController.text.trim(),
          transactionPin: _pinController.text.trim(),
          verifyWallets: !_isVerified,
        );
      } else {
        response = await WalletController.completeWalletFundsSwap(
          sourceWalletNumberOrUuid: _sourceWalletController.text.trim(),
          sourceWalletSwapAmount: double.parse(_amountController.text.trim()),
          destinationWalletNumberOrUuid: _destinationWalletController.text.trim(),
          description: _descriptionController.text.trim(),
          transactionPin: _pinController.text.trim(),
        );
      }

      if (response['status'] == true) {
        _showSuccessDialog(response);
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction completed successfully!'),
            const SizedBox(height: 8),
            Text('Amount: ₦${_amountController.text}'),
            Text('From: ${_sourceWalletController.text}'),
            Text('To: ${_destinationWalletController.text}'),
            if (_walletOwnerName.isNotEmpty)
              Text('Recipient: $_walletOwnerName'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _sourceWalletController.clear();
    _destinationWalletController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _pinController.clear();
    setState(() {
      _isVerified = false;
      _walletOwnerName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Transaction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Type',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Wallet Transfer'),
                              value: 'wallet_transfer',
                              groupValue: _transactionType,
                              onChanged: (value) {
                                setState(() {
                                  _transactionType = value!;
                                  _resetForm();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Currency Swap'),
                              value: 'currency_swap',
                              groupValue: _transactionType,
                              onChanged: (value) {
                                setState(() {
                                  _transactionType = value!;
                                  _resetForm();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Source Wallet
              TextFormField(
                controller: _sourceWalletController,
                decoration: const InputDecoration(
                  labelText: 'Source Wallet Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter source wallet number';
                  }
                  if (value.length < 10) {
                    return 'Wallet number must be at least 10 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Destination Wallet
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _destinationWalletController,
                      decoration: InputDecoration(
                        labelText: _transactionType == 'wallet_transfer'
                            ? 'Destination Wallet Number'
                            : 'Destination Wallet/UUID',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.send),
                        suffixIcon: _isVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      keyboardType: _transactionType == 'wallet_transfer'
                          ? TextInputType.number
                          : TextInputType.text,
                      inputFormatters: _transactionType == 'wallet_transfer'
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter destination wallet';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _isVerified = false;
                          _walletOwnerName = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_transactionType == 'wallet_transfer')
                    ElevatedButton(
                      onPressed: _verifyingWallet ? null : _verifyWallet,
                      child: _verifyingWallet
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Verify'),
                    ),
                ],
              ),

              if (_isVerified && _walletOwnerName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Verified: $_walletOwnerName',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: _transactionType == 'wallet_transfer'
                      ? 'Amount (₦)'
                      : 'Swap Amount (₦)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 10) {
                    return 'Minimum amount is ₦10';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transaction description';
                  }
                  if (value.length < 5) {
                    return 'Description must be at least 5 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Transaction PIN
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Transaction PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transaction PIN';
                  }
                  if (value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _processTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _transactionType == 'wallet_transfer'
                      ? Colors.blue
                      : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Processing...'),
                  ],
                )
                    : Text(
                  _transactionType == 'wallet_transfer'
                      ? 'Send Money'
                      : 'Swap Currency',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Info Card
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transaction Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_transactionType == 'wallet_transfer') ...[
                        const Text(
                          '• Wallet-to-wallet transfers are instant',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Minimum transfer amount: ₦10',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Verify recipient wallet before sending',
                          style: TextStyle(fontSize: 12),
                        ),
                      ] else ...[
                        const Text(
                          '• Currency swaps may take a few minutes',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Exchange rates are applied automatically',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Both wallet number and UUID are supported',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                      const Text(
                        '• Keep your transaction PIN secure',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}