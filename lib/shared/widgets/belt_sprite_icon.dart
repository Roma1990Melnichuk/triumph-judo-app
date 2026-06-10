import 'package:flutter/material.dart';
import '../../core/constants/belt_levels.dart';

/// Shows a belt illustration from the spritesheet (assets/belts/belts.webp).
/// Grid: 5 columns × 5 rows. We use rows 0–2 for our 12 belt levels.
class BeltSpriteIcon extends StatelessWidget {
  const BeltSpriteIcon({super.key, required this.belt, this.size = 64});

  final BeltLevel belt;
  final double size;

  static const int _cols = 5;

  // Grid position (col, row) for each belt level.
  // Matches the spritesheet layout (row 2, col 1 = brown-black, skipped).
  static (int, int) _pos(BeltLevel b) {
    switch (b) {
      case BeltLevel.white:        return (0, 0);
      case BeltLevel.whiteYellow:  return (1, 0);
      case BeltLevel.yellow:       return (2, 0);
      case BeltLevel.yellowOrange: return (3, 0);
      case BeltLevel.orange:       return (4, 0);
      case BeltLevel.orangeGreen:  return (0, 1);
      case BeltLevel.green:        return (1, 1);
      case BeltLevel.greenBlue:    return (2, 1);
      case BeltLevel.blue:         return (3, 1);
      case BeltLevel.blueBrown:    return (4, 1);
      case BeltLevel.brown:        return (0, 2);
      case BeltLevel.black:        return (2, 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (col, row) = _pos(belt);

    // Scale the full image so each cell = size × size.
    // Shift left/up to show the correct cell.
    // Use scaleFactor > 1 to zoom into belt illustration and trim label strip.
    const scaleFactor = 1.22; // crops ~18% from bottom (label area)
    final imgW = size * _cols;
    final imgH = imgW; // spritesheet is roughly square

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -col * size,
              top: -row * size * scaleFactor,
              width: imgW,
              height: imgH * scaleFactor,
              child: Image.asset(
                'assets/belts/belts.webp',
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
