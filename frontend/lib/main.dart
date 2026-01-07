import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/pages/assignments_page.dart';

import 'package:community_sports_league_scheduler/pages/matches_page.dart';
import 'package:community_sports_league_scheduler/pages/rankings_page.dart';
import 'package:community_sports_league_scheduler/pages/requests_page.dart';
import 'package:community_sports_league_scheduler/pages/rosters_page.dart';
import 'package:community_sports_league_scheduler/pages/signin_page.dart';
import 'package:community_sports_league_scheduler/pages/stats_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: SportsLeagueScheduler(),
  )
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
            path: '/rankings',
            builder: (_, __) => const RankingsPage(),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsPage(),
          ),
          GoRoute(
            path: '/signin',
            builder: (_, __) => const SignInPage(),
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
              return !auth.hasRole('manager') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/requests',
            builder: (_, __) => const RequestsPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('manager') ? '/' : null;
            }
          ),
          GoRoute(
            path: '/assignments',
            builder: (_, __) => const AssignmentsPage(),
            redirect: (context, state) {
              final auth = context.read<AuthProvider>();
              return !auth.hasRole('referee') ? '/' : null;
            }
          ),
        ],
      ),
    );
  }
}
