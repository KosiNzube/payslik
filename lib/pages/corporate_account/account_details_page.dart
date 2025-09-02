import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // Import for jsonDecode
import 'dart:typed_data'; // For working with byte data
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:gobeller/controller/CacVerificationController.dart'; // Import your controller

// ... your existing imports ...
import 'package:gobeller/controller/WalletTransactionController.dart'; // Import the transaction controller
import 'package:gobeller/utils/routes.dart'; // For navigation to full history
import 'package:gobeller/pages/success/widget/transaction_tile.dart'; // Assuming you have a TransactionTile widget

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isBalanceHidden = true;
  Color? _primaryColor;
  Color? _secondaryColor;
  bool _showFullTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadAppColors();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final walletController = context.read<CacVerificationController>();
      final transactionController = context.read<CacVerificationController>();

      await walletController.fetchWallets();

      final wallets = (walletController.wallets ?? []).cast<Map<String, dynamic>>();
      final wallet = wallets.firstWhere(
            (w) => w["ownership_type"] == "corporate-wallet",
        orElse: () => {},
      );

      if (wallet.isNotEmpty && wallet["wallet_number"] != null) {
        final walletNumber = wallet["wallet_number"].toString();
        await transactionController.fetchWalletTransactions(walletNumber: walletNumber);
      }
    });
  }



  Future<void> _loadAppColors() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryHex = data['customized-app-primary-color'];
      final secondaryHex = data['customized-app-secondary-color'];

      setState(() {
        _primaryColor = Color(int.parse(primaryHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryHex.replaceAll('#', '0xFF')));
      });
    }
  }


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
          .load('assets/logo.png')
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
                  _buildPdfTableRow("Amount", "${transaction["user_wallet"]["currency"]["symbol"]}${(double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2)}"),
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
          .load('assets/logo.png')
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

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<CacVerificationController>();
    final transactionController = context.watch<CacVerificationController>();


    final List<Map<String, dynamic>> wallets =
        (walletController.wallets as List?)?.cast<Map<String, dynamic>>() ?? [];

    final wallet = wallets.firstWhere(
          (w) => w["ownership_type"] == "corporate-wallet",
      orElse: () => {},
    );

    final bool hasWallet = wallet.isNotEmpty;
    final String walletType = wallet['ownership_label'] ?? "Unknown Type";
    final String accountNumber = wallet['wallet_number'] ?? "N/A";
    final String balance = wallet['balance']?.toString() ?? "0.00";
    final String bankName = wallet['bank']?['name'] ?? "Unknown Bank";
    final String formattedBalance = NumberFormat("#,##0.00").format(double.tryParse(balance) ?? 0.00);


    final transactions = transactionController.transactions;
    final isLoading = transactionController.isLoading;

    final bool hasTransactions = transactions.isNotEmpty;
    final int displayedTransactions = hasTransactions
        ? (_showFullTransactions ? transactions.length : (transactions.length < 3 ? transactions.length : 3))
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Corporate Account Overview"),
        centerTitle: true,
        backgroundColor: _primaryColor ?? Colors.deepPurple,
      ),
      body: Column(
        children: [
          /// Wallet Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _secondaryColor ?? Colors.deepPurple.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello 👋",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                if (!hasWallet)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text("Create Wallet"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryColor ?? Colors.deepPurple,
                      ),
                      onPressed: () {
                        // Handle create wallet
                      },
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        "Acct: $accountNumber",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: accountNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Account number copied!")),
                          );
                        },
                        child: const Icon(Icons.copy, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    bankName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$walletType",
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isBalanceHidden ? "****" : "₦$formattedBalance",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: Icon(
                          _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBalanceHidden = !_isBalanceHidden;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// Transaction Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header with See More
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Recent Transactions",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (hasTransactions)
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, Routes.history);
                              },
                              child: const Text("View All"),
                            ),
                        ],
                      ),
                      const Divider(),

                      /// Loading
                      if (isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )

                      /// Empty
                      else if (!hasTransactions)
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  "No transactions available",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )

                      /// Transactions List
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: displayedTransactions,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              String formattedAmount = (double.tryParse(transaction["user_amount"] ?? "0.00") ?? 0.00).toStringAsFixed(2);
                              return GestureDetector(
                                onTap: () => _showTransactionDetails(transaction),
                                child: TransactionTile(
                                  type: transaction["transaction_type"] ?? "Unknown",
                                  amount: formattedAmount,
                                  date: transaction["created_at"] ?? "Unknown",
                                  currencySymbol: transaction["user_wallet"]["currency"]["symbol"] ?? "₦",
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

