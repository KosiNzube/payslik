import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/cards_controller.dart';
import 'add_money_modal.dart';

class CardView extends StatelessWidget {
  final Map<String, dynamic> card;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CardView({
    super.key,
    required this.card,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final String cardNumber = card["masked_card_number"] ?? "**** **** **** ****";
    final String expiryDate = card["expiration_date"] ?? "--/--";
    final metadata = jsonDecode(card["card_response_metadata"] ?? '{}');
    final String cvv = metadata["cvv"] ?? "***";
    final String name = metadata["name"] ?? "Card Holder";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)],
            ),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Virtual Card", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Text(cardNumber, style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2.0)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Exp: $expiryDate", style: const TextStyle(color: Colors.white70)),
                    Text("CVV: $cvv", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActions(context, card),
          const SizedBox(height: 20),
          const Text("", style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Map<String, dynamic> card) {
    final controller = Provider.of<VirtualCardController>(context, listen: false);
    final isLocked = card["is_amount_locked"] == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.info_outline,
          label: "Details",
          color: primaryColor,
          onTap: () => Navigator.pushNamed(context, Routes.card_details, arguments: card),
        ),
        _actionButton(
          icon: Icons.account_balance_wallet_outlined,
          label: "Add Money",
          color: primaryColor,
          onTap: () => showAddMoneyModal(context, card["id"], secondaryColor),
        ),
        _actionButton(
          icon: isLocked ? Icons.lock_open : Icons.lock_outline,
          label: isLocked ? "Unfreeze" : "Freeze",
          color: primaryColor,
          onTap: () async {
            final result = await controller.toggleCardLockStatus(card["id"], isLocked);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: color?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
            foregroundColor: color ?? Colors.blue,
            radius: 28,
            child: Icon(icon),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
