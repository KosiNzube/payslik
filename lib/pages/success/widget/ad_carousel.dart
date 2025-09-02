// lib/widgets/ad_carousel.dart

import 'package:flutter/material.dart';

class AdCarousel extends StatelessWidget {
  final List<String> ads;

  const AdCarousel({Key? key, required this.ads}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return const SizedBox.shrink(); // Return nothing if no ads
    }

    return SizedBox(
      height: 150,
      child: PageView.builder(
        itemCount: ads.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ads[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          );
        },
      ),
    );
  }
}
