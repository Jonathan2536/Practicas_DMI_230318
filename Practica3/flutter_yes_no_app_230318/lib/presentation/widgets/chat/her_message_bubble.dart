import 'package:flutter/material.dart';

class HerMessageBubble extends StatelessWidget {
  final String text;
  final DateTime sentAt;
  final String? imageUrl;

  const HerMessageBubble({
    super.key,
    required this.text,
    required this.sentAt,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final imageWidth = MediaQuery.sizeOf(context).width * 0.68;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: TextStyle(color: colors.onSecondary)),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl!,
                        width: imageWidth,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          final totalBytes = loadingProgress.expectedTotalBytes;
                          return SizedBox(
                            width: imageWidth,
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: totalBytes == null
                                    ? null
                                    : loadingProgress.cumulativeBytesLoaded /
                                          totalBytes,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => SizedBox(
                          width: imageWidth,
                          height: 100,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      TimeOfDay.fromDateTime(sentAt).format(context),
                      style: TextStyle(
                        color: colors.onSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
