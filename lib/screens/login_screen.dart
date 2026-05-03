import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _isRegister = false;

  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Моля, попълни имейл и парола.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _snack('Моля, въведи валиден имейл адрес.');
      return;
    }

    if (password.length < 6) {
      _snack('Паролата трябва да е поне 6 символа.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _isRegister
          ? await AuthService.register(email, password)
          : await AuthService.login(email, password);

      if (!mounted) return;

      if (user == null) {
        _snack(
          _isRegister
              ? 'Регистрацията е неуспешна. Провери имейла или използвай друг.'
              : 'Неуспешен вход. Провери имейла и паролата.',
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/map');
    } catch (e) {
      if (!mounted) return;
      _snack('Грешка при вход: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Karla'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/login.jpg',
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.20),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundDeep.withValues(alpha: 0.35),
                        AppTheme.backgroundDeep,
                      ],
                      stops: const [0.45, 0.78, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(
                              Icons.terrain_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Little\nWonders BG',
                        style: TextStyle(
                          fontFamily: 'Lora',
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Малка страна. Големи чудеса.',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundCard,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXl),
                              border: Border.all(color: AppTheme.glassBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AuthToggle(
                                  isRegister: _isRegister,
                                  onToggle: (value) {
                                    setState(() => _isRegister = value);
                                  },
                                ),
                                const SizedBox(height: 28),
                                _Field(
                                  controller: _emailCtrl,
                                  hint: 'example@email.com',
                                  label: 'ИМЕЙЛ',
                                  icon: Icons.mail_outline_rounded,
                                  type: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  controller: _passCtrl,
                                  hint: '••••••••',
                                  label: 'ПАРОЛА',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscure,
                                  textInputAction: TextInputAction.done,
                                  suffix: IconButton(
                                    onPressed: () {
                                      setState(() => _obscure = !_obscure);
                                    },
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : _submit,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      decoration: BoxDecoration(
                                        gradient: _isLoading
                                            ? null
                                            : const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF9B6FD3),
                                                  Color(0xFFD77FA1),
                                                ],
                                              ),
                                        color: _isLoading
                                            ? AppTheme.textMuted
                                                .withValues(alpha: 0.35)
                                            : null,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                        boxShadow: _isLoading
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(0xFFD77FA1)
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isRegister
                                                    ? 'Създай профил'
                                                    : 'Вход',
                                                style: const TextStyle(
                                                  fontFamily: 'Karla',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Pill('Посещения'),
                            SizedBox(width: 8),
                            _Pill('Точки'),
                            SizedBox(width: 8),
                            _Pill('Значки'),
                          ],
                        ),
                      ),
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
}

class _AuthToggle extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onToggle;

  const _AuthToggle({
    required this.isRegister,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDeep,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            label: 'Вход',
            active: !isRegister,
            onTap: () => onToggle(false),
          ),
          _Tab(
            label: 'Регистрация',
            active: isRegister,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.backgroundCard : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Karla',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: active ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction textInputAction;

  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Karla',
              color: AppTheme.textMuted,
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.backgroundDeep,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: Color(0xFF253545)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.accentOrange,
                width: 1.5,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Karla',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryGreenLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
