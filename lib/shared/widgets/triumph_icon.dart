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
  // batch_05 — fitness exercises
  pullups,
  plank,
  squats,
  running,
  bicycle,
  jumpRope,
  throws,
  clear,
  sort,
  select,
  // batch_06 — food & nutrition
  checkbox,
  radio,
  breakfast,
  snack,
  lunch,
  dinner,
  protein,
  vegetables,
  grains,
  fruits,
  // 3D hero icons (for settings menu, full-color, no ColorFiltered)
  trophy3d,
  medal3d,
  calendar3d,
  training3d,
  motivation3d,
  // Special full-color icons (PNG)
  crown,
  // 3D icons batch-2 (PNG)
  bell3d, whistle3d, belts3d, scroll3d, location3d, gift3d,
  timer3d, lantern3d, shield3d, star3d, ref3d, clock3d,
  bellNotif3d, giftRed3d, dojo3d, dumbbell3d, flame3d, cert3d,
  stopwatch3d, memberCard3d, award3d, bag3d, emblem3d,
  trainer3d, family3d, premium3d,
  // 3D action icons (PNG)
  delete3d, edit3d, add3d, message3d,
  // 3D nav icons (PNG)
  settings3d,
  home3d,
  rating3d,
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

  static const _pngIcons = {
    TIcon.crown, TIcon.medal3d,
    TIcon.bell3d, TIcon.whistle3d, TIcon.belts3d, TIcon.scroll3d,
    TIcon.location3d, TIcon.gift3d, TIcon.timer3d, TIcon.lantern3d,
    TIcon.shield3d, TIcon.star3d, TIcon.ref3d, TIcon.clock3d,
    TIcon.bellNotif3d, TIcon.giftRed3d, TIcon.dojo3d, TIcon.dumbbell3d,
    TIcon.flame3d, TIcon.cert3d, TIcon.stopwatch3d, TIcon.memberCard3d,
    TIcon.award3d, TIcon.bag3d, TIcon.emblem3d, TIcon.trainer3d,
    TIcon.family3d, TIcon.premium3d,
    TIcon.delete3d, TIcon.edit3d, TIcon.add3d, TIcon.message3d,
    TIcon.settings3d, TIcon.home3d, TIcon.rating3d,
    TIcon.calendar3d,
  };

  static String _assetPath(TIcon icon) {
    final ext = _pngIcons.contains(icon) ? 'png' : 'webp';
    return 'assets/icons/ti_${icon.name}.$ext';
  }

  static IconData _fallback(TIcon icon) {
    return switch (icon) {
      TIcon.back         => Icons.arrow_back_ios_new,
      TIcon.team         => Icons.group_outlined,
      TIcon.athlete      => Icons.person_outline,
      TIcon.coach        => Icons.sports,
      TIcon.medal        => Icons.military_tech_outlined,
      TIcon.trophy       => Icons.emoji_events_outlined,
      TIcon.rating       => Icons.leaderboard_outlined,
      TIcon.search       => Icons.search,
      TIcon.notifications => Icons.notifications_outlined,
      TIcon.calendar     => Icons.calendar_today_outlined,
      TIcon.settings     => Icons.settings_outlined,
      TIcon.training     => Icons.fitness_center,
      TIcon.tournament   => Icons.sports_kabaddi,
      TIcon.achievements => Icons.workspace_premium_outlined,
      TIcon.belts        => Icons.style,
      TIcon.motivation   => Icons.local_fire_department,
      TIcon.statistics   => Icons.bar_chart,
      TIcon.experience   => Icons.stars,
      TIcon.tasks        => Icons.assignment_outlined,
      TIcon.profile      => Icons.person_outline,
      TIcon.club         => Icons.people_outlined,
      TIcon.info         => Icons.info_outline,
      TIcon.sparring     => Icons.sports_kabaddi,
      TIcon.cpu          => Icons.developer_board,
      TIcon.records      => Icons.history,
      TIcon.category     => Icons.category,
      TIcon.news         => Icons.newspaper,
      TIcon.video        => Icons.play_circle_outline,
      TIcon.security     => Icons.security,
      TIcon.goals        => Icons.outlined_flag,
      TIcon.home         => Icons.home_outlined,
      TIcon.filter       => Icons.tune,
      TIcon.add          => Icons.add,
      TIcon.edit         => Icons.edit_outlined,
      TIcon.delete       => Icons.delete_outline,
      TIcon.chart        => Icons.show_chart,
      TIcon.reminder     => Icons.alarm,
      TIcon.success      => Icons.check_circle_outline,
      TIcon.warning      => Icons.warning_amber,
      TIcon.error        => Icons.error_outline,
      TIcon.help         => Icons.help_outline,
      TIcon.pushups      => Icons.fitness_center,
      TIcon.pullups      => Icons.fitness_center,
      TIcon.plank        => Icons.accessibility_new,
      TIcon.squats       => Icons.directions_walk,
      TIcon.running      => Icons.directions_run,
      TIcon.bicycle      => Icons.directions_bike,
      TIcon.jumpRope     => Icons.loop,
      TIcon.throws       => Icons.sports_kabaddi,
      TIcon.clear        => Icons.close,
      TIcon.sort         => Icons.sort,
      TIcon.select       => Icons.checklist,
      TIcon.checkbox     => Icons.check_box_outline_blank,
      TIcon.radio        => Icons.radio_button_unchecked,
      TIcon.breakfast    => Icons.breakfast_dining,
      TIcon.snack        => Icons.coffee,
      TIcon.lunch        => Icons.lunch_dining,
      TIcon.dinner       => Icons.dinner_dining,
      TIcon.protein      => Icons.egg_alt,
      TIcon.vegetables   => Icons.eco,
      TIcon.grains       => Icons.grain,
      TIcon.fruits       => Icons.apple,
      TIcon.trophy3d     => Icons.emoji_events,
      TIcon.medal3d      => Icons.military_tech,
      TIcon.calendar3d   => Icons.calendar_month,
      TIcon.training3d   => Icons.fitness_center,
      TIcon.motivation3d => Icons.local_fire_department,
      TIcon.crown        => Icons.emoji_events,
      TIcon.bell3d       => Icons.notifications_outlined,
      TIcon.whistle3d    => Icons.sports,
      TIcon.belts3d      => Icons.style,
      TIcon.scroll3d     => Icons.description_outlined,
      TIcon.location3d   => Icons.location_on_outlined,
      TIcon.gift3d       => Icons.card_giftcard,
      TIcon.timer3d      => Icons.timer_outlined,
      TIcon.lantern3d    => Icons.wb_incandescent_outlined,
      TIcon.shield3d     => Icons.shield_outlined,
      TIcon.star3d       => Icons.star_outline,
      TIcon.ref3d        => Icons.gavel,
      TIcon.clock3d      => Icons.access_time,
      TIcon.bellNotif3d  => Icons.notifications_active_outlined,
      TIcon.giftRed3d    => Icons.redeem,
      TIcon.dojo3d       => Icons.home_outlined,
      TIcon.dumbbell3d   => Icons.fitness_center,
      TIcon.flame3d      => Icons.local_fire_department,
      TIcon.cert3d       => Icons.workspace_premium_outlined,
      TIcon.stopwatch3d  => Icons.timer_outlined,
      TIcon.memberCard3d => Icons.credit_card,
      TIcon.award3d      => Icons.emoji_events,
      TIcon.bag3d        => Icons.sports_handball,
      TIcon.emblem3d     => Icons.shield,
      TIcon.trainer3d    => Icons.badge_outlined,
      TIcon.family3d     => Icons.family_restroom,
      TIcon.premium3d    => Icons.workspace_premium,
      TIcon.delete3d     => Icons.delete_outline,
      TIcon.edit3d       => Icons.edit_outlined,
      TIcon.add3d        => Icons.add_circle_outline,
      TIcon.message3d    => Icons.chat_bubble_outline,
      TIcon.settings3d   => Icons.settings_outlined,
      TIcon.home3d       => Icons.home_outlined,
      TIcon.rating3d     => Icons.leaderboard_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      _assetPath(icon),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, _, __) {
        final fallbackColor = color ?? IconTheme.of(context).color ?? Colors.white;
        return Icon(_fallback(icon), size: size, color: fallbackColor);
      },
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
