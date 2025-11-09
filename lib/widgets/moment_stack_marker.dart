import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'sticker_card.dart';

/// Stacked moment cards that appear on the map
class MomentStackMarker extends StatelessWidget {
  final String title;
  final List<String> imageUrls;
  final DateTime date;
  final VoidCallback? onTap;

  const MomentStackMarker({
    super.key,
    required this.title,
    required this.imageUrls,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked cards
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  // Back cards (showing stack effect)
                  if (imageUrls.length > 1)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Transform.rotate(
                        angle: 0.1,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (imageUrls.length > 2)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Transform.rotate(
                        angle: -0.08,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Front card with image
                  Positioned(
                    left: 0,
                    top: 0,
                    child: StickerCard(
                      backgroundColor: Colors.white,
                      rotation: -0.05,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrls.first,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.photo),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Date stamp
                  Positioned(
                    right: 0,
                    top: 0,
                    child: DateStamp(
                      day: date.day,
                      month: _getMonthAbbreviation(date.month),
                      backgroundColor: Colors.red,
                      rotation: 0.15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Title sticker
            StickerLabel(
              text: title.toUpperCase(),
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              rotation: -0.02,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}
