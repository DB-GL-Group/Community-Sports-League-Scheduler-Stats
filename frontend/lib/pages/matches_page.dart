import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/matchcard.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:community_sports_league_scheduler/authprovider.dart';
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
  Map<String, int> _tabCounts = {
    'all': 0,
    'scheduled': 0,
    'in_progress': 0,
    'finished': 0,
    'postponed': 0,
    'tbd': 0,
    'canceled': 0,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _matches = _loadMatches(context.read<ApiRouter>());
      _matches.then((matches) {
        if (!mounted) return;
        setState(() {
          _tabCounts = _computeCounts(matches);
        });
      });
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
      throw Exception("Error loading matches: $e");
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
      (a, b) {
        final aTime = a.startTime;
        final bTime = b.startTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      },
    );
    return matches;
  }

  Future<void> _refreshMatches() async {
    final matches = await _loadMatches(context.read<ApiRouter>());
    setState(() {
      _matches = Future.value(matches);
      _tabCounts = _computeCounts(matches);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          title: const Text(
            'Matches',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(onPressed: _refreshMatches, child: const Text('Refresh')),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: _buildTabs(_tabCounts),
            ),
          ),
          body: FutureBuilder(
            future: _matches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading matches'));
              }
              final sortedMatches = _sortMatches([...snapshot.data!]);
              return TabBarView(
                children: [
                  _buildMatchesList(sortedMatches),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'scheduled')),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'in_progress')),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'finished')),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'postponed')),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'tbd')),
                  _buildMatchesList(_filterByStatus(sortedMatches, 'canceled')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<om.Match> _filterByStatus(List<om.Match> matches, String status) {
    return matches.where((match) => match.status == status).toList();
  }

  Map<String, int> _computeCounts(List<om.Match> matches) {
    return {
      'all': matches.length,
      'scheduled': _filterByStatus(matches, 'scheduled').length,
      'in_progress': _filterByStatus(matches, 'in_progress').length,
      'finished': _filterByStatus(matches, 'finished').length,
      'postponed': _filterByStatus(matches, 'postponed').length,
      'tbd': _filterByStatus(matches, 'tbd').length,
      'canceled': _filterByStatus(matches, 'canceled').length,
    };
  }

  List<Widget> _buildTabs(Map<String, int> counts) {
    return [
      Tab(text: 'All (${counts['all'] ?? 0})'),
      Tab(text: 'Scheduled (${counts['scheduled'] ?? 0})'),
      Tab(text: 'In progress (${counts['in_progress'] ?? 0})'),
      Tab(text: 'Finished (${counts['finished'] ?? 0})'),
      Tab(text: 'Postponed (${counts['postponed'] ?? 0})'),
      Tab(text: 'TBD (${counts['tbd'] ?? 0})'),
      Tab(text: 'Canceled (${counts['canceled'] ?? 0})'),
    ];
  }

  Widget _buildMatchesList(List<om.Match> matches) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return RefreshIndicator(
      onRefresh: _refreshMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to view match details.')),
                );
                context.go('/login');
                return;
              }
              context.push('/matches/${matches[index].id}');
            },
            child: MatchCard(match: matches[index]),
          );
        },
      ),
    );
  }
}
