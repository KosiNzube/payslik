import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankDetailsBottomSheet extends StatelessWidget {
  final String bankName;
  final String bankCode;
  final String accountNumber;

  const BankDetailsBottomSheet({
    super.key,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
  });

  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Number Copied!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Center(
            child: Text(
              'Bank Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _detailRow('Bank Name', bankName),
          const SizedBox(height: 15),
          _detailRow('Bank Code', bankCode),
          const SizedBox(height: 15),
          _accountNumberRow(context),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16,color: Colors.white,),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _accountNumberRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Number',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              accountNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => copyToClipboard(context, accountNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.copy, size: 18,color: Colors.white,),
              label:  Text('Copy',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ],
    );
  }
}

// Usage inside your button:
void showBankDetails(BuildContext context, String bankName, String bankCode, String accountNumber) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => BankDetailsBottomSheet(
      bankName: bankName,
      bankCode: bankCode,
      accountNumber: accountNumber,
    ),
  );
}
