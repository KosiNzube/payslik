import 'package:flutter/material.dart';
import 'package:gobeller/controller/cards_controller.dart';

void showCreateCardModal(BuildContext context, VirtualCardController controller, Color? secondaryColor) {
  final pinController = TextEditingController();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return Padding(
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
              decoration: const InputDecoration(labelText: "Enter 4-digit PIN", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PIN must be exactly 4 digits")),
                  );
                  return;
                }

                Navigator.pop(context);
                // Fixed: Added the required context parameter
                final result = await controller.createVirtualCard(cardPin: pin, context: context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                }

                await controller.fetchVirtualCards();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor ?? Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Create Card"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}