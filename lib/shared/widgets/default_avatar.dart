import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/child_model.dart';

/// Дефолтний аватар спортсмена коли фото відсутнє.
/// Показує стилізовану іконку дзюдоїста з кольором по статі або seed.
class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({
    super.key,
    required this.gender,
    required this.size,
    this.borderRadius,
    this.seed,
  });

  final Gender? gender;
  final double size;
  final BorderRadius? borderRadius;
  final String? seed;

  static const _maleColor   = Color(0xFF1565C0); // dark blue
  static const _femaleColor  = Color(0xFFAD1457); // deep pink
  static const _neutralColor = Color(0xFF546E7A); // blue-grey

  Color get _bgColor {
    if (seed != null) return AppColors.avatarColor(seed!);
    return switch (gender) {
      Gender.male   => _maleColor,
      Gender.female => _femaleColor,
      _             => _neutralColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.55;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.person,
            size: iconSize * 1.3,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

/// Кругла версія аватару для подіуму та рейтинг-списку.
class DefaultAvatarCircle extends StatelessWidget {
  const DefaultAvatarCircle({
    super.key,
    required this.gender,
    required this.radius,
    this.seed,
  });

  final Gender? gender;
  final double radius;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    return DefaultAvatar(
      gender: gender,
      size: radius * 2,
      borderRadius: BorderRadius.circular(radius),
      seed: seed,
    );
  }
}
