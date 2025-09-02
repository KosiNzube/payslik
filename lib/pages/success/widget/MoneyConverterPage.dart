import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MoneyConverterPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MoneyConverterPage extends StatefulWidget {
  const MoneyConverterPage({super.key});

  @override
  State<MoneyConverterPage> createState() => _MoneyConverterPageState();
}

class _MoneyConverterPageState extends State<MoneyConverterPage> {
  final double conversionRate = 0.87297562953;
  final double conversionFee = 6.0;
  final TextEditingController amountController = TextEditingController(text: "0.0");
  double? amount;
  double? convertedAmount;

  @override
  void initState() {
    super.initState();
    // Initialize values
    amount = double.tryParse(amountController.text) ?? 0;
    _calculateConversion();

    // Listen to changes in the text field
    amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    amountController.removeListener(_onAmountChanged);
    amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      amount = double.tryParse(amountController.text) ?? 0;
      _calculateConversion();
    });
  }

  void _calculateConversion() {
    if (amount != null) {
      double amountAfterFee = amount! - conversionFee;
      if (amountAfterFee < 0) amountAfterFee = 0;
      convertedAmount = amountAfterFee * conversionRate;
    } else {
      convertedAmount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    double amountAfterFee = (amount ?? 0) - conversionFee;
    if (amountAfterFee < 0) amountAfterFee = 0;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Convert money',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Enter amount and select currency to convert to',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Amount we\'ll convert',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: const CircleAvatar(
                                        child: Text('🇺🇸', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'USD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_down, size: 20),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Expanded(
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixText: '\$',
                                    prefixStyle: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bal: \$0',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Insufficient Balance',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Conversion fee',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '- \$${conversionFee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Amount we\'ll convert',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '= \$${amountAfterFee.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Today\'s rate',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '× $conversionRate',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Amount you will receive',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircleAvatar(
                                    child: Text('🇪🇺', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'EUR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.keyboard_arrow_down, size: 20),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '€${convertedAmount?.toStringAsFixed(2) ?? "0.00"}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Usually arrives in a minute',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}