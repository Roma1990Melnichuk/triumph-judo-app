import 'package:flutter/material.dart';

enum TIcon {
  team,
  athlete,
  coach,
  medal,
  trophy,
  rating,
  search,
  notifications,
  calendar,
  settings,
  training,
  tournament,
  achievements,
  belts,
  motivation,
  statistics,
  experience,
  tasks,
  profile,
  club,
  info,
  sparring,
  cpu,
  records,
  category,
  news,
  video,
  security,
  // batch_03
  goals,
  home,
  back,
  filter,
  // batch_04
  add,
  edit,
  delete,
  chart,
  reminder,
  success,
  warning,
  error,
  help,
  pushups,
}

class TriumphIcon extends StatelessWidget {
  const TriumphIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
  });

  final TIcon icon;
  final double size;
  final Color? color;

  static String _assetPath(TIcon icon) {
    return 'assets/icons/ti_${icon.name}.png';
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      _assetPath(icon),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: img,
      );
    }

    return img;
  }
}
