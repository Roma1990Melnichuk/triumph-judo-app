import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/meal_model.dart';

// ── Circular score gauge ───────────────────────────────────────────────────────

class NutritionScoreGauge extends StatelessWidget {
  const NutritionScoreGauge({
    super.key,
    required this.score,
    this.size = 130,
    this.strokeWidth = 10,
    this.child,
  });

  final double score;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(score: score, strokeWidth: strokeWidth),
        child: Center(child: child),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.score, required this.strokeWidth});
  final double score;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      rect, 0, math.pi * 2, false,
      Paint()
        ..color       = const Color(0xFF222222)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (score <= 0) return;

    final sweepAngle = math.pi * 2 * (score.clamp(0, 100) / 100);

    // Glow shadow
    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..color       = AppColors.orange.withValues(alpha: 0.30)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Arc fill with gradient
    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle:   startAngle + sweepAngle,
          colors:     const [AppColors.orange, Color(0xFFFFD060)],
        ).createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.score != score;
}

// ── Progress bar row (for plate elements) ─────────────────────────────────────

class PlateElementRow extends StatelessWidget {
  const PlateElementRow({
    super.key,
    required this.label,
    required this.emoji,
    required this.pct,
    this.color = AppColors.orange,
  });

  final String label;
  final String emoji;
  final double pct; // 0.0–1.0
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final pctInt = (pct * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    Text('$pctInt%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pct >= 0.8 ? color : AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF2A2A2A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          v >= 0.8 ? color : color.withValues(alpha: 0.55)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal status badge ──────────────────────────────────────────────────────────

class MealStatusBadge extends StatelessWidget {
  const MealStatusBadge(this.status, {super.key});
  final MealStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MealStatus.done    => ('Виконано',  AppColors.success),
      MealStatus.skipped => ('Пропущено', AppColors.error),
      MealStatus.pending => ('Очікується', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Plate dot badges (protein/veg/carbs/fruits/water) ─────────────────────────

class PlateDots extends StatelessWidget {
  const PlateDots(this.meal, {super.key});
  final MealModel meal;

  static const _items = [
    ('🥩', 'Б'), ('🥦', 'О'), ('🌾', 'В'), ('🍎', 'Ф'), ('💧', 'В'),
  ];

  @override
  Widget build(BuildContext context) {
    final checks = [
      meal.hasProtein, meal.hasVegetables, meal.hasCarbs,
      meal.hasFruits,  meal.hadWater,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_items.length, (i) {
        final active = checks[i];
        return Tooltip(
          message: _items[i].$1,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.orange.withValues(alpha: 0.2)
                  : const Color(0xFF2A2A2A),
              border: Border.all(
                color: active
                    ? AppColors.orange.withValues(alpha: 0.7)
                    : const Color(0xFF3A3A3A),
              ),
            ),
            child: Center(
              child: Text(_items[i].$2,
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.orange : AppColors.textSecondary)),
            ),
          ),
        );
      }),
    );
  }
}

// ── Quick stat chip ────────────────────────────────────────────────────────────

class QuickStatChip extends StatelessWidget {
  const QuickStatChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.done,
    this.onTap,
  });

  final String    emoji;
  final String    label;
  final bool      done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: done
              ? AppColors.orange.withValues(alpha: 0.12)
              : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? AppColors.orange.withValues(alpha: 0.45)
                : const Color(0xFF2C2C2C),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.orange : AppColors.textSecondary)),
            const SizedBox(height: 3),
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 12,
              color: done ? AppColors.orange : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class NutritionSectionHeader extends StatelessWidget {
  const NutritionSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String        title;
  final String?       action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange)),
            ),
        ],
      ),
    );
  }
}

// ── Surface card container ─────────────────────────────────────────────────────

class NutritionCard extends StatelessWidget {
  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    EdgeInsetsGeometry? margin,
  }) : _margin = margin;

  final Widget          child;
  final EdgeInsets?     padding;
  final VoidCallback?   onTap;
  final EdgeInsetsGeometry? _margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: _margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border:       Border.all(color: const Color(0xFF222222)),
        ),
        child: child,
      ),
    );
  }
}
