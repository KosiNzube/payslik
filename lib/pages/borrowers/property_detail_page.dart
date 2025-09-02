import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/property_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'InitiateSubscriptionScreen.dart';
import 'SubscriptionHistoryPage.dart';

class PropertyDetailPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  Map<String, dynamic>? property;
  bool isLoading = true;
  Color? _primaryColor;
  Color? _secondaryColor;
  String? _logoUrl;



  Future<void> _loadPrimaryColorAndLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      try {
        final settings = json.decode(settingsJson);
        final data = settings['data'] ?? {};

        setState(() {
          final primaryColorHex = data['customized-app-primary-color'];
          final secondaryColorHex = data['customized-app-secondary-color'];

          _primaryColor = primaryColorHex != null
              ? Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blue;

          _secondaryColor = secondaryColorHex != null
              ? Color(int.parse(secondaryColorHex.replaceAll('#', '0xFF')))
              : Colors.blueAccent;

          _logoUrl = data['customized-app-logo-url'];
        });
      } catch (_) {}
    }
  }
  @override
  void initState() {
    super.initState();
    _loadProperty();
    _loadPrimaryColorAndLogo();
  }

  Future<void> _loadProperty() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    final result = await controller.fetchPropertyDetails(widget.propertyId);
    setState(() {
      property = result;
      isLoading = false;
    });
  }

  // Helper method to format quantity (remove .00 if it's a whole number)
  String _formatQuantity(dynamic quantity) {
    if (quantity == null) return '0';

    // Convert to double first, then check if it's a whole number
    double quantityDouble = double.tryParse(quantity.toString()) ?? 0.0;

    if (quantityDouble == quantityDouble.toInt()) {
      // It's a whole number, return as integer
      return quantityDouble.toInt().toString();
    } else {
      // It has decimal places, return as is
      return quantityDouble.toString();
    }
  }

  // Helper method to get quantity as integer
  int _getQuantityAsInt(dynamic quantity) {
    if (quantity == null) return 1;

    // Convert to double first, then to int
    double quantityDouble = double.tryParse(quantity.toString()) ?? 1.0;
    return quantityDouble.toInt();
  }

  // Helper method to get the preferred image URL from property attachments
  String _getPropertyImageUrl(Map<String, dynamic> property) {
    final attachments = property['property_attachments'] as List<dynamic>?;

    if (attachments == null || attachments.isEmpty) {
      return 'https://via.placeholder.com/80x80.png?text=No+Image';
    }

    // First, try to find the preferred item
    final preferredAttachment = attachments.firstWhere(
          (attachment) => attachment['is_preferred_item'] == true,
      orElse: () => null,
    );

    String imageUrl;
    if (preferredAttachment != null) {
      imageUrl = preferredAttachment['attachment_open_url'] ?? 'https://via.placeholder.com/80x80.png?text=No+Image';
    } else {
      // If no preferred item, use the first attachment
      imageUrl = attachments.first['attachment_open_url'] ?? 'https://via.placeholder.com/80x80.png?text=No+Image';
    }

    // Add a timestamp to prevent caching issues
    if (imageUrl.startsWith('http')) {
      imageUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return imageUrl;
  }

  // Custom image widget with fallback options
  Widget _buildPropertyImage(String imageUrl, String propertyName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,  // Increased size for detail page
        height: 100, // Increased size for detail page
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          httpHeaders: const {
            'User-Agent': 'Flutter App',
            'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
          },
          placeholder: (context, url) => Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            print('Failed to load image: $url');
            print('Error: $error');
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : property == null
          ? const Center(child: Text('Failed to load property details.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top image and title
                  Row(
                    children: [
                      _buildPropertyImage(
                        _getPropertyImageUrl(property!),
                        property!['name'] ?? 'Unnamed Property',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property!['name'] ?? 'Unnamed Property',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₦${property!['price']} | ${property!['payment_cycle']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionHistoryPage(propertyId: widget.propertyId),
                              ),
                            );
                          },
                          child: const Text("Payment history"),
                        ),
                      ),
                      const SizedBox(width: 12), // spacing between the buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InitiateSubscriptionScreen(
                                  propertyId: widget.propertyId,
                                  quantity: _getQuantityAsInt(property!['quantity']),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Subscribe"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Plan Details Section
                  const Text(
                    "Plan details",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _buildDetailRow("Purchase amount", "₦${property!['price']}"),
                  _buildDetailRow("Payment Plan", "${property!['payment_cycle']}"),
                  _buildDetailRow("Interest", "%"+ "${property!['interest']}"),
                  _buildDetailRow(
                      "Available Stock",
                      "${_formatQuantity(property!['quantity'])}${property!['uom'] ?? ''}"
                  ), // Use helper method to format quantity
                  _buildDetailRow("Discount", "${property!['discount_pct']}"),
                  _buildDetailRow(
                    "Installmental Payment",
                    property!['allow_payment_installment'] == true ? "Allowed" : "Not Allowed",
                    valueColor: property!['allow_payment_installment'] == true ? Colors.green : Colors.red,
                  ),

                  _buildDetailRow(
                    "Description",
                    property!['property_attachments'].isNotEmpty
                        ? property!['property_attachments'][0]['description'] ?? "No description"
                        : "No description",
                    isDescription: true,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitiateSubscriptionScreen(
                        propertyId: widget.propertyId,
                        quantity: _getQuantityAsInt(property!['quantity']),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, // Use the dynamic primary color
                  foregroundColor: Colors.white,  // White text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Subscribe"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        bool isDescription = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black,
                fontSize: isDescription ? 13 : null,
              ),
              softWrap: true,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}