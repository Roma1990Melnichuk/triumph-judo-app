import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../animations/app_animations.dart';
import 'offline_banner.dart';
import 'premium_widgets.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  // One tap-scale controller per maximum tab count (6 for coach)
  late final List<AnimationController> _tapCtrls;
  late final List<Animation<double>> _tapScales;

  static const _coachRoutes  = ['/home', '/team', '/rating', '/events', '/belts', '/settings'];
  static const _parentRoutes = ['/home', '/team', '/rating', '/events', '/settings'];

  // Nav icon types
  static const _coachIcons = [
    TriumphIconType.club,        // Головна
    TriumphIconType.team,        // Команда
    TriumphIconType.rating,      // Рейтинг
    TriumphIconType.calendar,    // Графік
    TriumphIconType.belt,        // Пояси
    TriumphIconType.settings,    // Налашт.
  ];
  static const _parentIcons = [
    TriumphIconType.club,        // Головна
    TriumphIconType.team,        // Команда
    TriumphIconType.rating,      // Рейтинг
    TriumphIconType.calendar,    // Графік
    TriumphIconType.settings,    // Налашт.
  ];

  static const _coachLabels  = ['Головна', 'Команда', 'Рейтинг', 'Графік', 'Пояси', 'Налаштування'];
  static const _parentLabels = ['Головна', 'Команда', 'Рейтинг', 'Графік', 'Налаштування'];

  @override
  void initState() {
    super.initState();
    _tapCtrls = List.generate(6, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    ));
    _tapScales = _tapCtrls.map((c) => Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    )).toList();
  }

  @override
  void dispose() {
    for (final c in _tapCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _animateTap(int index) {
    _tapCtrls[index].forward().then((_) => _tapCtrls[index].reverse());
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final isCoach   = userAsync.value?.isCoach ?? false;
    final location  = GoRouterState.of(context).matchedLocation;

    final routes = isCoach ? _coachRoutes : _parentRoutes;
    final icons  = isCoach ? _coachIcons  : _parentIcons;
    final labels = isCoach ? _coachLabels : _parentLabels;

    int currentIndex = 0;
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        currentIndex = i;
        break;
      }
    }
    currentIndex = currentIndex.clamp(0, routes.length - 1);

    void onTap(int i) {
      _animateTap(i);
      context.go(routes[i]);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: _TriumphNavBar(
        currentIndex: currentIndex,
        icons: icons,
        labels: labels,
        tapScales: _tapScales,
        onTap: onTap,
      ),
    );
  }
}

// ── Custom bottom nav bar ─────────────────────────────────────────────────────

class _TriumphNavBar extends StatelessWidget {
  const _TriumphNavBar({
    required this.currentIndex,
    required this.icons,
    required this.labels,
    required this.tapScales,
    required this.onTap,
  });

  final int currentIndex;
  final List<TriumphIconType> icons;
  final List<String> labels;
  final List<Animation<double>> tapScales;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEB0B0B0B), // rgba(11,11,11,.92)
        border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)), // rgba(255,255,255,.08)
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(icons.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedBuilder(
                    animation: tapScales[i],
                    builder: (_, __) => Transform.scale(
                      scale: tapScales[i].value,
                      child: _NavItem(
                        icon: icons[i],
                        label: labels[i],
                        active: active,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final TriumphIconType icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final (col, row) = icon.pos;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlowIcon(
          isActive: active,
          color: AppColors.orange,
          icon: ColorFiltered(
            colorFilter: active
                ? const ColorFilter.mode(AppColors.orange, BlendMode.srcATop)
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: TriumphNavIcon(col: col, row: row, size: 26),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.orange : AppColors.textSecondary,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
