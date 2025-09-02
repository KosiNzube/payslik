import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/controller/cards_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../../controller/kyc_controller.dart';
import '../../controller/wallet_transfer_controller.dart';
import '../../utils/routes.dart';
import '../success/widget/transaction_list.dart';
import '../success/widget/transaction_list_card.dart';

class VirtualCardPage extends StatefulWidget {
  const VirtualCardPage({super.key});

  @override
  _VirtualCardPageState createState() => _VirtualCardPageState();
}

class _VirtualCardPageState extends State<VirtualCardPage> {
  bool _shouldShowKycButton = false;
  bool _kycLoading = true;

  Color? _primaryColor;
  Color? _secondaryColor;
  bool _isLoading = false; // Add this at the top of your StatefulWidget class
  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
    _checkKycStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VirtualCardController>(context, listen: false).fetchVirtualCards();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<WalletTransferController>(context, listen: false);
      controller.fetchSourceWallets();
      controller.clearBeneficiaryName();
    });
  }


  void _checkKycStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('cached_kyc_data');

    bool shouldShowKyc = true;

    if (rawData != null) {
      try {
        final List<dynamic> kycVerifications = json.decode(rawData);
        final usedTypes = kycVerifications
            .map((e) => (e['documentType'] as String?)?.toUpperCase())
            .whereType<String>()
            .toList();

        // Check if both BVN and NIN exist
        shouldShowKyc = !(usedTypes.contains('NIN') && usedTypes.contains('BVN'));
      } catch (e) {
        debugPrint("❌ Failed to parse cached_kyc_data: $e");
        shouldShowKyc = true; // fallback to showing KYC
      }
    }

    setState(() {
      _shouldShowKycButton = shouldShowKyc;
      _kycLoading = false;
    });
  }



  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final Map<String, dynamic> settings = json.decode(settingsJson);
      final data = settings['data'] ?? {};

      final primaryColorHex = data['customized-app-primary-color'] ?? "#2196F3";
      final secondaryColorHex = data['customized-app-secondary-color'] ?? "#1976D2";

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
        _secondaryColor = Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')));
      });
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false, // <-- Now it supports disabling
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            backgroundColor: _primaryColor?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
            foregroundColor: _primaryColor ?? Colors.blue,
            radius: 28,
            child: Icon(icon, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<VirtualCardController>(context);
    final transferController = Provider.of<WalletTransferController>(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCachedKycData(), // 👇 Replace API call with cached data
      builder: (context, snapshot) {
        final kycData = snapshot.data ?? [];

        final usedTypes = kycData
            .map((item) => (item['documentType'] as String?)?.toUpperCase())
            .whereType<String>()
            .toList();

        final bool hasBvn = usedTypes.contains('BVN');
        final bool hasNin = usedTypes.contains('NIN');
        final bool isKycComplete = hasBvn && hasNin;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, // This removes the back button

            title: const Text("Virtual Card"),
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: controller.virtualCards.isEmpty
                    ? Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : isKycComplete
                      ? ElevatedButton.icon(
                    onPressed: () => _showCreateCardModal(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Virtual Card"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor ?? Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text("Complete KYC"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
                    : _buildCardContent(controller.virtualCards.first,transferController),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getCachedKycData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('cached_kyc_data');

    if (rawData != null) {
      try {
        final List<dynamic> parsed = json.decode(rawData);
        return parsed.cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint("❌ Failed to parse cached KYC data: $e");
      }
    }
    return [];
  }




  Widget _buildCardContent(Map<String, dynamic> card, tcontroller) {
    final metadataRaw = card["card_response_metadata"];
    final decodedMeta = metadataRaw != null ? jsonDecode(metadataRaw) : {};
    final String cardNumber = card["masked_card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final String cvv = decodedMeta["cvv"] ?? "***";
    final String name = decodedMeta["name"] ?? "Card Holder";
    final String currency = card["currency"] ?? "NGN";
    final dynamic balanceRaw = card["balance"];
    final String balance = balanceRaw != null ? balanceRaw.toString() : "--";

    // Whether the card is currently merchant-locked (frozen)
    final bool isLocked = card["is_amount_locked"] == true;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Information Section - iOS inspired glass card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _secondaryColor!.withOpacity(0.5),
                    _secondaryColor!.withOpacity(0.9),
                  ],
                  stops: [0.0, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        "Virtual Card",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:  Text(
                          "VISA",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    cardNumber,
                    style:  GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "EXPIRES",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expiryDate,
                            style:  GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "CVV",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cvv,
                            style:  GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.toUpperCase(),
                    style:  GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
      
            // Action buttons - iOS style with haptic feedback feel
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildIOSActionButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.card_details,
                          arguments: card,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildIOSActionButton(
                      icon: Icons.wallet,
                      label: 'Add Money',
                      onTap: isLocked
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Your card is frozen. Please unfreeze it to add money.",
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                          : () => _showAddMoneyModal(context, card,tcontroller),
                      isDisabled: isLocked,
                    ),
                  ),
                  Expanded(
                    child: _buildIOSActionButton(
                      icon: isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      label: isLocked ? 'Unfreeze' : 'Freeze',
                      onTap: () async {
                        final rootCtx = context;
                        final scaffold = ScaffoldMessenger.of(rootCtx);
                        final controller = Provider.of<VirtualCardController>(rootCtx, listen: false);
      
                        final dialogCtx = await _showLoadingDialog(rootCtx);
      
                        try {
                          final result = await controller.toggleCardLockStatus(
                            card["id"],
                            isLocked,
                          );
      
                          if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
      
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(result),
                              backgroundColor: result.toLowerCase().contains("success")
                                  ? Colors.green
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      isDestructive: !isLocked,
                    ),
                  ),
                ],
              ),
            ),
      
            // Extra info if card is locked - iOS alert style
            if (isLocked) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Your card is frozen. Unfreeze to perform transactions.",
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
      
            const SizedBox(height: 15),
            const TransactionListCard(),
            const SizedBox(height: 5),

          ],
        ),
      ),
    );
  }


  Widget _buildIOSActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDisabled ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDisabled
                  ? Colors.grey[400]
                  : isDestructive
                  ? Colors.red[600]
                  : Colors.blue[600],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? Colors.grey[400]
                    : isDestructive
                    ? Colors.red[600]
                    : Colors.blue[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  void _showAddMoneyModal(BuildContext context, Map<String, dynamic> card, WalletTransferController transferController) {
    final BuildContext rootContext = context; // Save the parent context
    final TextEditingController amountController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);
    final controller = Provider.of<VirtualCardController>(rootContext, listen: false);
    final TextEditingController pinController = TextEditingController();

    String? selectedWallet;

    controller.fetchWallets();

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Consumer<VirtualCardController>(
            builder: (context, controller, child) {
              final wallets = transferController.sourceWallets;
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Add Money to Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    wallets.isEmpty
                        ? const CircularProgressIndicator()
                        :               DropdownButtonFormField<String>(
                      isExpanded: true,

                      value: selectedWallet,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: transferController.sourceWallets.map((wallet) {
                        return DropdownMenuItem<String>(

                          value: wallet['account_number'],
                          child: Text(
                            "${wallet['account_number']} - (${wallet['currency_symbol'] + wallet['available_balance']}"+")",
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedWallet = value),
                      validator: (value) => value == null ? "Please select a source wallet" : null,
                    ),



                    /*
                    DropdownButtonFormField<String>(
                      value: selectedWallet,
                      items: wallets.map((wallet) {
                        final walletName = wallet["name"] ?? "Wallet";
                        final walletNumber = wallet["wallet_number"] ?? "";
                        final uuid = wallet["id"] ?? "";

                        return DropdownMenuItem<String>(
                          value: walletNumber.isNotEmpty ? walletNumber : uuid,
                          child: Text("$walletName - $walletNumber"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedWallet = value;
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Source Wallet",
                        border: OutlineInputBorder(),
                      ),
                    ),


                     */
                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Enter Amount",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Enter 4-digit PIN",
                        counterText: "",  // Hides the character counter
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        final amountText = amountController.text.trim();
                        if (selectedWallet == null || amountText.isEmpty || double.tryParse(amountText) == null) {
                          print("xxx");
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text("Please select a wallet and enter valid amount")),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close bottom sheet

                        final dialogContext = await _showLoadingDialog(rootContext);

                        try {
                          final virtualCardId = card["id"] ?? "";

                          final initResponse = await controller.initiateCardFunding(
                            sourceWalletNumberOrUuid: selectedWallet!,
                            fundingAmount: double.parse(amountText),
                            virtualCardId: virtualCardId,
                          );

                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }

                          if (initResponse["status"] == true) {
                            final proceed = await _showFundingDetailsDialog(rootContext, initResponse["data"]);

                            if (proceed == true) {
                              // 🔥 ASK for PIN before processing funding

                              if (pinController.text != null) {
                                final processDialogContext = await _showLoadingDialog(rootContext);

                                final processResult = await controller.processCardFunding(
                                  sourceWalletNumberOrUuid: selectedWallet!,
                                  fundingAmount: double.parse(amountText),
                                  virtualCardId: virtualCardId,
                                  transactionPin: pinController.text, // Pass PIN here
                                );

                                if (Navigator.canPop(processDialogContext)) {
                                  Navigator.pop(processDialogContext);
                                }

                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(processResult),
                                    backgroundColor: processResult.contains("success") ? Colors.green : Colors.red,
                                  ),
                                );

                                if (processResult.contains("success")) {
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  controller.fetchVirtualCards();
                                }
                              }
                            }
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(initResponse["message"])),
                            );
                          }
                        } catch (e, stack) {
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text("Failed to fund card: ${e.toString()}")),
                          );
                          debugPrint("❌ Error funding card: $e");
                          debugPrintStack(stackTrace: stack);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Add Money"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  // FUND CARD DETAILS
  Future<bool?> _showFundingDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final sourceAmount = data["source_wallet_debit_amount"];
    final sourceCurrency = data["source_wallet_currency_symbol"];
    final destAmount = data["destination_card_final_amount"];
    final destCurrency = data["destination_card_currency_symbol"];
    final exchangeRate = data["exchange_rate"];

    final BuildContext rootContext = context; // Save the parent context
    final scaffoldMessenger = ScaffoldMessenger.of(rootContext);

    return showModalBottomSheet<bool>(
      context: rootContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Confirm Funding Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Display funding details in text format
                _buildDetailRow("Source Amount:", "$sourceCurrency$sourceAmount"),
                const SizedBox(height: 12),
                _buildDetailRow("Destination Amount:", "$destCurrency$destAmount"),
                const SizedBox(height: 12),
                _buildDetailRow("Exchange Rate:", "$exchangeRate"),
                const SizedBox(height: 24),

                // Proceed & Cancel buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Proceed"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper method to build a detail row with title and value
  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "$title ",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }


  // FUND CARD PIN MODAL


  // CREATE CARD MODAL
  void _showCreateCardModal(BuildContext context, VirtualCardController controller) {
    final TextEditingController pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Create Virtual Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: "Enter 4-digit PIN",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.length != 4) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text("PIN must be exactly 4 digits")),
                      );
                      return;
                    }

                    Navigator.pop(context); // Close bottom sheet first

                    // Now show loading dialog
                    final dialogContext = await _showLoadingDialog(context);

                    try {
                      final result = await controller.createVirtualCard(
                        context: dialogContext,
                        cardPin: pin,
                      );

                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext); // close the loading
                      }

                      // Now show success/failure message
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(result),
                          backgroundColor: result.contains("successfully") ? Colors.green : Colors.red,
                        ),
                      );

                      if (result.contains("successfully")) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        controller.fetchVirtualCards();
                      }

                    } catch (e, stack) {
                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext); // close loading
                      }

                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text("Failed to create card: ${e.toString()}")),
                      );

                      debugPrint("❌ Error creating card: $e");
                      debugPrintStack(stackTrace: stack);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryColor ?? Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Create Card"),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper function to show loading dialog properly
  Future<BuildContext> _showLoadingDialog(BuildContext context) async {
    final completer = Completer<BuildContext>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        completer.complete(ctx);
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        );
      },
    );

    return completer.future;
  }






  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return "/";
      case 1:
        return "/wallet";
      case 2:
        return "/virtualCard";
      case 3:
        return "/profile";
      default:
        return "/";
    }
  }
}
