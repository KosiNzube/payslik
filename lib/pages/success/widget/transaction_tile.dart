import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Add this import

class TransactionTile extends StatelessWidget {
  final String type;
  final String amount;
  final String date;
  final String currencySymbol;

  const TransactionTile({
    Key? key,
    required this.type,
    required this.amount,
    required this.date,
    required this.currencySymbol,
  }) : super(key: key);

  // Method to format datetime with time on top, date below
  String formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String time = DateFormat('h:mm a').format(dateTime); // e.g., "7:04 PM"
      String date = DateFormat('MMM dd, yyyy').format(dateTime); // e.g., "Jun 21, 2025"
      return '$time\n$date';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        type.toUpperCase(),
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(formatDateTime(date),style: GoogleFonts.raleway(fontWeight: FontWeight.w500)),
      trailing: Text(
        "$currencySymbol$amount",
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: type.toLowerCase() == "credit" ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  String _formatTransactionSubtitle(Map<String, dynamic> transaction) {
    String transactionType = transaction["transaction_type"] ?? "Unknown";
    String createdAt = transaction["created_at"] ?? "Unknown";

    // Parse the date and format it
    try {
      DateTime dateTime = DateTime.parse(createdAt);
      String formattedDate = "${dateTime.day} ${_getMonthName(dateTime.month)}, ${dateTime.year}";
      String time = DateFormat('h:mm a').format(dateTime); // e.g., "7:04 PM"

      if (transactionType.toLowerCase().contains('deposit')) {
        return "$time • $formattedDate";
      } else {
        return "$time • $formattedDate";
      }
    } catch (e) {
      return "$transactionType • $createdAt";
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}