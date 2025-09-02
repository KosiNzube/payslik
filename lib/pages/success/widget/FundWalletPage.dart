import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class FundWalletPage extends StatefulWidget {
  @override
  _FundWalletPageState createState() => _FundWalletPageState();
}

class _FundWalletPageState extends State<FundWalletPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController walletNumberController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController(text: "Wallet funding");

  bool isLoading = false;
  Map<String, dynamic>? fundingDetails;

  Future<void> initiateFundWalletTransaction() async {
    setState(() {
      isLoading = true;
      fundingDetails = null;
    });

    final dio = Dio();

    const url = 'https://app.gobeller.com/api/v1/customers/fund-wallet-transaction/initiate';

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 191|GOBELLER_00mAEOK2es5Rp8bp8BySW5WJ9MEepjdcz7s3J4AM615a3324',
      'AppID': '9d4558d8-5d4f-4e85-a8c1-bccee25e022b',
    };

    final data = {
      "funding_amount": double.tryParse(amountController.text) ?? 0.0,
      "destination_wallet_number_or_uuid": walletNumberController.text,
      "description": descriptionController.text,
    };

    try {
      final response = await dio.post(
        url,
        options: Options(headers: headers),
        data: data,
      );

      setState(() {
        fundingDetails = response.data['data'];
      });
    } on DioException catch (e) {
      print('Error: ${e.response?.data ?? e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate funding.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fund Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to Fund',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: walletNumberController,
              decoration: InputDecoration(
                labelText: 'Wallet Number',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : initiateFundWalletTransaction,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Initiate Funding'),
            ),
            SizedBox(height: 24),
            if (fundingDetails != null) ...[
              Divider(),
              Text(
                'Funding Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Wallet Number: ${fundingDetails!['wallet_number']}'),
              Text('Currency: ${fundingDetails!['currency_symbol']} (${fundingDetails!['currency_code']})'),
              Text('Initial Balance: ${fundingDetails!['initial_balance']}'),
              Text('Amount to Fund: ${fundingDetails!['amount_to_fund']}'),
              Text('Platform Fee: ${fundingDetails!['platform_fee']}'),
              Text('Expected Balance: ${fundingDetails!['expected_balance_after_funding']}'),
              Text('Total Payable: ${fundingDetails!['total_payable']}'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Proceed to payment logic
                },
                child: Text('Proceed to Payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
