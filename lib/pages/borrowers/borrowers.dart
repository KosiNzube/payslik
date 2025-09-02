import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gobeller/pages/borrowers/property_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/property_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'SubscriptionHistoryPage.dart';
import 'package:gobeller/pages/property/property_history_page.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  Color _primaryColor = const Color(0xFF2BBBA4); // Add default color
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PropertyController>(context, listen: false);
      controller.fetchProperties();
      controller.fetchPropertyCategories();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('appSettingsData');

    if (settingsJson != null) {
      final settings = json.decode(settingsJson)['data'];
      final primaryColorHex = settings['customized-app-primary-color'] ?? '#2BBBA4';

      setState(() {
        _primaryColor = Color(int.parse(primaryColorHex.replaceAll('#', '0xFF')));
      });
    }
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
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          httpHeaders: const {
            'User-Agent': 'Flutter App',
            'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
          },
          placeholder: (context, url) => Container(
            width: 70,
            height: 70,
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
              width: 70,
              height: 70,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button

        title: const Text('Available Properties'),
        actions: [
          IconButton(
            icon:  Icon(CupertinoIcons.arrow_2_circlepath),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertyHistoryPage(),
                ),
              );
            },
          ),
          _buildCategoryButton(context),
        ],
      ),
      body: Consumer<PropertyController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No properties available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (controller.selectedCategoryId != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => controller.clearCategoryFilter(),
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filter'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              if (controller.selectedCategoryId != null)
                _buildActiveFilterBar(controller),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.properties.length,
                  itemBuilder: (context, index) {
                    final property = controller.properties[index];
                    final imageUrl = _getPropertyImageUrl(property);
                    final propertyName = property['name'] ?? 'Unnamed Property';
                    final propertyId = property['id']; // <-- Get the property ID here

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image and Title Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildPropertyImage(imageUrl, propertyName),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      propertyName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "₦${property['price']}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${property['payment_duration'] ?? '12'} mo • ${property['payment_cycle']}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Availability Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Available Stock",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              Text(
                                "${_formatQuantity(property!['quantity'])} ${property['uom'] ?? ''}",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubscriptionHistoryPage(propertyId: propertyId),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFFF5F5F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text("My Order", style: TextStyle(fontWeight: FontWeight.w500)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PropertyDetailPage(propertyId: propertyId),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: _primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text("View Details", style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    },
                ),
              ),
              if (controller.hasNextPage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ElevatedButton(
                    onPressed: () => controller.loadNextPage(),
                    child: controller.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load More'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context) {
    return Consumer<PropertyController>(
      builder: (context, controller, _) {
        if (controller.isCategoriesLoading) {
          return const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        if (controller.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.filter_list),
              if (controller.selectedCategoryId != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Filter by Category',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.3,
                maxChildSize: 0.85,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (controller.selectedCategoryId != null)
                            TextButton(
                              onPressed: () {
                                controller.clearCategoryFilter();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear Filter'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.category_outlined,
                                color: controller.selectedCategoryId == null 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey,
                              ),
                              title: Text(
                                'All Categories',
                                style: TextStyle(
                                  fontWeight: controller.selectedCategoryId == null 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: controller.selectedCategoryId == null
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                              ),
                              selected: controller.selectedCategoryId == null,
                              onTap: () {
                                controller.clearCategoryFilter();
                                Navigator.pop(context);
                              },
                              trailing: controller.selectedCategoryId == null
                                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                                  : null,
                            ),
                            const Divider(),
                            ...controller.categories.map((category) {
                              final isSelected = controller.isCategorySelected(category['id']);
                              return ListTile(
                                leading: Icon(
                                  Icons.check_circle_outline,
                                  color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey,
                                ),
                                title: Text(
                                  category['label'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).primaryColor : null,
                                  ),
                                ),
                                selected: isSelected,
                                onTap: () {
                                  controller.filterPropertiesByCategory(category['id']);
                                  Navigator.pop(context);
                                },
                                trailing: isSelected
                                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                                    : null,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveFilterBar(PropertyController controller) {
    final category = controller.getCategoryById(controller.selectedCategoryId);
    if (category == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered by: ${category['label']}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => controller.clearCategoryFilter(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            icon: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            label: Text(
              'Clear',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
