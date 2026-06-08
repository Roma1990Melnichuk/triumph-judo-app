import 'package:flutter/material.dart';

enum BeltLevel {
  white,
  whiteYellow,
  yellow,
  yellowOrange,
  orange,
  orangeGreen,
  green,
  greenBlue,
  blue,
  blueBrown,
  brown,
  black,
}

extension BeltLevelX on BeltLevel {
  String get displayName {
    switch (this) {
      case BeltLevel.white:
        return 'Білий';
      case BeltLevel.whiteYellow:
        return 'Біло-жовтий';
      case BeltLevel.yellow:
        return 'Жовтий';
      case BeltLevel.yellowOrange:
        return 'Жовто-помаранчевий';
      case BeltLevel.orange:
        return 'Помаранчевий';
      case BeltLevel.orangeGreen:
        return 'Помаранчево-зелений';
      case BeltLevel.green:
        return 'Зелений';
      case BeltLevel.greenBlue:
        return 'Зелено-синій';
      case BeltLevel.blue:
        return 'Синій';
      case BeltLevel.blueBrown:
        return 'Синьо-коричневий';
      case BeltLevel.brown:
        return 'Коричневий';
      case BeltLevel.black:
        return 'Чорний (Дан)';
    }
  }

  Color get color {
    switch (this) {
      case BeltLevel.white:
        return const Color(0xFFF5F5F5);
      case BeltLevel.whiteYellow:
        return const Color(0xFFFFF176);
      case BeltLevel.yellow:
        return const Color(0xFFFFD600);
      case BeltLevel.yellowOrange:
        return const Color(0xFFFFB300);
      case BeltLevel.orange:
        return const Color(0xFFFF6D00);
      case BeltLevel.orangeGreen:
        return const Color(0xFF8BC34A);
      case BeltLevel.green:
        return const Color(0xFF2E7D32);
      case BeltLevel.greenBlue:
        return const Color(0xFF29B6F6);
      case BeltLevel.blue:
        return const Color(0xFF1565C0);
      case BeltLevel.blueBrown:
        return const Color(0xFF795548);
      case BeltLevel.brown:
        return const Color(0xFF4E342E);
      case BeltLevel.black:
        return const Color(0xFF212121);
    }
  }

  Color get textColor {
    switch (this) {
      case BeltLevel.white:
      case BeltLevel.whiteYellow:
      case BeltLevel.yellow:
      case BeltLevel.yellowOrange:
      case BeltLevel.orange:
      case BeltLevel.orangeGreen:
      case BeltLevel.greenBlue:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  String get abbreviation {
    switch (this) {
      case BeltLevel.white:
        return 'Б';
      case BeltLevel.whiteYellow:
        return 'БЖ';
      case BeltLevel.yellow:
        return 'Ж';
      case BeltLevel.yellowOrange:
        return 'ЖП';
      case BeltLevel.orange:
        return 'П';
      case BeltLevel.orangeGreen:
        return 'ПЗ';
      case BeltLevel.green:
        return 'З';
      case BeltLevel.greenBlue:
        return 'ЗС';
      case BeltLevel.blue:
        return 'С';
      case BeltLevel.blueBrown:
        return 'СК';
      case BeltLevel.brown:
        return 'К';
      case BeltLevel.black:
        return 'Дан';
    }
  }

  /// Second color for two-tone belts, null for single-color.
  Color? get secondaryColor {
    switch (this) {
      case BeltLevel.whiteYellow:  return const Color(0xFFFFD600);
      case BeltLevel.yellowOrange: return const Color(0xFFFF6D00);
      case BeltLevel.orangeGreen:  return const Color(0xFF2E7D32);
      case BeltLevel.greenBlue:    return const Color(0xFF1565C0);
      case BeltLevel.blueBrown:    return const Color(0xFF4E342E);
      default: return null;
    }
  }

  BeltLevel? get next {
    final idx = BeltLevel.values.indexOf(this);
    if (idx >= BeltLevel.values.length - 1) return null;
    return BeltLevel.values[idx + 1];
  }

  bool get isLast => next == null;

  static BeltLevel fromString(String value) {
    return BeltLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BeltLevel.white,
    );
  }
}
