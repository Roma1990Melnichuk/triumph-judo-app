import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/achievement_model.dart';
import '../animations/app_animations.dart';

/// Shows achievement icon: PNG asset if exists, otherwise emoji fallback.
/// Asset path: assets/achievements/achievement_{id}.png
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({super.key, required this.def, this.size = 40});

  final AchievementDef def;
  final double size;

  String get _assetPath => 'assets/achievements/achievement_${def.id}.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _emojiIcon(),
      ),
    );
  }

  Widget _emojiIcon() => Center(
        child: Text(def.emoji,
            style: TextStyle(fontSize: size * 0.65)),
      );
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.def,
    this.earnedAt,
    this.small = false,
    this.locked = false,
    this.progress,
    this.progressHint,
  });

  final AchievementDef def;
  final DateTime? earnedAt;
  final bool small;
  final bool locked;
  /// 0.0–1.0 progress toward unlocking this achievement. null = unknown.
  final double? progress;
  /// Human-readable hint, e.g. "47 / 100". Shown only when [progress] ≠ null.
  final String? progressHint;

  // The rarity color (used for unlocked state and as the target color when lerping).
  Color get _rarityColor {
    switch (def.rarity) {
      case AchievementRarity.common:    return Colors.grey.shade600;
      case AchievementRarity.rare:      return Colors.green.shade600;
      case AchievementRarity.epic:      return Colors.blue.shade600;
      case AchievementRarity.legendary: return Colors.purple.shade600;
      case AchievementRarity.mythic:    return AppColors.accent;
    }
  }

  Color get _borderColor {
    if (!locked) return _rarityColor;
    // Lerp from surface3 toward rarity color as progress grows.
    final p = (progress ?? 0.0).clamp(0.0, 1.0);
    return Color.lerp(AppColors.surface3, _rarityColor, p)!;
  }

  Color get _bgColor {
    if (locked) return AppColors.surface2;
    switch (def.rarity) {
      case AchievementRarity.common:    return Colors.grey.shade900;
      case AchievementRarity.rare:      return Colors.green.shade900;
      case AchievementRarity.epic:      return Colors.blue.shade900;
      case AchievementRarity.legendary: return Colors.purple.shade900;
      case AchievementRarity.mythic:    return const Color(0xFF2A1A00);
    }
  }

  double get _opacity {
    if (!locked) return 1.0;
    final p = (progress ?? 0.0).clamp(0.0, 1.0);
    // 0% progress → 0.30 opacity; 100% progress → 0.88 opacity.
    return lerpDouble(0.30, 0.88, p)!;
  }

  bool get _hasProgress => locked && progress != null && progress! > 0;

  @override
  Widget build(BuildContext context) {
    return small ? _smallBadge() : _animatedFullBadge();
  }

  // ── Small badge ─────────────────────────────────────────────────────────────

  Widget _smallBadge() {
    return Opacity(
      opacity: _hasProgress ? _opacity : (locked ? 0.4 : 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  locked && def.isHidden
                      ? const Text('❓', style: TextStyle(fontSize: 14))
                      : AchievementIcon(def: def, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    locked && def.isHidden ? '???' : def.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          locked ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  if (_hasProgress && progressHint != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      progressHint!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _borderColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Progress bar strip at the bottom of the badge.
            if (_hasProgress)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(9),
                  bottomRight: Radius.circular(9),
                ),
                child: LinearProgressIndicator(
                  value: progress!,
                  minHeight: 3,
                  backgroundColor: AppColors.surface3.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(_borderColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Full badge ──────────────────────────────────────────────────────────────

  SeasonType? get _seasonType {
    switch (def.id) {
      case 'autumn_discipline': return SeasonType.autumn;
      case 'winter_discipline': return SeasonType.winter;
      case 'spring_discipline': return SeasonType.spring;
      case 'summer_discipline': return SeasonType.summer;
      default: return null;
    }
  }

  Widget _animatedFullBadge() {
    final badge = _fullBadge();
    if (locked) return LockedBreath(child: badge);

    final season = _seasonType;
    if (season != null) {
      return LightSweep(
        child: SeasonalParticles(type: season, child: badge),
      );
    }
    return LightSweep(child: badge);
  }

  Widget _fullBadge() {
    final effectiveOpacity = _hasProgress ? _opacity : (locked ? 0.45 : 1.0);

    return Opacity(
      opacity: effectiveOpacity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor, width: locked ? 1 : 1.5),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: _borderColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                locked && def.isHidden
                    ? const Text('❓', style: TextStyle(fontSize: 28))
                    : AchievementIcon(def: def, size: 40),
                const SizedBox(height: 6),
                Text(
                  locked && def.isHidden ? '???' : def.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        locked ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!locked) ...[
                  const SizedBox(height: 3),
                  Text(
                    def.rarity.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: _borderColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_hasProgress && progressHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    progressHint!,
                    style: TextStyle(
                      fontSize: 9,
                      color: _borderColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Thin progress arc overlaid on the badge when in-flight.
          if (_hasProgress)
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress!,
                strokeWidth: 2.5,
                backgroundColor: AppColors.surface3.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(
                  _borderColor.withValues(alpha: 0.8),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
        ],
      ),
    );
  }
}
