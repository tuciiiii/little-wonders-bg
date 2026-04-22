import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _isLoading     = false;
  bool _obscure       = true;
  bool _isRegister    = false;

  late final AnimationController _anim;
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _snack('Please fill in all fields'); return;
    }
    setState(() => _isLoading = true);
    if (_isRegister) {
      final user = await AuthService.register(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user != null) {
        _snack('Account created — welcome!');
        setState(() => _isRegister = false);
      } else { _snack('Registration failed. Try a different email.'); }
    } else {
      final user = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/');
      } else { _snack('Invalid email or password'); }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Karla'))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(children: [
        // ── Gradient hero bg ─────────────────────────────
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primaryGreenDeep, AppTheme.primaryGreenMid, AppTheme.primaryGreen],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Decorative rings
            Positioned(top: -60, right: -60, child: _Ring(size: 220, opacity: 0.07)),
            Positioned(top: 40, right: 50, child: _Ring(size: 90, opacity: 0.06)),
            Positioned(bottom: 30, left: -30, child: _Ring(size: 140, opacity: 0.05)),
            // Fade to background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.backgroundDeep.withValues(alpha: 0.0), AppTheme.backgroundDeep],
                  stops: const [0.6, 0.85, 1.0],
                ),
              ),
            ),
          ]),
        ),

        // ── Scrollable form ──────────────────────────────
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 28),

                  // App icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: const Icon(Icons.terrain_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Headline
                  const Text('Summit\nStories',
                      style: TextStyle(fontFamily: 'Lora', color: Colors.white, fontSize: 42,
                          height: 1.0, fontWeight: FontWeight.w700, letterSpacing: -1)),
                  const SizedBox(height: 10),
                  Text('Collect peaks, memories and\nstories from every corner of Bulgaria.',
                      style: TextStyle(fontFamily: 'Karla', color: Colors.white.withValues(alpha: 0.78), fontSize: 15, height: 1.55)),
                  const SizedBox(height: 40),

                  // ── Auth card with glassmorphism ──────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundCard,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          border: Border.all(color: AppTheme.glassBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 16))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Login / Register toggle
                          _AuthToggle(isRegister: _isRegister, onToggle: (v) => setState(() => _isRegister = v)),
                          const SizedBox(height: 28),

                          // Email field
                          _Field(
                              controller: _emailCtrl, hint: 'your@email.com', label: 'EMAIL',
                              icon: Icons.mail_outline_rounded, type: TextInputType.emailAddress),
                          const SizedBox(height: 16),

                          // Password field
                          _Field(
                              controller: _passCtrl, hint: '••••••••', label: 'PASSWORD',
                              icon: Icons.lock_outline_rounded, obscure: _obscure,
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppTheme.textMuted, size: 20),
                              )),
                          const SizedBox(height: 28),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_isRegister ? 'Create Account' : 'Log In',
                                  style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tagline pills
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _Pill('Track visits'),
                      const SizedBox(width: 8),
                      _Pill('Earn points'),
                      const SizedBox(width: 8),
                      _Pill('Unlock badges'),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────

class _AuthToggle extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onToggle;
  const _AuthToggle({required this.isRegister, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.backgroundDeep, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _Tab(label: 'Log In',   active: !isRegister, onTap: () => onToggle(false)),
        _Tab(label: 'Register', active: isRegister,  onTap: () => onToggle(true)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.backgroundCard : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)] : null,
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.w700, fontSize: 14,
                color: active ? AppTheme.textPrimary : AppTheme.textMuted)),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint, label;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final Widget? suffix;
  const _Field({required this.controller, required this.hint, required this.label,
    required this.icon, this.type = TextInputType.text, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 11, fontWeight: FontWeight.w700,
          color: AppTheme.textMuted, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      TextField(
        controller: controller, keyboardType: type, obscureText: obscure,
        style: const TextStyle(fontFamily: 'Karla', fontSize: 15, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Karla', color: AppTheme.textMuted, fontSize: 15),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffix,
          filled: true, fillColor: AppTheme.backgroundDeep,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: Color(0xFF253545))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: AppTheme.accentOrange, width: 1.5)),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ]);
  }
}

class _Ring extends StatelessWidget {
  final double size, opacity;
  const _Ring({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: opacity), width: size * 0.18),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.primaryGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
    ),
    child: Text(text, style: const TextStyle(fontFamily: 'Karla', fontSize: 11,
        fontWeight: FontWeight.w700, color: AppTheme.primaryGreenLight, letterSpacing: 0.3)),
  );
}