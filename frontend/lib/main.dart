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
import 'package:community_sports_league_scheduler/pages/admin_venues_page.dart';
import 'package:community_sports_league_scheduler/theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(
  MultiProvider(
    providers: [
      Provider<ApiRouter>(
        create: (_) => ApiRouter(
          onSessionExpired: () async {
            final context = navigatorKey.currentContext;
            if (context == null) return;
            final auth = Provider.of<AuthProvider>(context, listen: false);
            auth.signOut();
            final shouldLogin = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Session expirée'),
                content: const Text(
                  'Votre session a expiré. Voulez-vous vous reconnecter pour la prolonger ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Plus tard'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Se reconnecter'),
                  ),
                ],
              ),
            );
            if (shouldLogin == true && context.mounted) {
              GoRouter.of(context).go('/login');
            }
          },
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
      ),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => SportsLeagueScheduler(
        themeMode: themeProvider.themeMode,
      ),
    ),
  ),
);

// La class SportsLeagueScheduler est la classe principale du UI.
class SportsLeagueScheduler extends StatefulWidget {
  const SportsLeagueScheduler({super.key, this.themeMode = ThemeMode.dark});

  final ThemeMode themeMode;

  @override
  State<SportsLeagueScheduler> createState() => _SportsLeagueSchedulerState();
}

class _SportsLeagueSchedulerState extends State<SportsLeagueScheduler> {
  late final GoRouter _router;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _router = GoRouter(
      navigatorKey: navigatorKey,
      refreshListenable: _auth,
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
          redirect: (_, __) => _auth.isLoggedIn ? null : '/',
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
          redirect: (_, __) => _auth.isLoggedIn ? '/' : null,
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignUpPage(),
          redirect: (_, __) => _auth.isLoggedIn ? '/' : null,
        ),
        GoRoute(
          path: '/rosters',
          builder: (_, __) => const RostersPage(),
          redirect: (_, __) => !_auth.hasRole('MANAGER') ? '/' : null,
        ),
        GoRoute(
          path: '/requests',
          builder: (_, __) => const RequestsPage(),
          redirect: (_, __) => !_auth.hasRole('MANAGER') ? '/' : null,
        ),
        GoRoute(
          path: '/assignments',
          builder: (_, __) => const AssignmentsPage(),
          redirect: (_, __) => !_auth.hasRole('REFEREE') ? '/' : null,
        ),
        GoRoute(
          path: '/availabilities',
          builder: (_, __) => const AvailabilityPage(),
          redirect: (_, __) => !_auth.hasRole('REFEREE') ? '/' : null,
        ),
        GoRoute(
          path: '/admin/role-keys',
          builder: (_, __) => const AdminKeysPage(),
          redirect: (_, __) => !_auth.hasRole('ADMIN') ? '/' : null,
        ),
        GoRoute(
          path: '/admin/console',
          builder: (_, __) => const AdminConsolePage(),
          redirect: (_, __) => !_auth.hasRole('ADMIN') ? '/' : null,
        ),
        GoRoute(
          path: '/admin/scheduler',
          builder: (_, __) => const AdminSchedulerPage(),
          redirect: (_, __) => !_auth.hasRole('ADMIN') ? '/' : null,
        ),
        GoRoute(
          path: '/admin/venues',
          builder: (_, __) => const AdminVenuesPage(),
          redirect: (_, __) => !_auth.hasRole('ADMIN') ? '/' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();
    final lightTheme = ThemeData.light();
    return MaterialApp.router( // Root widget
      title: 'Sports League Scheduler',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      theme: lightTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F2EB),
        colorScheme: lightTheme.colorScheme.copyWith(
          primary: const Color(0xFFB8501E),
          secondary: const Color(0xFF1976D2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1E24),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1E24),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1E24)),
        ),
        cardColor: const Color(0xFFF0E7DA),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFFE1D6C7),
          contentTextStyle: TextStyle(color: Color(0xFF1A1E24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0E7DA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB8501E)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF3A3A3A)),
          hintStyle: const TextStyle(color: Color(0xFF7A7A7A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB8501E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8C6A1C),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFB8501E),
          foregroundColor: Colors.white,
        ),
        textTheme: lightTheme.textTheme.apply(
          bodyColor: const Color(0xFF1A1E24),
          displayColor: const Color(0xFF1A1E24),
        ),
      ),
      darkTheme: baseTheme.copyWith(
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
      routerConfig: _router,
    );
  }
}
