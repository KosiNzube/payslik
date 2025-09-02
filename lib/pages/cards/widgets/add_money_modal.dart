import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/cards_controller.dart';

void showAddMoneyModal(BuildContext context, String cardId, Color? secondaryColor) async {
  final controller = Provider.of<VirtualCardController>(context, listen: false);
  await controller.fetchWallets();

  final amountController = TextEditingController();
  String selectedWalletId = "";

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) => Padding(
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
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter Amount", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Consumer<VirtualCardController>(
            builder: (context, controller, child) {
              return controller.sourceWallets.isEmpty
                  ? const CircularProgressIndicator()
                  : DropdownButton<String>(
                value: selectedWalletId.isEmpty ? null : selectedWalletId,
                hint: const Text("Select Wallet"),
                items: controller.sourceWallets.map((wallet) {
                  return DropdownMenuItem<String>(
                    value: wallet["wallet_number"],
                    child: Text("Wallet ${wallet["wallet_number"]} - ${wallet["balance"]} ${wallet["currency"]["symbol"]}"),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedWalletId = value ?? "";
                  (context as Element).markNeedsBuild();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0 || selectedWalletId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid amount and select wallet")),
                );
                return;
              }

              final result = await controller.addFundsToCard(
                cardId: cardId,
                amount: amount,
                walletId: selectedWalletId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor ?? Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Add Money"),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
