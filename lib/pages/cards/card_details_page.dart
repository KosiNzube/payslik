import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controller/cards_controller.dart';

class CardDetailsPage extends StatefulWidget {
  final Map<String, dynamic> card;

  const CardDetailsPage({super.key, required this.card});

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCardDetails();
  }

  Future<void> _fetchCardDetails() async {
    try {
      final controller = Provider.of<VirtualCardController>(context, listen: false);
      await controller.fetchCardBalanceDetails(widget.card["id"]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to fetch card details: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String cardId = widget.card["id"] ?? "";
    final String cardNumber = widget.card["card_number"] ?? "**** **** **** ****";
    final String expiryDate = widget.card["expiration_date"] ?? "--/--";
    final String cvv = jsonDecode(widget.card["card_response_metadata"] ?? '{}')["cvv"] ?? "***";
    final String name = jsonDecode(widget.card["card_response_metadata"] ?? '{}')["name"] ?? "Card Holder";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Card Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchCardDetails();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Card Holder", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),
                const Text("Card Number", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cardNumber,
                        style: const TextStyle(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cardNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Card number copied to clipboard")),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Expiry", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(expiryDate, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CVV", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(cvv, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  "The Card Address is the same as your residential address for online transaction or purchase",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Balance and Address Section
                Consumer<VirtualCardController>(
                  builder: (context, controller, _) {
                    if (_isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (_error != null) {
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _error = null;
                                });
                                _fetchCardDetails();
                              },
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      );
                    }

                    final cardInfo = controller.cardDetails[cardId];
                    if (cardInfo == null) {
                      return const Center(
                        child: Text(
                          "No card details available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final balance = cardInfo["balance"];
                    final address = cardInfo["address"];
                    final street = address?["street"] ?? "N/A";
                    final city = address?["city"] ?? "N/A";
                    final state = address?["state"] ?? "N/A";
                    final postalCode = address?["postal_code"] ?? "N/A";
                    final country = address?["country"] ?? "N/A";

                    String balanceText;
                    if (balance == null || (balance is num && balance == 0)) {
                      balanceText = "No Balance Available";
                    } else {
                      balanceText = "\$${balance.toString()}";
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Balance", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: balanceText == "No Balance Available" ? Colors.red : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text("Address", style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          "$street, $city, $state, $postalCode, $country",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Text(
                  "This is your virtual card detail. Keep your card data secure and do not share sensitive information.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
