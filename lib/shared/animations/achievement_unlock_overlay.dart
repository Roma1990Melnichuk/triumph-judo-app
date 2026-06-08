import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/achievement_model.dart';
import '../widgets/achievement_badge.dart';

/// Achievement unlock cinematic overlay.
/// Dark overlay → rarity glow → icon → title → description → wisdom → burst
///
/// Usage:
///   AchievementUnlockOverlay.show(context, def: def);
class AchievementUnlockOverlay extends StatefulWidget {
  const AchievementUnlockOverlay({super.key, required this.def});
  final AchievementDef def;

  static Future<void> show(BuildContext context, {required AchievementDef def}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => AchievementUnlockOverlay(def: def),
    );
  }

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _overlay;
  late final AnimationController _glow;
  late final AnimationController _icon;
  late final AnimationController _title;
  late final AnimationController _desc;
  late final AnimationController _burst;

  late final Animation<double> _overlayOpacity;
  late final Animation<double> _glowScale;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _descOpacity;
  late final Animation<double> _burstScale;
  late final Animation<double> _burstOpacity;

  final _particles = <_Particle>[];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _overlay = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _glow    = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _icon    = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _title   = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _desc    = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _burst   = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _overlayOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _overlay, curve: Curves.easeOut));
    _glowScale = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glow, curve: Curves.elasticOut));
    _iconScale = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _icon, curve: Curves.elasticOut));
    _iconOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _icon, curve: Curves.easeIn));
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _title, curve: Curves.easeOut));
    _descOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _desc, curve: Curves.easeOut));
    _burstScale = Tween(begin: 0.0, end: 2.5).animate(
        CurvedAnimation(parent: _burst, curve: Curves.easeOut));
    _burstOpacity = Tween(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _burst, curve: Curves.easeOut));

    _generateParticles();
    _runSequence();
  }

  void _generateParticles() {
    for (var i = 0; i < 20; i++) {
      _particles.add(_Particle(
        angle: _rng.nextDouble() * math.pi * 2,
        speed: 60 + _rng.nextDouble() * 140,
        size: 2 + _rng.nextDouble() * 4,
        color: _glowColor.withValues(alpha: 0.6 + _rng.nextDouble() * 0.4),
      ));
    }
  }

  Future<void> _runSequence() async {
    await _overlay.forward();                         // 0ms  – dark overlay
    await Future.delayed(const Duration(milliseconds: 80));
    _glow.forward();                                  // glow appears
    await Future.delayed(const Duration(milliseconds: 150));
    _icon.forward();                                  // icon appears
    await Future.delayed(const Duration(milliseconds: 300));
    _title.forward();                                 // title appears
    await Future.delayed(const Duration(milliseconds: 200));
    _desc.forward();                                  // description appears
    await Future.delayed(const Duration(milliseconds: 300));
    _burst.forward();                                 // burst effect
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) Navigator.of(context).pop();
  }

  Color get _glowColor {
    switch (widget.def.rarity) {
      case AchievementRarity.common:    return Colors.grey;
      case AchievementRarity.rare:      return Colors.green;
      case AchievementRarity.epic:      return Colors.blue.shade400;
      case AchievementRarity.legendary: return Colors.purple.shade400;
      case AchievementRarity.mythic:    return AppColors.accent;
    }
  }

  @override
  void dispose() {
    _overlay.dispose();
    _glow.dispose();
    _icon.dispose();
    _title.dispose();
    _desc.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_overlay, _glow, _icon, _title, _desc, _burst]),
        builder: (_, __) {
          return Material(
            color: Colors.transparent,
            child: Stack(children: [
              // Dark overlay
              Opacity(
                opacity: _overlayOpacity.value * 0.88,
                child: Container(color: const Color(0xFF050000)),
              ),

              // Burst ring
              if (_burst.value > 0)
                Center(
                  child: Opacity(
                    opacity: _burstOpacity.value,
                    child: Transform.scale(
                      scale: _burstScale.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _glowColor.withValues(alpha: 0.8),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Particles
              if (_burst.value > 0)
                Center(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width,
                               MediaQuery.of(context).size.height),
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _burst.value,
                      origin: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2,
                      ),
                    ),
                  ),
                ),

              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rarity glow + icon
                    Transform.scale(
                      scale: _glowScale.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: Opacity(
                          opacity: _iconOpacity.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _glowColor.withValues(alpha: 0.12),
                              boxShadow: [
                                BoxShadow(
                                  color: _glowColor.withValues(alpha: 0.6),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                              border: Border.all(
                                color: _glowColor.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: AchievementIcon(def: widget.def, size: 72),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // NEW badge
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: _glowColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _glowColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'НОВА НАГОРОДА',
                          style: TextStyle(
                            color: _glowColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          widget.def.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Description
                    Opacity(
                      opacity: _descOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          widget.def.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rarity label
                    Opacity(
                      opacity: _descOpacity.value,
                      child: Text(
                        widget.def.rarity.label.toUpperCase(),
                        style: TextStyle(
                          color: _glowColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tap to dismiss hint
                    Opacity(
                      opacity: _descOpacity.value * 0.4,
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

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
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
      final dist = p.speed * progress;
      final x = origin.dx + math.cos(p.angle) * dist;
      final y = origin.dy + math.sin(p.angle) * dist;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - progress * 0.5),
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
