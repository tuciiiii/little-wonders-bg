import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/app_export.dart';
import 'services/auth_service.dart';

import 'screens/login_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('visits');
  await Hive.openBox('badges');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: AppLoadingOverlay());
          }
          return snapshot.hasData ? const MainShell() : const LoginScreen();
        },
      ),
      routes: {
        '/login':   (_) => const LoginScreen(),
        '/map':     (_) => const MainShell(),
        '/profile': (_) => const ProfileScreen(),
        '/badges':  (_) => const BadgesScreen(),
      },
    );
  }
}

// ── 5-tab shell ───────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    FeedScreen(),
    JournalScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _AppNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Nav bar ───────────────────────────────────────────────────────────────────
class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppNavBar({required this.currentIndex, required this.onTap});

  static final _items = [
    (icon: Icons.map_outlined,           activeIcon: Icons.map_rounded,           label: 'Map'),
    (icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library_rounded, label: 'Feed'),
    (icon: Icons.book_outlined,          activeIcon: Icons.book_rounded,          label: 'Journal'),
    (icon: Icons.emoji_events_outlined,  activeIcon: Icons.emoji_events_rounded,  label: 'Badges'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,        label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.84),
                border: Border.all(color: AppColors.glassBorder),
                borderRadius: const BorderRadius.all(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    final active = i == currentIndex;
                    return Expanded(
                      child: _NavItem(
                        icon: active ? item.activeIcon : item.icon,
                        label: item.label,
                        active: active,
                        onTap: () => onTap(i),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: const BorderRadius.all(AppRadius.md),
          boxShadow: active
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26, height: 3,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Icon(icon, size: 22, color: active ? Colors.white : AppColors.textLight),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}