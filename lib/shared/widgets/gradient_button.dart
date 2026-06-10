import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Primary CTA button — animated gradient flow + tap scale
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.height = 52,
    this.gradient = AppColors.ctaGradient,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double height;
  final LinearGradient gradient;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with TickerProviderStateMixin {
  late final AnimationController _flow;
  late final AnimationController _tap;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 90),
    );
    _tapScale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tap, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _flow.dispose();
    _tap.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _enabled ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _tap.forward() : null,
        onTapUp: _enabled
            ? (_) {
                _tap.reverse();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? () => _tap.reverse() : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flow, _tap]),
          builder: (_, child) => Transform.scale(
            scale: _tapScale.value,
            child: Container(
              height: widget.height,
              decoration: _enabled
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment(-1 + _flow.value * 2, 0),
                        end: Alignment(0 + _flow.value * 2, 0),
                        colors: const [
                          Color(0xFFE40000),
                          Color(0xFFFF260F),
                          Color(0xFFFF8A00),
                          Color(0xFFFFD21A),
                          Color(0xFFFF8A00),
                          Color(0xFFFF260F),
                          Color(0xFFE40000),
                        ],
                        stops: const [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.surface2,
                    ),
              child: child,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : widget.child,
          ),
        ),
      ),
    );
  }
}
