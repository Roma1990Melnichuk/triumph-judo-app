import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ambient Energy Background
// slow red → orange → gold fog, opacity 3–8%, 20–30 sec loop
// ─────────────────────────────────────────────────────────────────────────────

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat(reverse: true);

    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      // Fog layer 1 — red blob top-left
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl1,
          builder: (_, __) => Positioned.fill(
            child: CustomPaint(painter: _FogPainter(_ctrl1.value, _ctrl2.value)),
          ),
        ),
      ),
    ]);
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter(this.t1, this.t2);
  final double t1;
  final double t2;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.8 + t1 * 0.6,
          -0.6 + t2 * 0.4,
        ),
        radius: 0.7,
        colors: [
          AppColors.primary.withValues(alpha: 0.05 + t1 * 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          0.6 - t2 * 0.4,
          0.8 - t1 * 0.5,
        ),
        radius: 0.6,
        colors: [
          AppColors.accent.withValues(alpha: 0.03 + t2 * 0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(_FogPainter old) =>
      old.t1 != t1 || old.t2 != t2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Breath — scale 1.00 → 1.01 → 1.00 every 4–6 sec
// ─────────────────────────────────────────────────────────────────────────────

class CardBreath extends StatefulWidget {
  const CardBreath({super.key, required this.child, this.offset = 0});
  final Widget child;
  final int offset; // ms offset so cards don't sync

  @override
  State<CardBreath> createState() => _CardBreathState();
}

class _CardBreathState extends State<CardBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _scale = Tween(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.offset), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Light Sweep — soft diagonal shine, 500 ms, every 10–15 sec with random offset
// ─────────────────────────────────────────────────────────────────────────────

class LightSweep extends StatefulWidget {
  const LightSweep({
    super.key,
    required this.child,
    this.intervalSeconds = 12,
    this.offsetSeconds = 0,
  });
  final Widget child;
  final int intervalSeconds;
  final int offsetSeconds;

  @override
  State<LightSweep> createState() => _LightSweepState();
}

class _LightSweepState extends State<LightSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _ctrl.reset();
        _scheduleSweep();
      }
    });
    Future.delayed(Duration(seconds: widget.offsetSeconds), _scheduleSweep);
  }

  void _scheduleSweep() {
    if (!mounted) return;
    Future.delayed(Duration(seconds: widget.intervalSeconds), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ClipRect(
          child: Stack(children: [
            child!,
            if (_ctrl.value > 0 && _ctrl.value < 1)
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (b) => LinearGradient(
                    begin: Alignment(-1 + _ctrl.value * 3, -0.5),
                    end: Alignment(-0.5 + _ctrl.value * 3, 0.5),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ).createShader(b),
                  child: Container(color: Colors.white.withValues(alpha: 0.01)),
                ),
              ),
          ]),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count-Up Text — animates from 0 to target value
// ─────────────────────────────────────────────────────────────────────────────

class CountUpText extends StatefulWidget {
  const CountUpText(
    this.value, {
    super.key,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
  });

  final int value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;
  final Duration delay;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = (_anim.value * widget.value).round();
        return Text('$v${widget.suffix}', style: widget.style);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Tap Scale — 1.00 → 0.96 → 1.00 on press, 180 ms
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedTapScale extends StatefulWidget {
  const AnimatedTapScale({super.key, required this.child, this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 90),
    );
    _scale = Tween(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered Entry — fade + slide-up reveal with delay per index
// ─────────────────────────────────────────────────────────────────────────────

class StaggeredEntry extends StatefulWidget {
  const StaggeredEntry({
    super.key,
    required this.child,
    required this.index,
    this.delayBase = 60,
    this.delayPerItem = 80,
    this.duration = const Duration(milliseconds: 400),
    this.slideDistance = 20.0,
  });

  final Widget child;
  final int index;
  final int delayBase;
  final int delayPerItem;
  final Duration duration;
  final double slideDistance;

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween(begin: widget.slideDistance, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    final delay = widget.delayBase + widget.index * widget.delayPerItem;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Glow — gold/colored glow pulse around a widget
// ─────────────────────────────────────────────────────────────────────────────

class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.child,
    this.color = const Color(0xFFFFD21A),
    this.blurRadius = 16,
    this.periodSeconds = 5,
    this.minAlpha = 0.2,
    this.maxAlpha = 0.55,
    this.borderRadius = 12.0,
  });

  final Widget child;
  final Color color;
  final double blurRadius;
  final int periodSeconds;
  final double minAlpha;
  final double maxAlpha;
  final double borderRadius;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.periodSeconds),
    )..repeat(reverse: true);
    _alpha = Tween(begin: widget.minAlpha, end: widget.maxAlpha).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alpha,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _alpha.value),
              blurRadius: widget.blurRadius,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewport Reveal — cards rise 12px when entering viewport
// ─────────────────────────────────────────────────────────────────────────────

class ViewportReveal extends StatefulWidget {
  const ViewportReveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  State<ViewportReveal> createState() => _ViewportRevealState();
}

class _ViewportRevealState extends State<ViewportReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked Breath — locked achievements: opacity 90% → 100% → 90%, 5 sec
// ─────────────────────────────────────────────────────────────────────────────

class LockedBreath extends StatefulWidget {
  const LockedBreath({super.key, required this.child, this.offset = 0});
  final Widget child;
  final int offset;

  @override
  State<LockedBreath> createState() => _LockedBreathState();
}

class _LockedBreathState extends State<LockedBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _opacity = Tween(begin: 0.35, end: 0.50).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.offset), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientFlow — continuous gradient motion for primary buttons
// ─────────────────────────────────────────────────────────────────────────────

class GradientFlow extends StatefulWidget {
  const GradientFlow({super.key, required this.child, required this.borderRadius});
  final Widget child;
  final double borderRadius;

  @override
  State<GradientFlow> createState() => _GradientFlowState();
}

class _GradientFlowState extends State<GradientFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _ctrl.value * 2, 0),
            end: Alignment(0 + _ctrl.value * 2, 0),
            colors: const [
              Color(0xFFD50000),
              Color(0xFFFF6A00),
              Color(0xFFFFD21A),
              Color(0xFFFF6A00),
              Color(0xFFD50000),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TriumphNavIcon — loads from extracted individual PNG in assets/icons/
// Row × 7 + col maps to the same ordering as the original sprite sheet.
// ─────────────────────────────────────────────────────────────────────────────

const _kTriumphIconNames = [
  'team', 'athlete', 'coach', 'medal', 'trophy', 'rating', 'search',
  'notifications', 'calendar', 'settings', 'training', 'tournament', 'achievements', 'belts',
  'motivation', 'statistics', 'experience', 'tasks', 'profile', 'club', 'info',
  'sparring', 'cpu', 'records', 'category', 'news', 'video', 'security',
];

class TriumphNavIcon extends StatelessWidget {
  const TriumphNavIcon({
    super.key,
    required this.col,
    required this.row,
    this.size = 26,
  });

  final int col; // 0–6
  final int row; // 0–3
  final double size;

  @override
  Widget build(BuildContext context) {
    final index = (row * 7 + col).clamp(0, _kTriumphIconNames.length - 1);
    return Image.asset(
      'assets/icons/ti_${_kTriumphIconNames[index]}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// Enum for well-known icon positions in triumph_icons.png
enum TriumphIconType {
  team,         // Команда     (0, 0)
  athlete,      // Спортсмен   (1, 0)
  coach,        // Тренер      (2, 0)
  medal,        // Медаль      (3, 0)
  trophy,       // Кубок       (4, 0)
  rating,       // Рейтинг     (5, 0)
  search,       // Пошук       (6, 0)
  notification, // Повідом.    (0, 1)
  calendar,     // Календар    (1, 1)
  settings,     // Налашт.     (2, 1)
  training,     // Тренування  (3, 1)
  tournament,   // Турнір      (4, 1)
  achievement,  // Досягнення  (5, 1)
  belt,         // Пояси       (6, 1)
  motivation,   // Мотивація   (0, 2)
  statistics,   // Статистика  (1, 2)
  experience,   // Досвід      (2, 2)
  tasks,        // Завдання    (3, 2)
  profile,      // Профіль     (4, 2)
  club,         // Клуб        (5, 2)
  info,         // Інфо        (6, 2)
  sparring,     // Спарінг     (0, 3)
  target,       // ЦПЕ         (1, 3)
  records,      // Рекорди     (2, 3)
  category,     // Категорія   (3, 3)
  news,         // Новини      (4, 3)
  video,        // Відео       (5, 3)
  security,     // Безпека     (6, 3)
}

extension TriumphIconPos on TriumphIconType {
  (int col, int row) get pos {
    switch (this) {
      case TriumphIconType.team:         return (0, 0);
      case TriumphIconType.athlete:      return (1, 0);
      case TriumphIconType.coach:        return (2, 0);
      case TriumphIconType.medal:        return (3, 0);
      case TriumphIconType.trophy:       return (4, 0);
      case TriumphIconType.rating:       return (5, 0);
      case TriumphIconType.search:       return (6, 0);
      case TriumphIconType.notification: return (0, 1);
      case TriumphIconType.calendar:     return (1, 1);
      case TriumphIconType.settings:     return (2, 1);
      case TriumphIconType.training:     return (3, 1);
      case TriumphIconType.tournament:   return (4, 1);
      case TriumphIconType.achievement:  return (5, 1);
      case TriumphIconType.belt:         return (6, 1);
      case TriumphIconType.motivation:   return (0, 2);
      case TriumphIconType.statistics:   return (1, 2);
      case TriumphIconType.experience:   return (2, 2);
      case TriumphIconType.tasks:        return (3, 2);
      case TriumphIconType.profile:      return (4, 2);
      case TriumphIconType.club:         return (5, 2);
      case TriumphIconType.info:         return (6, 2);
      case TriumphIconType.sparring:     return (0, 3);
      case TriumphIconType.target:       return (1, 3);
      case TriumphIconType.records:      return (2, 3);
      case TriumphIconType.category:     return (3, 3);
      case TriumphIconType.news:         return (4, 3);
      case TriumphIconType.video:        return (5, 3);
      case TriumphIconType.security:     return (6, 3);
    }
  }

  Widget icon({double size = 26}) {
    final (col, row) = pos;
    return TriumphNavIcon(col: col, row: row, size: size);
  }
}

// ── SeasonalParticles ─────────────────────────────────────────────────────────
// Overlays drifting seasonal particles (leaves/snow/petals/sparks) on a child.
// Used on earned seasonal discipline achievement badges.
// ─────────────────────────────────────────────────────────────────────────────

enum SeasonType { autumn, winter, spring, summer }

class SeasonalParticles extends StatefulWidget {
  const SeasonalParticles({
    super.key,
    required this.child,
    required this.type,
  });

  final Widget child;
  final SeasonType type;

  @override
  State<SeasonalParticles> createState() => _SeasonalParticlesState();
}

class _SeasonalParticlesState extends State<SeasonalParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_SPart> _parts;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final rng = math.Random();
    _parts = List.generate(12, (_) => _SPart(
      startX: rng.nextDouble(),
      phase: rng.nextDouble(),
      speed: 0.55 + rng.nextDouble() * 0.7,
      size: 2.0 + rng.nextDouble() * 2.5,
      swayAmp: (rng.nextDouble() - 0.5) * 0.18,
      swayFreq: 1.5 + rng.nextDouble() * 1.5,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _SeasonPainter(
                  parts: _parts,
                  time: _ctrl.value,
                  type: widget.type,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SPart {
  const _SPart({
    required this.startX,
    required this.phase,
    required this.speed,
    required this.size,
    required this.swayAmp,
    required this.swayFreq,
  });
  final double startX;
  final double phase;
  final double speed;
  final double size;
  final double swayAmp;
  final double swayFreq;
}

class _SeasonPainter extends CustomPainter {
  const _SeasonPainter({
    required this.parts,
    required this.time,
    required this.type,
  });

  final List<_SPart> parts;
  final double time;
  final SeasonType type;

  @override
  void paint(Canvas canvas, Size sz) {
    final rising = type == SeasonType.summer;
    for (final p in parts) {
      // Individual time progress (0→1 within one loop)
      final t = ((time * p.speed) + p.phase) % 1.0;
      final yFrac = rising ? (1.0 - t) : t;

      // Horizontal sway
      final xFrac = (p.startX + p.swayAmp * math.sin(t * p.swayFreq * math.pi * 2));
      final px = ((xFrac % 1.0 + 1.0) % 1.0) * sz.width;
      final py = yFrac * sz.height;

      // Fade in at start, fade out at end of each pass
      final edgeFade = t < 0.12 ? t / 0.12 : (t > 0.88 ? (1.0 - t) / 0.12 : 1.0);
      final paint = Paint()
        ..color = _colorFor(t).withValues(alpha: edgeFade * 0.72);

      switch (type) {
        case SeasonType.autumn:
          // Tumbling oval leaf
          canvas.save();
          canvas.translate(px, py);
          canvas.rotate(t * math.pi * 6);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: p.size * 2.2, height: p.size),
            paint,
          );
          canvas.restore();
        case SeasonType.winter:
          // Round snowflake dot
          canvas.drawCircle(Offset(px, py), p.size, paint);
        case SeasonType.spring:
          // Soft petal circle
          canvas.save();
          canvas.translate(px, py);
          canvas.rotate(t * math.pi * 3);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * 0.9),
            paint,
          );
          canvas.restore();
        case SeasonType.summer:
          // Rising spark – tiny bright point
          final glow = Paint()
            ..color = _colorFor(t).withValues(alpha: edgeFade * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(Offset(px, py), p.size * 0.9, glow);
          canvas.drawCircle(Offset(px, py), p.size * 0.5, paint);
      }
    }
  }

  Color _colorFor(double t) {
    switch (type) {
      case SeasonType.autumn:
        const colors = [
          Color(0xFFFF6B35),
          Color(0xFFFFB347),
          Color(0xFFCD853F),
          Color(0xFFE87722),
        ];
        return colors[(t * colors.length).floor().clamp(0, colors.length - 1)];
      case SeasonType.winter:
        return Color.lerp(const Color(0xFFD0E8FF), const Color(0xFFFFFFFF), t)!;
      case SeasonType.spring:
        return Color.lerp(const Color(0xFFFFB7C5), const Color(0xFFFFF0F5), t)!;
      case SeasonType.summer:
        return Color.lerp(const Color(0xFFFF8C00), const Color(0xFFFFD700), t)!;
    }
  }

  @override
  bool shouldRepaint(_SeasonPainter old) => old.time != time;
}
