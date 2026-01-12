import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/widgets/matchinfotab.dart';
import 'package:community_sports_league_scheduler/widgets/matchplayerstab.dart';
import 'package:community_sports_league_scheduler/widgets/matchscoretab.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class MatchDetailPage extends StatefulWidget {
  final int matchId;

  const MatchDetailPage({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late Future<om.MatchDetail> _matchFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _matchFuture = _loadMatch(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<om.MatchDetail> _loadMatch(ApiRouter apiRouter) async {
    try {
      final token = context.read<AuthProvider>().user?.access_token ?? '';
      final data = await apiRouter.fetchData('matches/${widget.matchId}', token: token);
      return om.MatchDetail.fromJson(data);
    } catch (e) {
      throw Exception('Error loading match detail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Match Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Info'),
                Tab(text: 'Score'),
                Tab(text: 'Players'),
              ],
            ),
          ),
          body: FutureBuilder<om.MatchDetail>(
            future: _matchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading match details'),
                );
              }

              final match = snapshot.data!;

              return TabBarView(
                children: [
                  InfoTab(match: match),
                  ScoreTab(match: match),
                  PlayersTab(match: match),
                ],
              );
            },
          ),
        ),
      )
    );
  }
}