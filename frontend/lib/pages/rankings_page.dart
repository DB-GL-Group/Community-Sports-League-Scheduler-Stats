import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  late Future<List<om.RankingEntry>> _rankingFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _rankingFuture = _loadRanking(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<om.RankingEntry>> _loadRanking(ApiRouter apiRouter) async {
    List<om.RankingEntry> ranking = [];
    try {
      final data = await apiRouter.fetchData('matches/rankings');
      int rank = 1;
      for (Map<String, dynamic> rkentry in data) {
        ranking.add(om.RankingEntry.fromJson(rank, rkentry));
        rank += 1;
      }
    } catch (e) {
      throw Exception("Error loading ranking: $e");
    } finally {
      return ranking;
    }
  }

  Future<void> _refreshRanking() async {
    final ranking = await _loadRanking(context.read<ApiRouter>());
    setState(() {
      _rankingFuture = Future.value(ranking);
    });
  }

  List<om.RankingEntry> _sortEntries(List<om.RankingEntry> ranking) {
    ranking.sort((a, b) => a.rank.compareTo(b.rank));
    return ranking;
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Rankings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              onPressed: _refreshRanking,
              child: const Text('Refresh'),
            )
          ],
        ),
        body: FutureBuilder<List<om.RankingEntry>>(
          future: _rankingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading ranking'));
            }

            final ranking = _sortEntries([...snapshot.data!]);

            return RefreshIndicator(
              onRefresh: _refreshRanking,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('GD', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: ranking.map((entry) {
                    final primaryColor = Color(int.parse('0xff${entry.team_primary_color.substring(1)}'));
                    final secondaryColor = Color(int.parse('0xff${entry.team_secondary_color.substring(1)}'));

                    return DataRow(
                      cells: [
                        DataCell(Text('${entry.rank}')),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: primaryColor,
                                child: CircleAvatar(radius: 6, backgroundColor: secondaryColor),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.team_name),
                            ],
                          ),
                        ),
                        DataCell(Text('${entry.points}')),
                        DataCell(Text('${entry.goal_difference}')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}