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

  void _forgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecoveryModal(emailHint: _emailCtrl.text.trim()),
    );
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

                      // Social divider — VIS-02 Fix: stylised
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.surface3)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'або продовжити з',
                              style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                  fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.surface3)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social buttons — VIS-03 Fix: Circular
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialBtn(
                            icon: 'G',
                            color: const Color(0xFFEA4335),
                            onTap: () => _showSocialToast(),
                          ),
                          const SizedBox(width: 20),
                          _SocialBtn(
                            icon: '',
                            iconWidget: const Icon(Icons.apple,
                                color: Colors.white, size: 24),
                            color: const Color(0xFF1C1C1E),
                            onTap: () => _showSocialToast(),
                          ),
                          const SizedBox(width: 20),
                          _SocialBtn(
                            icon: '',
                            iconWidget: const Icon(Icons.phone_outlined,
                                color: Colors.white, size: 22),
                            color: const Color(0xFF25D366),
                            onTap: () => _showSocialToast(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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

// ── Recovery modal ────────────────────────────────────────────────────────────

class _RecoveryModal extends ConsumerStatefulWidget {
  const _RecoveryModal({this.emailHint});
  final String? emailHint;

  @override
  ConsumerState<_RecoveryModal> createState() => _RecoveryModalState();
}

class _RecoveryModalState extends ConsumerState<_RecoveryModal> {
  int  _tab     = 0; // 0 = email, 1 = phone
  bool _loading = false;
  bool _sent    = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: _tab == 0 ? (widget.emailHint ?? '') : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final val = _ctrl.text.trim();
    if (_tab == 0) {
      if (val.isEmpty || !val.contains('@')) return;
      setState(() => _loading = true);
      await ref.read(authNotifierProvider.notifier).sendPasswordReset(val);
      if (mounted) setState(() { _loading = false; _sent = true; });
    } else {
      // SMS recovery — placeholder
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141210),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (_sent)
            _SuccessView(isEmail: _tab == 0, onDone: () => Navigator.pop(context))
          else ...[
            // Icon
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),

            const Text(
              'Відновлення пароля',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Виберіть спосіб відновлення доступу',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Tab toggle
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TabBtn(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    active: _tab == 0,
                    onTap: () {
                      setState(() { _tab = 0; _ctrl.text = widget.emailHint ?? ''; });
                    },
                  ),
                  _TabBtn(
                    label: 'Телефон',
                    icon: Icons.phone_outlined,
                    active: _tab == 1,
                    onTap: () {
                      setState(() { _tab = 1; _ctrl.clear(); });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input
            TextField(
              controller: _ctrl,
              keyboardType: _tab == 0
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: _tab == 0 ? 'Email адреса' : 'Номер телефону',
                prefixIcon: Icon(
                    _tab == 0 ? Icons.email_outlined : Icons.phone_outlined,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFF1A1816),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2C2A28)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2C2A28)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // CTA
            GradientButton(
              onPressed: _loading ? null : _send,
              isLoading: _loading,
              child: const Text(
                'Надіслати інструкції',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),

            // Remember link
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Я згадав пароль',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                const Text(
                  'Ми ніколи не передаємо ваші дані третім особам',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String       label;
  final IconData     icon;
  final bool         active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.6))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15,
                  color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.isEmail, required this.onDone});
  final bool         isEmail;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF0D2A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Інструкції відправлено!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            isEmail
                ? 'Перевірте вашу пошту та\nдотримуйтесь інструкцій у листі'
                : 'Перевірте SMS на вашому телефоні',
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GradientButton(
            onPressed: onDone,
            child: const Text(
              'Зрозуміло',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ],
      ),
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
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle, // VIS-03 Fix: Circular buttons
          border: Border.all(color: AppColors.surface3),
        ),
        child: Center(
          child: iconWidget ??
              Text(
                icon,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}
