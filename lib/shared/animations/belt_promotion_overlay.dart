import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/belt_levels.dart';
import '../widgets/belt_sprite_icon.dart';

/// Belt promotion ceremony overlay.
/// Darken → belt appears (scale+rotate) → particles → rank title reveal
///
/// Usage:
///   BeltPromotionOverlay.show(context, belt: BeltLevel.blue);
class BeltPromotionOverlay extends StatefulWidget {
  const BeltPromotionOverlay({super.key, required this.belt});
  final BeltLevel belt;

  static Future<void> show(BuildContext context, {required BeltLevel belt}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => BeltPromotionOverlay(belt: belt),
    );
  }

  @override
  State<BeltPromotionOverlay> createState() => _BeltPromotionOverlayState();
}

class _BeltPromotionOverlayState extends State<BeltPromotionOverlay>
    with TickerProviderStateMixin {
  // Stage controllers
  late final AnimationController _dark;
  late final AnimationController _belt;
  late final AnimationController _burst;
  late final AnimationController _title;
  late final AnimationController _glow;

  // Animations
  late final Animation<double> _darkOpacity;
  late final Animation<double> _beltScale;
  late final Animation<double> _beltOpacity;
  late final Animation<double> _beltRotation;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _glowPulse;

  final _dots = <_Particle>[];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _dark      = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _belt      = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _title     = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glow      = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _darkOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _dark, curve: Curves.easeIn));

    _beltScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0),  weight: 40),
    ]).animate(CurvedAnimation(parent: _belt, curve: Curves.easeOutCubic));

    _beltOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _belt, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    _beltRotation = Tween(begin: -0.15, end: 0.0).animate(
        CurvedAnimation(parent: _belt, curve: Curves.easeOutBack));

    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _title, curve: Curves.easeOut));
    _titleSlide = Tween(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _title, curve: Curves.easeOutCubic));

    _glowPulse = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glow, curve: Curves.easeInOut));

    _generateParticles();
    _runSequence();
  }

  void _generateParticles() {
    final beltColor = widget.belt.color;
    final secondColor = widget.belt.secondaryColor ?? beltColor;
    for (var i = 0; i < 30; i++) {
      _dots.add(_Particle(
        angle: _rng.nextDouble() * math.pi * 2,
        speed: 80 + _rng.nextDouble() * 180,
        size: 3 + _rng.nextDouble() * 6,
        color: i.isEven
            ? beltColor.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3)
            : secondColor.withValues(alpha: 0.5 + _rng.nextDouble() * 0.4),
      ));
    }
  }

  Future<void> _runSequence() async {
    // 1. Screen darkens
    await _dark.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Belt appears with rotation
    _belt.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Particles burst
    _burst.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // 4. Rank title slides in
    await _title.forward();
    await Future.delayed(const Duration(milliseconds: 2500));

    // 5. Dismiss
    if (mounted) Navigator.of(context).pop();
  }

  Color get _beltGlowColor {
    final c = widget.belt.color;
    // For very dark belts (black/brown) use their secondary or accent
    if (c.computeLuminance() < 0.05) return AppColors.accent;
    return c;
  }

  @override
  void dispose() {
    _dark.dispose();
    _belt.dispose();
    _burst.dispose();
    _title.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_dark, _belt, _burst, _title, _glow]),
        builder: (_, __) {
          return Material(
            color: Colors.transparent,
            child: Stack(children: [
              // Dark backdrop
              Opacity(
                opacity: _darkOpacity.value * 0.92,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        _beltGlowColor.withValues(alpha: 0.08 * _darkOpacity.value),
                        const Color(0xFF050000),
                      ],
                    ),
                  ),
                ),
              ),

              // Particles
              if (_burst.value > 0)
                CustomPaint(
                  size: size,
                  painter: _BeltParticlePainter(
                    particles: _dots,
                    progress: _burst.value,
                    origin: Offset(size.width / 2, size.height / 2 - 20),
                  ),
                ),

              // Main content column
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow ring + belt
                    Transform.rotate(
                      angle: _beltRotation.value,
                      child: Transform.scale(
                        scale: _beltScale.value,
                        child: Opacity(
                          opacity: _beltOpacity.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _beltGlowColor.withValues(alpha: 0.06),
                              boxShadow: [
                                BoxShadow(
                                  color: _beltGlowColor.withValues(
                                      alpha: 0.55 * _glowPulse.value),
                                  blurRadius: 60,
                                  spreadRadius: 12,
                                ),
                                BoxShadow(
                                  color: _beltGlowColor.withValues(
                                      alpha: 0.25 * _glowPulse.value),
                                  blurRadius: 120,
                                  spreadRadius: 24,
                                ),
                              ],
                            ),
                            child: Center(
                              child: BeltSpriteIcon(
                                belt: widget.belt,
                                size: 140,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // "ПІДВИЩЕННЯ ПОЯСА" label
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: _beltGlowColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _beltGlowColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'ПІДВИЩЕННЯ ПОЯСА',
                            style: TextStyle(
                              color: _beltGlowColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Belt name
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Text(
                          widget.belt.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Belt abbreviation chip
                    Opacity(
                      opacity: _titleOpacity.value * 0.7,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.belt.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: widget.belt.color.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            widget.belt.abbreviation,
                            style: TextStyle(
                              color: _beltGlowColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Tap hint
                    Opacity(
                      opacity: _titleOpacity.value * 0.35,
                      child: const Text(
                        'Торкніться для продовження',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ── Particle data ─────────────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _BeltParticlePainter extends CustomPainter {
  _BeltParticlePainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });
  final List<_Particle> particles;
  final double progress;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final eased = Curves.easeOut.transform(progress);
      final dist = p.speed * eased;
      final x = origin.dx + math.cos(p.angle) * dist;
      final y = origin.dy + math.sin(p.angle) * dist;
      final fade = (1 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        p.size * (0.5 + (1 - progress) * 0.5),
        Paint()..color = p.color.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BeltParticlePainter old) => old.progress != progress;
}
