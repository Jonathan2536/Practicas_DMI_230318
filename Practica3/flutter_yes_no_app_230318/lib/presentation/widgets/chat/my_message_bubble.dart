import 'package:flutter/material.dart';

class MyMessageBubble extends StatelessWidget {
  final String text;
  final DateTime sentAt;

  const MyMessageBubble({super.key, required this.text, required this.sentAt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(text, style: TextStyle(color: colors.onPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    TimeOfDay.fromDateTime(sentAt).format(context),
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 11,
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
