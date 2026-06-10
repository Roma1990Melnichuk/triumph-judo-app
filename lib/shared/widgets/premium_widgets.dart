import 'dart:math' show min;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ── 1. GLASSMORPHISM CARD ───────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.borderWidth = 1.0,
    this.blur = 12.0,
    this.opacity = 0.05,
    this.margin,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── 2. CIRCULAR PROGRESS PAINTER ──────────────────────────────────────────────

class AthleteProgressPainter extends CustomPainter {
  const AthleteProgressPainter({
    required this.progress, // 0.0 to 1.0
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 3.5;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.surface3.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with glow
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Shadow/Glow effect
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(AthleteProgressPainter old) =>
      old.progress != progress || old.color != color;
}

class AthleteProgressCircle extends StatelessWidget {
  const AthleteProgressCircle({
    super.key,
    required this.progress,
    required this.color,
    this.size = 44,
    this.child,
  });

  final double progress;
  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: AthleteProgressPainter(progress: progress, color: color),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ── 3. GLOW ICON FOR NAVIGATION ──────────────────────────────────────────────

class GlowIcon extends StatelessWidget {
  const GlowIcon({
    super.key,
    required this.icon,
    this.size = 26.0,
    this.color = AppColors.orange,
    this.isActive = false,
  });

  final Widget icon;
  final double size;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return icon;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Real soft glow instead of box shadow
        Container(
          width: size * 1.5,
          height: size * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.4),
                color.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // The icon itself
        icon,
      ],
    );
  }
}
