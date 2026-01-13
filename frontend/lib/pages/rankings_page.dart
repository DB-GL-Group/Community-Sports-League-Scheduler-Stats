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
  int _selectedDivision = 1;

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
      final data = await apiRouter.fetchData('matches/rankings/$_selectedDivision');
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

  Color _colorFromValue(String? value) {
    if (value == null || value.isEmpty) {
      return const Color(0xFF9E9E9E);
    }
    const named = {
      'red': 0xFFD32F2F,
      'blue': 0xFF1976D2,
      'green': 0xFF388E3C,
      'yellow': 0xFFFBC02D,
      'orange': 0xFFF57C00,
      'purple': 0xFF7B1FA2,
      'black': 0xFF212121,
      'white': 0xFFFFFFFF,
      'grey': 0xFF616161,
      'gray': 0xFF616161,
      'lightgrey': 0xFFE0E0E0,
      'lightgray': 0xFFE0E0E0,
    };
    final lowered = value.toLowerCase();
    if (named.containsKey(lowered)) {
      return Color(named[lowered]!);
    }
    final cleanHex = value.replaceAll('#', '');
    if (cleanHex.length != 6) {
      return const Color(0xFF9E9E9E);
    }
    try {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
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
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedDivision,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: Theme.of(context).colorScheme.surface,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedDivision = value;
                    _rankingFuture = _loadRanking(context.read<ApiRouter>());
                  });
                },
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Division 1')),
                  DropdownMenuItem(value: 2, child: Text('Division 2')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _refreshRanking,
                child: const Text('Refresh'),
              ),
            ),
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
                    final primaryColor = _colorFromValue(entry.team_primary_color);
                    final secondaryColor = _colorFromValue(entry.team_secondary_color);

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
