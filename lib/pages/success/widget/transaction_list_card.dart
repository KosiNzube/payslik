import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/WalletTransactionController.dart';
import '../../../controller/WTCC.dart';
import 'transaction_tile.dart';
import 'package:gobeller/utils/routes.dart';
import 'dart:convert'; // Import for jsonDecode
import 'dart:typed_data'; // For working with byte data
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

class TransactionListCard extends StatefulWidget {
  const TransactionListCard({super.key});

  @override
  State<TransactionListCard> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionListCard> {
  bool _showFullTransactions = false;
  late WalletTransactionControllerCard _walletTransactionController;

  @override
  void initState() {
    super.initState();
    _walletTransactionController = Provider.of<WalletTransactionControllerCard>(context, listen: false);
    _walletTransactionController.loadCachedTransactions();

    _walletTransactionController.fetchWalletTransactions();
  }

  /// **Opens modal to show full transaction details**
  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final statusLabel = (transaction["status"]["label"]?.toString().toLowerCase() ?? "unknown");
            Color statusColor;
            if (statusLabel.contains("successful")) {
              statusColor = Colors.green;
            } else if (statusLabel.contains("fail")) {
              statusColor = Colors.red;
            } else {
              statusColor = Colors.orange;
            }

            final timelineSteps = <Map<String, String>>[];
            timelineSteps.add({"title": "Payment\nInitiated", "time": transaction["created_at"] ?? "N/A"});
            if (statusLabel.contains("pending")) {
              timelineSteps.add({"title": "Processing\nby Bank", "time": transaction["created_at"]});
            } else if (statusLabel.contains("fail")) {
              timelineSteps.add({"title": "Failed\nat Bank", "time": transaction["updated_at"] ?? transaction["created_at"]});
            } else {
              timelineSteps.add({"title": "Processing\nby Bank", "time": transaction["created_at"]});
              timelineSteps.add({"title": "Received\nby Bank", "time": transaction["completed_at"] ?? transaction["created_at"]});
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Transfer to ${transaction["receiver_name"] ?? "Recipient"}",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      transaction["status"]["label"] ?? "Status Unknown",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timeline Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          timelineSteps.length * 2 - 1,
                              (index) {
                            if (index.isEven) {
                              final step = timelineSteps[index ~/ 2];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    Icon(Icons.circle, size: 12, color: statusColor),
                                    const SizedBox(height: 4),
                                    Text(step["title"]!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(step["time"]!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                width: 20,
                                height: 2,
                                color: statusColor,
                              );
                            }
                          },
                        ),
                      ),
                    ),


                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Amount", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
                          _infoRow("Fee", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["org_charge_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
                          _infoRow("Recipient", "${transaction["description"] ?? "N/A"}", wrap: true),
                          _infoRow("Account Number", "${transaction["user_wallet"]["wallet_number"] ?? "N/A"}"),
                          _infoRow("Session ID", "${transaction["instrument_code"] ?? transaction["reference_number"] ?? "N/A"}", wrap: true, showCopy: true),
                          _infoRow("Payment Method", "${transaction["transaction_category"]["category"] ?? "N/A"}"),
                          _infoRow("Date", transaction["created_at"] ?? "N/A"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadTransactionAsPDF(transaction),
                            icon: const Icon(Icons.download),
                            label: const Text("Download"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareTransactionAsPDF(transaction),
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper for info rows
  Widget _infoRow(String title, String value, {bool wrap = false, bool showCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    softWrap: wrap,
                    overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
                    maxLines: wrap ? null : 1,
                  ),
                ),
                if (showCopy) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }




// Helper function to build Table cells
  Widget _buildTableCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  // PDF share
  Future<void> _shareTransactionAsPDF(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();

    final prefs = await SharedPreferences.getInstance();
    final customerSupportData = prefs.getString('customerSupportData');
    final customerSupport = customerSupportData != null
        ? jsonDecode(customerSupportData)['data']
        : null;

    Uint8List? logoImageBytes;
    try {
      logoImageBytes = await rootBundle
          .load('assets/logobg.png')
          .then((value) => value.buffer.asUint8List());
    } catch (e) {
      print("Error loading logo image from assets: $e");
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo at top center
              pw.Center(
                child: logoImageBytes != null
                    ? pw.Image(pw.MemoryImage(logoImageBytes), width: 100, height: 100, fit: pw.BoxFit.contain)
                    : pw.SizedBox(width: 100, height: 100),
              ),
              pw.SizedBox(height: 20),

              // Title: Transaction Receipt
              pw.Center(
                child: pw.Text(
                  'Transaction Receipt',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Status Label
              pw.Center(
                child: pw.Text(
                  transaction["status"]["label"],
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _getPdfStatusColor(transaction["status"]["label"]),
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Table for transaction details
              pw.Table(
                children: [
                  _buildPdfTableRow("Amount", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
                  _buildPdfTableRow("Transaction Type", transaction["transaction_type"] ?? "Unknown"),
                  _buildPdfTableRow("Date", transaction["created_at"] ?? "Unknown"),
                  _buildPdfTableRow("Description", transaction["description"] ?? "No Description"),
                  _buildPdfTableRow("Transaction Reference", transaction["reference_number"] ?? "N/A"),
                  if (transaction["instrument_code"] != null)
                    _buildPdfTableRow("Session ID", transaction["instrument_code"]),
                ],
              ),

              pw.SizedBox(height: 20),

              // Customer Support Details
              if (customerSupport != null) ...[
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Customer Support:',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Email: ${customerSupport['official_email']}'),
                pw.Text('Phone: ${customerSupport['official_telephone']}'),
                pw.Text('Website: ${customerSupport['public_existing_website']}'),
                if (customerSupport['address'] != null && customerSupport['address']['country'] != null)
                  pw.Text('Country: ${customerSupport['address']['country']}'),
              ],
              pw.SizedBox(height: 20),

              // Footer (Generated Date)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'transaction_receipt.pdf',
    );
  }

// Helper to build a clean table row
  pw.TableRow _buildPdfTableRow(String title, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

// Helper to determine PDF status label color
  PdfColor _getPdfStatusColor(String statusLabel) {
    if (statusLabel == "Pending") {
      return PdfColors.orange; // Pending
    } else if (statusLabel == "Successful") {
      return PdfColors.green; // Successful
    } else {
      return PdfColors.red; // Any other status
    }
  }


  Future<void> _downloadTransactionAsPDF(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();
    final customerSupportData = prefs.getString('customerSupportData');
    final customerSupport = customerSupportData != null
        ? jsonDecode(customerSupportData)['data']
        : null;

    Uint8List? logoImageBytes;
    try {
      logoImageBytes = await rootBundle
          .load('assets/logobg.png')
          .then((value) => value.buffer.asUint8List());
    } catch (e) {
      print("Error loading logo image from assets: $e");
    }

    // Determine status and colors
    final statusLabel = transaction["status"]["label"]?.toString().toLowerCase() ?? "unknown";
    PdfColor statusColor;
    if (statusLabel.contains("successful")) {
      statusColor = PdfColors.green;
    } else if (statusLabel.contains("fail")) {
      statusColor = PdfColors.red;
    } else {
      statusColor = PdfColors.orange;
    }

    // Timeline steps based on status
    final timelineSteps = <Map<String, String>>[];
    timelineSteps.add({"title": "Payment\nInitiated", "time": transaction["created_at"] ?? "N/A"});

    if (statusLabel.contains("pending")) {
      timelineSteps.add({"title": "Processing\nby Bank", "time": transaction["created_at"]});
    } else if (statusLabel.contains("fail")) {
      timelineSteps.add({"title": "Failed\nat Bank", "time": transaction["updated_at"] ?? transaction["created_at"]});
    } else {
      timelineSteps.add({"title": "Processing\nby Bank", "time": transaction["created_at"]});
      timelineSteps.add({"title": "Received\nby Bank", "time": transaction["completed_at"] ?? transaction["created_at"]});
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImageBytes != null)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoImageBytes),
                    width: 60,
                    height: 60,
                  ),
                ),
              pw.SizedBox(height: 10),

              pw.Text(
                "Transfer to ${transaction["receiver_name"] ?? "Recipient"}",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Color-coded status label
              pw.Text(
                transaction["status"]["label"] ?? "Status Unknown",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: statusColor,
                ),
              ),
              pw.SizedBox(height: 20),

              // Timeline
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  timelineSteps.length * 2 - 1,
                      (index) {
                    if (index.isEven) {
                      final step = timelineSteps[index ~/ 2];
                      return _buildTimelineStep(step["title"]!, step["time"]!);
                    } else {
                      return _buildTimelineDivider();
                    }
                  },
                ),
              ),
              pw.SizedBox(height: 20),

              _buildInfoRow("Amount", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
              _buildInfoRow("Fee", "${transaction["user_wallet"]["currency"]["code"]}${(double.tryParse(transaction["org_charge_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),

              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Recipient", "${transaction["description"] ?? "N/A"}"),
                    _buildInfoRow("Account Number", "${transaction["user_wallet"]["wallet_number"] ?? "N/A"}"),
                    _buildInfoRow("Transaction No.", "${transaction["reference_number"] ?? "N/A"}"),
                    _buildInfoRow("Session ID", transaction["instrument_code"] ?? transaction["reference_number"] ?? "N/A"),
                    _buildInfoRow("Payment Method", "${transaction["transaction_category"]["category"] ?? "N/A"}"),
                    _buildInfoRow("Date", transaction["created_at"] ?? "N/A"),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              if (customerSupport != null) ...[
                pw.Divider(),
                pw.Text("Customer Support", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Email: ${customerSupport['official_email']}'),
                pw.Text('Phone: ${customerSupport['official_telephone']}'),
                pw.Text('Website: ${customerSupport['public_existing_website']}'),
                if (customerSupport['address'] != null && customerSupport['address']['country'] != null)
                  pw.Text('Country: ${customerSupport['address']['country']}'),
              ],
              pw.SizedBox(height: 20),

              pw.Text(
                'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  pw.Widget _buildInfoRow(String title, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          value is pw.Widget ? value : pw.Text(value.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildTimelineStep(String label, String? time) {
    return pw.Column(
      children: [
        pw.Container(
          width: 15,
          height: 15,
          decoration: pw.BoxDecoration(
            color: PdfColors.green,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8)),
        if (time != null) pw.Text(DateFormat('MM-dd HH:mm').format(DateTime.parse(time)), style: pw.TextStyle(fontSize: 6, color: PdfColors.grey)),
      ],
    );
  }

  pw.Widget _buildTimelineDivider() {
    return pw.Container(
      width: 20,
      height: 2,
      color: PdfColors.green,
    );
  }



  pw.TableRow _buildTableRow(String title, String value) {
    return pw.TableRow(
      children: [
        // Title aligned to the left with padding and wrapping enabled
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            softWrap: true, // Allow text to wrap
            maxLines: 2, // Limit the lines to 2 (you can adjust based on your needs)
          ),
        ),
        // Value aligned to the right with padding and wrapping enabled
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,  // Align the value to the right
            style: pw.TextStyle(
              color: PdfColors.black,
            ),
            softWrap: true,  // Allow text to wrap
            maxLines: 2,  // Limit the lines to 2 (you can adjust based on your needs)
          ),
        ),
      ],
    );
  }
  var transactions;
  var isLoading;
  late bool hasTransactions;
  late int displayedTransactions;
  @override
  Widget build(BuildContext context) {
    final transactionController = Provider.of<WalletTransactionControllerCard>(context);


    if(transactionController!=null) {
       transactions = transactionController.transactions;
       isLoading = transactionController.isLoading;

       hasTransactions= transactions.isNotEmpty;
       displayedTransactions = hasTransactions
          ? (_showFullTransactions ? transactions.length : (transactions
          .length < 15 ? transactions.length : 15))
          : 0;
    }
    return transactionController!=null? SizedBox(
      width: double.infinity,
      child: Container(
      //  margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),

          color:  Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Card Transactions",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        if (hasTransactions)
                          Text(
                            "${transactions.length} transaction${transactions.length == 1 ? '' : 's'}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemGrey.resolveFrom(context),
                            ),
                          ),


                      ],
                    ),

                  ],
                ),
              ),

              /// Content Section
              Container(
                padding: const EdgeInsets.only(top: 5,bottom: 5),
                child: Column(
                  children: [
                    /// Loading State
                    if (isLoading)
                      SizedBox(
                        height: 160,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(
                                radius: 16,
                                color: CupertinoColors.systemBlue.resolveFrom(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Loading transactions...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.systemGrey.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )

                    /// No Transactions Message
                    else if (!hasTransactions)
                      SizedBox(
                        height: 160,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.creditcard,
                                  size: 32,
                                  color: CupertinoColors.systemGrey2.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No transactions available",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Your recent transactions will appear here",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.systemGrey.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )

                    /// Transaction List
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: displayedTransactions,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            color: CupertinoColors.systemGrey5.resolveFrom(context),
                          ),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            String formattedAmount = (double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2);
                            String transactionType = transaction["transaction_type"] ?? "Unknown";
                            String slug= transaction['transaction_category']['category']??"";
                            bool isDeposit = transactionType.toLowerCase().contains('deposit') ||
                                transactionType.toLowerCase().contains('credit');

                            return Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBackground.resolveFrom(context),
                                borderRadius: BorderRadius.vertical(
                                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                                  bottom: index == displayedTransactions - 1 ? const Radius.circular(16) : Radius.zero,
                                ),
                              ),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _showTransactionDetails(transaction),
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 15,top: 15),
                                  child: Row(
                                    children: [
                                      // Icon container
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDeposit ? const Color(0xFFE8F5E8) : CupertinoColors.destructiveRed.withOpacity(.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isDeposit ? CupertinoIcons.add : CupertinoIcons.minus,
                                          color: isDeposit ? const Color(0xFF4CAF50) : CupertinoColors.destructiveRed,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Transaction details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transactionType.toLowerCase() +
                                                  " • " +
                                                  (slug.length > 14 ? slug.substring(0, 14) + ".." : slug).toLowerCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTransactionSubtitle(transaction),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: CupertinoColors.systemGrey.resolveFrom(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount
                                      Text(
                                        "${isDeposit ? '+' : '-'}${transaction["user_wallet"]["currency"]["symbol"] ?? "₦"}${formattedAmount}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDeposit ? const Color(0xFF4CAF50) : CupertinoColors.destructiveRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ):Container();
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
