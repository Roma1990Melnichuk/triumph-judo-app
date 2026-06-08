import 'package:flutter/material.dart';

class TriumphEmblem extends StatelessWidget {
  const TriumphEmblem({super.key, required this.size, this.animated = true});

  final double size;
  // animated parameter kept for API compatibility but no longer used
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/triumph_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      ),
    );
  }
}
