import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/triumph_emblem.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    final error = ref.read(authNotifierProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_mapError(error.toString())),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть email для скидання паролю')),
      );
      return;
    }
    await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лист відправлено на вашу пошту ✅')),
      );
    }
  }

  String _mapError(String e) {
    if (e.contains('wrong-password') || e.contains('invalid-credential')) {
      return 'Невірний email або пароль';
    }
    if (e.contains('user-not-found')) return 'Користувача не знайдено';
    if (e.contains('network')) return 'Помилка мережі';
    return 'Помилка входу. Спробуйте ще раз';
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Red glow from top-right
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 340, height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Secondary glow left
          Positioned(
            top: 100, left: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Emblem
                      const Center(child: TriumphEmblem(size: 100)),
                      const SizedBox(height: 18),

                      // ТРІУМФ
                      Center(
                        child: ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.ctaGradient.createShader(b),
                          child: Text(
                            'ТРІУМФ',
                            style: GoogleFonts.russoOne(
                              fontSize: 30,
                              color: Colors.white,
                              letterSpacing: 7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title + subtitle
                      const Text(
                        'Вхід до акаунту',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Раді знову вас бачити!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Email або телефон',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: FormValidators.email,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: FormValidators.password,
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero),
                          child: const Text(
                            'Забули пароль?',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA button
                      GradientButton(
                        onPressed: loading ? null : _submit,
                        isLoading: loading,
                        child: const Text(
                          'Увійти',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.surface3)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'або продовжити з',
                              style: TextStyle(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.surface3)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialBtn(
                            icon: 'G',
                            color: const Color(0xFFEA4335),
                            onTap: () => _showSocialToast(),
                          ),
                          const SizedBox(width: 16),
                          _SocialBtn(
                            icon: '',
                            iconWidget: const Icon(Icons.apple,
                                color: Colors.white, size: 22),
                            color: const Color(0xFF1C1C1E),
                            onTap: () => _showSocialToast(),
                          ),
                          const SizedBox(width: 16),
                          _SocialBtn(
                            icon: '',
                            iconWidget: const Icon(Icons.phone_outlined,
                                color: Colors.white, size: 20),
                            color: const Color(0xFF25D366),
                            onTap: () => _showSocialToast(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Немає акаунту? ',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/register'),
                            child: const Text(
                              'Зареєструватись',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSocialToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скоро буде доступно')),
    );
  }
}

// ── Social button ──────────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconWidget,
  });

  final String icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface3),
        ),
        child: Center(
          child: iconWidget ??
              Text(
                icon,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}
