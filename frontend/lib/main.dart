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
    return MaterialApp.router( // Root widget
      title: 'Sports League Scheduler',
      debugShowCheckedModeBanner: false,
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
