import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _progressCtrl;

  late final Animation<double> _glow;
  late final Animation<double> _fade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    // Pulsing glow on logo
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.35, end: 0.75)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Fade-in all content
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Progress bar — fills over 2.4 seconds
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();
    _progress = CurvedAnimation(
        parent: _progressCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final logoSize = sw * 0.62;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated radial red glow ────────────────────────────────────
          AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color.lerp(
                      const Color(0xAA7A0000),
                      const Color(0x88D50000),
                      _glow.value,
                    )!,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          FadeTransition(
            opacity: _fade,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Full logo with glow ────────────────────────────────
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, child) => Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.3 + _glow.value * 0.25),
                            blurRadius: 60 + _glow.value * 40,
                            spreadRadius: 8 + _glow.value * 12,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/triumph_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── ТРІУМФ — gold, Russo One ───────────────────────────
                  Text(
                    'ТРІУМФ',
                    style: GoogleFonts.russoOne(
                      fontSize: 42,
                      color: AppColors.accent, // #FFD21A gold
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subtitle ────────────────────────────────────────────
                  Text(
                    'ДЗЮДО ПОЧИНАЄТЬСЯ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary
                          .withValues(alpha: 0.85),
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'З ПЕРЕМОГИ НАД СОБОЮ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary
                          .withValues(alpha: 0.85),
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Progress bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) {
                        final pct = (_progress.value * 100).round();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  // Background track
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface3,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Filled gradient bar
                                  FractionallySizedBox(
                                    widthFactor: _progress.value,
                                    child: Container(
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.ctaGradient,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
