import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/pages/availability_page.dart';
import 'package:community_sports_league_scheduler/pages/match_detail_page.dart';
import 'package:community_sports_league_scheduler/router.dart';

import 'package:community_sports_league_scheduler/pages/assignments_page.dart';
import 'package:community_sports_league_scheduler/pages/matches_page.dart';
import 'package:community_sports_league_scheduler/pages/rankings_page.dart';
import 'package:community_sports_league_scheduler/pages/requests_page.dart';
import 'package:community_sports_league_scheduler/pages/rosters_page.dart';
import 'package:community_sports_league_scheduler/pages/login_page.dart';
import 'package:community_sports_league_scheduler/pages/signup_page.dart';
import 'package:community_sports_league_scheduler/pages/stats_page.dart';
import 'package:community_sports_league_scheduler/pages/admin_keys_page.dart';
import 'package:community_sports_league_scheduler/pages/admin_console_page.dart';
import 'package:community_sports_league_scheduler/pages/admin_scheduler_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(
  MultiProvider(
    providers: [
      Provider<ApiRouter>(
        create: (_) => ApiRouter(),
      ),
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
      ),
    ],
    child: const SportsLeagueScheduler(),
  ),
);

// La class SportsLeagueScheduler est la classe principale du UI.
class SportsLeagueScheduler extends StatelessWidget {
  const SportsLeagueScheduler({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();
    return MaterialApp.router( // Root widget
      title: 'Sports League Scheduler',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF101214),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFFF57C00),
          secondary: const Color(0xFF1976D2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: const Color(0xFF1A1E24),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E2228),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1E24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF57C00)),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF57C00),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFBC02D),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF57C00),
          foregroundColor: Colors.white,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const MatchesPage(),
          ),
          GoRoute(
            path: '/matches/:id',
            builder: (context, state) {
              final matchId = int.parse(state.pathParameters['id']!);
              return MatchDetailPage(matchId: matchId);
            },
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return auth.isLoggedIn ? null : '/';
            },
          ),
          GoRoute(
            path: '/rankings',
            builder: (_, __) => const RankingsPage(),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const LogInPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return auth.isLoggedIn ? '/' : null;
            },
          ),
          GoRoute(
            path: '/signup',
            builder: (_, __) => const SignUpPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return auth.isLoggedIn ? '/' : null;
            },
          ),
          GoRoute(
            path: '/rosters',
            builder: (_, __) => const RostersPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('MANAGER') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/requests',
            builder: (_, __) => const RequestsPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('MANAGER') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/assignments',
            builder: (_, __) => const AssignmentsPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('REFEREE') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/availabilities',
            builder: (_, __) => const AvailabilityPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('REFEREE') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/admin/role-keys',
            builder: (_, __) => const AdminKeysPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('ADMIN') ? '/' : null;
            },
          ),
          GoRoute(
            path: '/admin/console',
            builder: (_, __) => const AdminConsolePage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('ADMIN') ? '/' : null;
            },
          ),
          GoRoute(
            path: '/admin/scheduler',
            builder: (_, __) => const AdminSchedulerPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('ADMIN') ? '/' : null;
            },
          ),
        ],
      ),
    );
  }
}
