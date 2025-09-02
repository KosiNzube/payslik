import 'package:flutter/material.dart';

class LoanSuccessPage extends StatelessWidget {
  final Map<String, dynamic> response;

  const LoanSuccessPage({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final data = response['data'] ?? {};
    final message = response['message'] ?? 'Your loan application was successful!';
    final applicationNumber = data['application_number'] ?? 'N/A';
    final loanAmount = data['loan_amount'] ?? 'N/A';
    final description = data['description'] ?? 'N/A';
    final salary = data['monthly_salary_amount']?.toString() ?? 'N/A';
    final otherIncome = data['other_income_amount']?.toString() ?? '0';
    final expenses = data['monthly_expenses'] ?? 'N/A';
    final repaymentMethod = data['preferred_repayment_method'] ?? 'N/A';
    final repaymentStructure = data['ref_repayment_structure'] ?? 'N/A';
    final frequency = data['ref_loan_frequency'] ?? 'N/A';
    final duration = data['ref_loan_frequent_duration']?.toString() ?? 'N/A';
    final date = data['created_at'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Application Success')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(
              'Application Submitted!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            _buildInfoTile('Application Number', applicationNumber),
            _buildInfoTile('Loan Amount', '₦$loanAmount'),
            _buildInfoTile('Loan Purpose', description),
            _buildInfoTile('Monthly Income', '₦$salary'),
            _buildInfoTile('Other Income', '₦$otherIncome'),
            _buildInfoTile('Monthly Expenses', '₦$expenses'),
            _buildInfoTile('Repayment Method', repaymentMethod),
            _buildInfoTile('Repayment Type', repaymentStructure),
            _buildInfoTile('Repayment Frequency', frequency),
            _buildInfoTile('Loan Duration (months)', duration),
            _buildInfoTile('Submission Date', date),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/loan', (route) => false);
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Loan Page'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
