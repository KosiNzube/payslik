import 'package:flutter/material.dart';

class TransactionHistory extends StatelessWidget {
  // Dummy data for transactions (empty for now to show the "No Record" message)
  final List<Map<String, String>> transactions = [];

  TransactionHistory({super.key, required cardId});

  @override
  Widget build(BuildContext context) {
    return transactions.isEmpty
        ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          "No records available.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent,
              child: Icon(
                Icons.payment,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              transaction['description'] ?? 'No Description',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              'Amount: \$${transaction['amount']}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            trailing: Text(
              transaction['date'] ?? 'No Date',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
