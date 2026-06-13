import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'offline_banner.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  late final List<AnimationController> _tapCtrls;
  late final List<Animation<double>> _tapScales;

  static const _coachRoutes  = ['/home', '/team', '/rating', '/events', '/belts', '/settings'];
  static const _parentRoutes = ['/home', '/team', '/rating', '/events', '/settings'];

  // Luxury glyph icons — clean vectors, readable at 26 px
  static const _coachNavIcons = <IconData>[
    Icons.home_rounded,          // Головна
    Icons.groups_rounded,        // Команда
    Icons.leaderboard_rounded,   // Рейтинг
    Icons.event_note_rounded,    // Графік
    Icons.layers_rounded,        // Пояси
    Icons.tune_rounded,          // Налашт.
  ];
  static const _parentNavIcons = <IconData>[
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.leaderboard_rounded,
    Icons.event_note_rounded,    // Графік
    Icons.tune_rounded,
  ];

  static const _coachLabels  = ['Головна', 'Команда', 'Рейтинг', 'Графік', 'Пояси', 'Налашт.'];
  static const _parentLabels = ['Головна', 'Команда', 'Рейтинг', 'Графік', 'Налашт.'];

  @override
  void initState() {
    super.initState();
    _tapCtrls = List.generate(6, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    ));
    _tapScales = _tapCtrls.map((c) => Tween(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    )).toList();
  }

  @override
  void dispose() {
    for (final c in _tapCtrls) c.dispose();
    super.dispose();
  }

  void _animateTap(int index) =>
      _tapCtrls[index].forward().then((_) => _tapCtrls[index].reverse());

  @override
  Widget build(BuildContext context) {
    final userAsync  = ref.watch(currentUserModelProvider);
    final isCoach    = userAsync.asData?.value?.isCoach ?? false;
    final location   = GoRouterState.of(context).matchedLocation;

    final routes = isCoach ? _coachRoutes    : _parentRoutes;
    final icons  = isCoach ? _coachNavIcons  : _parentNavIcons;
    final labels = isCoach ? _coachLabels    : _parentLabels;

    int currentIndex = 0;
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) { currentIndex = i; break; }
    }
    currentIndex = currentIndex.clamp(0, routes.length - 1);

    void onTap(int i) { _animateTap(i); context.go(routes[i]); }

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

// ── Nav bar ───────────────────────────────────────────────────────────────────

class _TriumphNavBar extends StatelessWidget {
  const _TriumphNavBar({
    required this.currentIndex,
    required this.icons,
    required this.labels,
    required this.tapScales,
    required this.onTap,
  });

  final int currentIndex;
  final List<IconData> icons;
  final List<String> labels;
  final List<Animation<double>> tapScales;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Upward shadow — separates bar from content
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: const Color(0xFFFFB43C).withValues(alpha: 0.08),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xF50A0807), // rgba(10,8,7,.96)
              border: Border(
                top: BorderSide(color: Color(0x2DFFB43C), width: 1), // rgba(255,180,60,.18)
              ),
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
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String   label;
  final bool     active;

  // Orange glow colour constants
  static const _glowColor  = Color(0xCCFFAA00); // glow layer (blurred copy)
  static const _activeColor = Color(0xFFFFB000); // crisp top icon
  static const _inactiveColor = Color(0xFF8A8078); // warm neutral-grey (not cold)

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (active) ...[
                // Glow: blurred orange copy of the icon underneath
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                    child: Icon(icon, size: 26, color: _glowColor),
                  ),
                ),
                // Crisp active icon on top
                Icon(icon, size: 26, color: _activeColor),
              ] else
                Icon(icon, size: 24, color: _inactiveColor),
            ],
          ),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? _activeColor
                : _inactiveColor.withValues(alpha: 0.85),
            shadows: active
                ? [Shadow(color: _glowColor, blurRadius: 10)]
                : null,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
