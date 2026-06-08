import 'package:flutter/material.dart';
import '../../core/constants/belt_levels.dart';
import 'belt_icon.dart';

class BeltBadge extends StatelessWidget {
  const BeltBadge({
    super.key,
    required this.belt,
    this.size = BeltBadgeSize.medium,
  });

  final BeltLevel belt;
  final BeltBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final double fontSize = switch (size) {
      BeltBadgeSize.small => 11,
      BeltBadgeSize.medium => 12,
      BeltBadgeSize.large => 14,
    };
    final EdgeInsets padding = switch (size) {
      BeltBadgeSize.small => const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      BeltBadgeSize.medium => const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      BeltBadgeSize.large => const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: belt.color,
        borderRadius: BorderRadius.circular(20),
        border: belt == BeltLevel.white
            ? Border.all(color: Colors.black54, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BeltIcon(belt: belt, size: fontSize + 3, color: belt.textColor),
          const SizedBox(width: 5),
          Text(
            belt.displayName,
            style: TextStyle(
              color: belt.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum BeltBadgeSize { small, medium, large }
