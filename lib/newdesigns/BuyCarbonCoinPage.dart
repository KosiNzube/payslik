import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class BuySolarCoinPage extends StatefulWidget {

  final Map<String, dynamic> wallet;

  const BuySolarCoinPage({super.key, required this.wallet});


  @override
  _BuySolarCoinPageState createState() => _BuySolarCoinPageState();
}

class _BuySolarCoinPageState extends State<BuySolarCoinPage> {
  int currentStep = 0;

  // Step 1 variables
  final TextEditingController _amountController = TextEditingController();
  double enteredAmount = 0.0;

  // Step 2 variables
  List<Agent> agents = [];
  Agent? selectedAgent;
  bool isLoadingAgents = false;

  // Step 3 variables
  double coinQuantity = 0.0;
  bool isProcessingPayment = false;

  bool isConfirmingPayment = false;


  String? buyerDebitWalletNumber;
  String? buyerDebitCurrency;
  String? buyerDebitSymbol;
  num? buyerDebitAmount;

  String? buyerCreditWalletNumber;
  String? buyerCreditCurrency;
  String? buyerCreditSymbol;
  num? buyerCreditAmount;

  String? exchangeType;
  num? exchangeRate;

  String? agentId;
  Color _primaryColor=Colors.orange;
  Color _secondaryColor=Colors.purple;


  Future<void> _loadSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');  // Using the correct key name for settings

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? '#171E3B'; // Default fallback color
      final secondaryColorHex = data['customized-app-secondary-color'] ?? '#EB6D00'; // Default fallback color

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _loadSecondaryColor();

  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Fetch agents from API
  Future<void> _fetchAgents() async {
    setState(() {
      isLoadingAgents = true;
    });

    try {
      final response = await ApiService.getRequest(
          '/customized-currency-mgt/trading-marketplace?items_per_page=15&page=1'
      );

      if (response['status'] == true) {

        print("5555555555555555555555555555555555555555555555555555555555555555555\n\n\\n\n\n\\n\n\n\n\n\n\\n\n\n\n"+response.toString()+"5555555555555555555555555555555555555555555555555555555555555555555\n\n\\n\n\n\\n\n\n\n\n\n\\n\n\n\n");

        final List<dynamic> agentsData = response['data']['data'];
        setState(() {
          agents = agentsData.map((data) => Agent.fromJson(data)).toList();
          // Filter agents who have buy rates
          agents = agents.where((agent) =>
          agent.tradingRates.containsKey('cc-cbc-buy-rate') &&
              agent.tradingRates['cc-cbc-buy-rate'] != null
          ).toList();
        });
      } else {
        _showErrorSnackbar('Failed to load agents: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackbar('Error loading agents: $e');
    } finally {
      setState(() {
        isLoadingAgents = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
      ),
    );
  }

  // Step 1: Continue to agent selection
  void _continueToAgentSelection() {
    if (_amountController.text.isEmpty) {
      _showErrorSnackbar('Please enter an amount');
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showErrorSnackbar('Please enter a valid amount');
      return;
    }

    setState(() {
      enteredAmount = amount;
      currentStep = 1;
    });

    _fetchAgents();
  }

  // Step 2: Select agent and continue to confirmation
  Future<void> _selectAgent(Agent agent) async {
    double buyRate = agent.tradingRates['cc-cbc-buy-rate']?.toDouble() ?? 0;


    SmartDialog.showLoading(msg: "Please wait...");

    await _processPayment();

    SmartDialog.dismiss();

    setState(() {
      selectedAgent = agent;
      coinQuantity = enteredAmount / buyRate;
    });
  }

  // Step 3: Process payment
  Future<void> _processPayment() async {
    if (selectedAgent == null) return;

    setState(() {
      isProcessingPayment = true;
    });

    try {
      // TODO: Replace with actual payment endpoint
      final response = await ApiService.postRequest(
          '/customized-currency-mgt/trading-marketplace/initiate-exchange',
          {
            'wallet_number_or_uuid':widget.wallet['wallet_number'],
            'agent_id': selectedAgent!.id,
            "exchange_type": "buy",
            'exchange_amount': enteredAmount,
           // 'coin_quantity': coinQuantity,
          //  'buy_rate': selectedAgent!.tradingRates['cc-cbc-buy-rate'],
          }
      );

      if (response['status'] == true) {
        final data = response['data'];
        final trader = data['trader'];
        final agent = data['agent'];

        setState(() {
          /// Transaction summary for the buyer
          buyerDebitWalletNumber = trader['debit']['wallet_number'];
          buyerDebitCurrency = trader['debit']['currency_code'];
          buyerDebitSymbol = trader['debit']['currency_symbol'];
          buyerDebitAmount = trader['debit']['amount'];

          buyerCreditWalletNumber = trader['credit']['wallet_number'];
          buyerCreditCurrency = trader['credit']['currency_code'];
          buyerCreditSymbol = trader['credit']['currency_symbol'];
          buyerCreditAmount = trader['credit']['amount'];

          exchangeType = data['exchange_type'];
          exchangeRate = agent['exchange_rates']['buy_rate'];

          agentId = agent['id']; // You may later fetch agent name if needed.

          currentStep = 2; // Move to Confirm & Pay page
        });
      } else {
        _showErrorSnackbar('Something went wrong: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackbar('Something went wrong: $e');
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }


  Future<void> _confirmPayment(String pin) async {
    if (selectedAgent == null) return;

    setState(() {
      isConfirmingPayment = true;
    });

    try {
      // TODO: Replace with actual payment endpoint
      final response = await ApiService.postRequest(
          '/customized-currency-mgt/trading-marketplace/process-exchange',
          {
            'wallet_number_or_uuid':widget.wallet['id'],
            'agent_id': selectedAgent!.id,
            'transaction_pin':pin,
            "exchange_type": "buy",
            'exchange_amount': enteredAmount,
            // 'coin_quantity': coinQuantity,
            //  'buy_rate': selectedAgent!.tradingRates['cc-cbc-buy-rate'],
          }
      );

      if (response['status'] == true) {
        final data = response['data'];
        final trader = data['trader'];
        final agent = data['agent'];

        setState(() {
          /// Transaction summary for the buyer
          buyerDebitWalletNumber = trader['debit']['wallet_number'];
          buyerDebitCurrency = trader['debit']['currency_code'];
          buyerDebitSymbol = trader['debit']['currency_symbol'];
          buyerDebitAmount = trader['debit']['amount'];

          buyerCreditWalletNumber = trader['credit']['wallet_number'];
          buyerCreditCurrency = trader['credit']['currency_code'];
          buyerCreditSymbol = trader['credit']['currency_symbol'];
          buyerCreditAmount = trader['credit']['amount'];

          exchangeType = data['exchange_type'];
          exchangeRate = agent['exchange_rates']['buy_rate'];

          agentId = agent['id']; // You may later fetch agent name if needed.

          currentStep = 2; // Move to Confirm & Pay page
        });
      } else {
        _showErrorSnackbar('Something went wrong: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackbar('Something went wrong: $e');
    } finally {
      setState(() {
        isConfirmingPayment = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Solar Coin',style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(32),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: Colors.grey[200]!),

              ),

              child: Column(

                children: [

                  Text(

                    "Source Wallet",

                    style: TextStyle(

                      fontSize: 16,

                      color: Colors.grey[600],

                      fontWeight: FontWeight.w500,

                    ),

                  ),

                  const SizedBox(height: 8),

                  Text(



                    widget.wallet['currency']+ NumberFormat("#,##0.00")

                        .format(double.tryParse(widget.wallet['balance'].toString())),





                    style: const TextStyle(

                      fontSize: 32,

                      fontWeight: FontWeight.bold,

                      color: Colors.black87,

                    ),

                  ),

                  const SizedBox(height: 4),

                  Text(

                    'Account: '+ widget.wallet['wallet_number'],textAlign: TextAlign.center,

                    style: TextStyle(

                      fontSize: 18,

                      color: Colors.grey[600],

                      fontWeight: FontWeight.w500,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),



            // Progress indicator
            Container(
              padding: EdgeInsets.all(16),
          //    color: _primaryColor!.withOpacity(0.5),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Amount', currentStep >= 0),
                  Expanded(child: Divider()),
                  _buildStepIndicator(1, 'Agent', currentStep >= 1),
                  Expanded(child: Divider()),
                  _buildStepIndicator(2, 'Confirm', currentStep >= 2),
                ],
              ),
            ),
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ?_primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? _primaryColor : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _buildAmountStep();
      case 1:
        return _buildAgentSelectionStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return _buildAmountStep();
    }
  }

  // Step 1: Enter Amount
  Widget _buildAmountStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Enter Amount',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enter the amount you want to buy in Nigerian Naira (₦)',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 32),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (₦)',
              prefixText: '₦ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor!, width: 2),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _continueToAgentSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Select Agent
  Widget _buildAgentSelectionStep() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => currentStep = 0),
                icon: Icon(Icons.arrow_back, color: Colors.black),
              ),
              Text(
                'Step 2: Select Agent',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor!.withOpacity(.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: _primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Amount: ₦${enteredAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),
          Expanded(
            child: isLoadingAgents
                ? Center(child: CircularProgressIndicator())
                : agents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No agents available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchAgents,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: agents.length,
              itemBuilder: (context, index) {
                final agent = agents[index];
                return _buildAgentCard(agent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Agent agent) {
    double buyRate = agent.tradingRates['cc-cbc-buy-rate']?.toDouble() ?? 0;
    double maxBuyLimit = agent.tradingRates['cc-cbc-max-buy-limit']?.toDouble() ?? double.infinity;
    bool isAvailable = enteredAmount <= maxBuyLimit;

    return CupertinoCard(
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased for iOS spacing (16-24px typical)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, // Standard iOS avatar size
                  height: 48,
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      agent.firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: _secondaryColor,
                        fontWeight: FontWeight.w600, // iOS medium-bold
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // iOS horizontal spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18, // iOS heading size
                          height: 1.2, // Line height for readability
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${agent.id.substring(0, 8)}...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14, // Secondary label size
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? CupertinoColors.systemGreen.withOpacity(0.15)
                        : CupertinoColors.systemRed.withOpacity(0.15),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: isAvailable
                          ? CupertinoColors.systemGreen.withOpacity(0.3)
                          : CupertinoColors.systemRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: isAvailable
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Vertical spacing for clean separation
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy Rate',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₦$buyRate per coin',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'ll get',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(enteredAmount / buyRate).toStringAsFixed(4)} coins',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _secondaryColor, // iOS accent
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: isAvailable ? () => _selectAgent(agent) : null,
                borderRadius: const BorderRadius.all(Radius.circular(10)), // iOS button radius
                padding: const EdgeInsets.symmetric(vertical: 12), // Comfortable tap target
                color: isAvailable
                    ? _secondaryColor
                    : CupertinoColors.systemGrey3,
                disabledColor: CupertinoColors.systemGrey3,
                child: Text(
                  isAvailable ? 'Select Agent' : 'Limit Exceeded',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Step 3: Confirmation
  String? transactionPin; // <-- Add this to your State class

  Widget _buildConfirmationStep() {
    if (selectedAgent == null) return SizedBox();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Back Button & Title ---
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => currentStep = 1),
                icon: Icon(Icons.arrow_back, color: Colors.black),
              ),
              Text(
                'Step 3: Confirm & Pay',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          /// --- Title ---
          Text(
            'Transaction Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          /// --- Transaction Summary Card ---
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'You Pay',
                  '$buyerDebitSymbol${buyerDebitAmount?.toStringAsFixed(2) ?? '--'} '
                      '(${buyerDebitCurrency ?? ''})',
                ),
                Divider(),
                _buildSummaryRow(
                  'You Receive',
                  '${buyerCreditAmount?.toStringAsFixed(4) ?? '--'} ${buyerCreditCurrency ?? ''}',
                ),
                Divider(),
                _buildSummaryRow(
                  'Rate',
                  '1 ${buyerCreditCurrency ?? ''} = $buyerDebitSymbol${exchangeRate?.toStringAsFixed(2) ?? '--'}',
                ),
                /*
                Divider(),
                _buildSummaryRow(
                  'Agent Selected',
                  agentId ?? 'Unknown Agent',
                ),

                 */
              ],
            ),
          ),

          SizedBox(height: 24),

          /// --- PIN INPUT FIELD ---
          TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: "Transaction PIN",
              border: OutlineInputBorder(),
              counterText: "", // hides character counter
            ),
            onChanged: (value) {
              transactionPin = value;
            },
          ),

          SizedBox(height: 24),


          /// --- Confirm Button ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isConfirmingPayment
                  ? null
                  : () {
                if (transactionPin == null || transactionPin!.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter your 4-digit PIN')),
                  );
                  return;
                }
                _confirmPayment(transactionPin!); // pass pin to processor
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isConfirmingPayment
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
                  : Text(
                'Confirm & Pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

}

// Agent model class
class Agent {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final Map<String, dynamic> tradingRates;
  final String? profileImageUrl;

  Agent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.tradingRates,
    this.profileImageUrl,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      tradingRates: json['trading_rates'] ?? {},
      profileImageUrl: json['profile_image_url'],
    );
  }
}

class CupertinoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double elevation; // Subtle iOS-like shadow

  const CupertinoCard({
    super.key,
    required this.child,
    this.margin,
    this.borderRadius = 16.0,
    this.elevation = 1.0, // Low for iOS subtlety
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05), // Subtle iOS shadow
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}