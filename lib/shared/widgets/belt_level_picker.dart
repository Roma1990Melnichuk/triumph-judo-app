import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/belt_levels.dart';

/// Повертає варіант кольору поясу, який завжди видно на темному фоні.
/// Світлі кольори (білий, біло-жовтий) злегка притемнюємо,
/// темні (зелений, синій, коричневий, чорний) — освітлюємо.
Color _visibleOnDark(Color c) {
  final lum = c.computeLuminance();
  if (lum > 0.6) return Color.lerp(c, const Color(0xFF888888), 0.45)!;
  if (lum < 0.08) return Color.lerp(c, Colors.white, 0.55)!;
  return c;
}

/// Пікер поясу. Пояси до [value] відображаються як виконані (галочка),
/// [value] — як вибраний, наступні — як доступні для вибору.
class BeltLevelPicker extends StatelessWidget {
  const BeltLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BeltLevel value;
  final ValueChanged<BeltLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BeltLevel.values.map((b) {
        final selected = b == value;
        final isPast   = b.index < value.index;
        final accent   = _visibleOnDark(b.color);

        Color bgColor;
        Color borderColor;
        Color textColor;

        if (selected) {
          bgColor     = b.color;
          borderColor = b.color;
          textColor   = b.textColor;
        } else if (isPast) {
          // Тонкий тінт кольору поясу поверх темної поверхні
          bgColor     = Color.lerp(AppColors.surface3, b.color, 0.22)!;
          borderColor = accent.withValues(alpha: 0.8);
          textColor   = accent;
        } else {
          // Майбутній пояс — нейтральний темний чіп
          bgColor     = AppColors.surface2;
          borderColor = AppColors.surface3;
          textColor   = AppColors.textSecondary;
        }

        return GestureDetector(
          onTap: () => onChanged(b),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPast) ...[
                  Icon(Icons.check, size: 11, color: accent),
                  const SizedBox(width: 3),
                ],
                Text(
                  b.displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.bold
                        : isPast
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
