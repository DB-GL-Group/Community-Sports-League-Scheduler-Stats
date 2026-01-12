import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/matchcard.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<StatefulWidget> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late Future<List<om.Match>> _matches;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _matches = _loadMatches(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<om.Match>> _loadMatches(ApiRouter apiRouter) async {
    List<om.Match> matches = [];
    try {
      final data = await apiRouter.fetchData("matches/previews");
      for(Map<String, dynamic> matchJson in data) {
        matches.add(om.Match.fromJson(matchJson));
      }
    } catch (e) {
      print(e.toString());
    } finally {
      return matches;
    }
    // return [
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Thoune',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Lucerne',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 4,
    //     awayScore: 1,
    //     startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Grasshoper',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Servette',
    //       primaryColor: '#992E40',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 0,
    //     awayScore: 1,
    //     startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'St. Gallen',
    //       primaryColor: '#00FF00',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'FC Zürich',
    //       primaryColor: '#FFFFFF',
    //       secondaryColor: '#0000FF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 1,
    //     awayScore: 2,
    //     startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'FC Winterthour',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#000000',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'FC Basel',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#0000FF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 1,
    //     awayScore: 2,
    //     startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Lausanne',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Lugano',
    //       primaryColor: '#000000',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 0,
    //     awayScore: 0,
    //     startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Sion',
    //       primaryColor: '#FFFFFF',
    //       secondaryColor: '#FF0000',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Young Boys',
    //       primaryColor: '#FFFF00',
    //       secondaryColor: '#000000',
    //     ),
    //     status: 'Finished',
    //     homeScore: 2,
    //     awayScore: 0,
    //     startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Thoune',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Lucerne',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 4,
    //     awayScore: 1,
    //     startTime: DateTime.parse('2025-12-08T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Grasshoper',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Servette',
    //       primaryColor: '#992E40',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 0,
    //     awayScore: 1,
    //     startTime: DateTime.parse('2025-12-08T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'St. Gallen',
    //       primaryColor: '#00FF00',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'FC Zürich',
    //       primaryColor: '#FFFFFF',
    //       secondaryColor: '#0000FF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 1,
    //     awayScore: 2,
    //     startTime: DateTime.parse('2025-12-08T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'FC Winterthour',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#000000',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'FC Basel',
    //       primaryColor: '#FF0000',
    //       secondaryColor: '#0000FF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 1,
    //     awayScore: 2,
    //     startTime: DateTime.parse('2025-12-09T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Lausanne',
    //       primaryColor: '#0000FF',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Lugano',
    //       primaryColor: '#000000',
    //       secondaryColor: '#FFFFFF',
    //     ),
    //     status: 'Finished',
    //     homeScore: 0,
    //     awayScore: 0,
    //     startTime: DateTime.parse('2025-12-09T18:00:00.356518Z'),
    //   ),
    //   om.Match(
    //     divisionName: 'First Division',
    //     homeTeam: om.Team(
    //       name: 'Sion',
    //       primaryColor: '#FFFFFF',
    //       secondaryColor: '#FF0000',
    //     ),
    //     awayTeam: om.Team(
    //       name: 'Young Boys',
    //       primaryColor: '#FFFF00',
    //       secondaryColor: '#000000',
    //     ),
    //     status: 'Finished',
    //     homeScore: 2,
    //     awayScore: 0,
    //     startTime: DateTime.parse('2025-12-09T18:00:00.356518Z'),
    //   ),
    // ];
  }

  List<om.Match> _sortMatches(List<om.Match> matches) {
    matches.sort(
      (a, b) => b.startTime.compareTo(a.startTime),
    );
    return matches;
  }

  Future<void> _refreshMatches() async {
    final matches = await _loadMatches(context.read<ApiRouter>());
    setState(() {
      _matches = Future.value(matches);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Matches',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [ElevatedButton(onPressed: _refreshMatches, child: const Text('Refresh'))],
        ),
        body: FutureBuilder(future: _matches,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading matches'));
            }
            final sortedMatches = _sortMatches([...snapshot.data!]);
            return RefreshIndicator(
              onRefresh: _refreshMatches,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedMatches.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      context.push('/matches/${sortedMatches[index].id}');
                    },
                    child: MatchCard(match: sortedMatches[index]),
                  );
                },
              )
            );
          }
        ),
      )
    );
  }
}