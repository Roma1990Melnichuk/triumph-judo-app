import 'package:flutter/material.dart';
import '../../core/constants/belt_levels.dart';

class BeltIcon extends StatelessWidget {
  const BeltIcon({
    super.key,
    required this.belt,
    this.size = 32,
    this.color,
  });

  final BeltLevel belt;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BeltKnotPainter(
          primary: color ?? belt.color,
          secondary: color != null ? null : belt.secondaryColor,
          isWhite: belt == BeltLevel.white,
        ),
      ),
    );
  }
}

class _BeltKnotPainter extends CustomPainter {
  const _BeltKnotPainter({
    required this.primary,
    this.secondary,
    this.isWhite = false,
  });

  final Color primary;
  final Color? secondary;
  final bool isWhite;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final p1 = Paint()
      ..color = primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final p2 = Paint()
      ..color = secondary ?? primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final knot = Paint()
      ..color = Color.lerp(primary, Colors.black, 0.30)!
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final border = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    // ── Left belt half ──────────────────────────────────────────
    final leftPath = Path()
      ..addRRect(RRect.fromLTRBR(
        0, cy - h * 0.22,
        cx - w * 0.12, cy + h * 0.22,
        Radius.circular(h * 0.18),
      ));
    canvas.drawPath(leftPath, p1);

    // ── Right belt half (secondary color for two-tone) ──────────
    final rightPath = Path()
      ..addRRect(RRect.fromLTRBR(
        cx + w * 0.12, cy - h * 0.22,
        w, cy + h * 0.22,
        Radius.circular(h * 0.18),
      ));
    canvas.drawPath(rightPath, p2);

    // ── Central knot ─────────────────────────────────────────────
    final knotRect = RRect.fromLTRBR(
      cx - w * 0.18, cy - h * 0.34,
      cx + w * 0.18, cy + h * 0.34,
      const Radius.circular(3),
    );
    canvas.drawRRect(knotRect, knot);

    // Highlight line on knot
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - w * 0.12, cy - h * 0.18),
      Offset(cx + w * 0.12, cy - h * 0.18),
      highlight,
    );

    // Border for white belt (otherwise invisible on light bg)
    if (isWhite) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, cy - h * 0.22, cx - w * 0.12, cy + h * 0.22,
            Radius.circular(h * 0.18)),
        border,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(cx + w * 0.12, cy - h * 0.22, w, cy + h * 0.22,
            Radius.circular(h * 0.18)),
        border,
      );
    }
  }

  @override
  bool shouldRepaint(_BeltKnotPainter old) =>
      old.primary != primary || old.secondary != secondary;
}
