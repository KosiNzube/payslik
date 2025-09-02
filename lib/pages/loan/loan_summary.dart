import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoanSummaryPage extends StatelessWidget {
  const LoanSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mockLoans = [
      {"id": "001", "amount": 20000, "status": "Approved", "date": "2025-05-01"},
      {"id": "002", "amount": 150000, "status": "Pending", "date": "2025-04-10"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("My Loans")),
      body: ListView.builder(
        itemCount: mockLoans.length,
        itemBuilder: (_, index) {
          final loan = mockLoans[index];
          return ListTile(
            title: Text("₦${loan['amount']} - ${loan['status']}"),
            subtitle: Text("Date: ${loan['date']}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          );
        },
      ),
    );
  }
}
