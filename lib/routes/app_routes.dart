import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/badges_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/login_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String mapScreen = '/map-screen';
  static const String feedScreen = '/feed-screen';
  static const String journalScreen = '/journal-screen';
  static const String profileScreen = '/profile-screen';
  static const String badgesScreen = '/badges-screen';
  static const String leaderboard = '/leaderboard';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes = {
    initial: (_) => const MapScreen(),
    mapScreen: (_) => const MapScreen(),
    feedScreen: (_) => const FeedScreen(),
    journalScreen: (_) => const JournalScreen(),
    profileScreen: (_) => const ProfileScreen(),
    badgesScreen: (_) => const BadgesScreen(),
    leaderboard: (_) => const LeaderboardScreen(),
    login: (_) => const LoginScreen(),
  };
}
