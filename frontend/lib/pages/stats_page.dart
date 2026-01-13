import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<_TeamStats>> _statsFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _statsFuture = _loadStats(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<_TeamStats>> _loadStats(ApiRouter apiRouter) async {
    final data = await apiRouter.fetchData('matches/previews');
    final statsByTeam = <String, _TeamStats>{};

    void ensureTeam(String name, String? primary, String? secondary) {
      statsByTeam.putIfAbsent(
        name,
        () => _TeamStats(
          name: name,
          primaryColor: primary,
          secondaryColor: secondary,
        ),
      );
      final current = statsByTeam[name]!;
      if ((current.primaryColor == null || current.primaryColor!.isEmpty) && primary != null) {
        current.primaryColor = primary;
      }
      if ((current.secondaryColor == null || current.secondaryColor!.isEmpty) && secondary != null) {
        current.secondaryColor = secondary;
      }
    }

    for (final match in data) {
      final homeName = match['home_team'] as String;
      final awayName = match['away_team'] as String;
      ensureTeam(homeName, match['home_primary_color'], match['home_secondary_color']);
      ensureTeam(awayName, match['away_primary_color'], match['away_secondary_color']);

      if (match['status'] != 'finished') {
        continue;
      }
      final homeScore = match['home_score'] as int? ?? 0;
      final awayScore = match['away_score'] as int? ?? 0;
      final startRaw = match['start_time'];
      final startTime = startRaw is String ? DateTime.tryParse(startRaw) : null;

      final home = statsByTeam[homeName]!;
      final away = statsByTeam[awayName]!;
      home.played += 1;
      away.played += 1;
      home.goalsFor += homeScore;
      home.goalsAgainst += awayScore;
      away.goalsFor += awayScore;
      away.goalsAgainst += homeScore;

      if (homeScore > awayScore) {
        home.wins += 1;
        away.losses += 1;
        home.points += 3;
        home.form.add(_FormEntry('W', startTime));
        away.form.add(_FormEntry('L', startTime));
      } else if (homeScore < awayScore) {
        away.wins += 1;
        home.losses += 1;
        away.points += 3;
        home.form.add(_FormEntry('L', startTime));
        away.form.add(_FormEntry('W', startTime));
      } else {
        home.draws += 1;
        away.draws += 1;
        home.points += 1;
        away.points += 1;
        home.form.add(_FormEntry('D', startTime));
        away.form.add(_FormEntry('D', startTime));
      }
    }

    final list = statsByTeam.values.toList();
    for (final team in list) {
      team.form.sort((a, b) {
        final aTime = a.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.time ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    }
    list.sort((a, b) {
      final pointsCmp = b.points.compareTo(a.points);
      if (pointsCmp != 0) return pointsCmp;
      final gdCmp = b.goalDifference.compareTo(a.goalDifference);
      if (gdCmp != 0) return gdCmp;
      return b.goalsFor.compareTo(a.goalsFor);
    });
    return list;
  }

  Future<void> _refreshStats() async {
    final stats = await _loadStats(context.read<ApiRouter>());
    setState(() {
      _statsFuture = Future.value(stats);
    });
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
            'Team Stats',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(onPressed: _refreshStats, child: const Text('Refresh')),
            ),
          ],
        ),
        body: FutureBuilder<List<_TeamStats>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading stats'));
            }
            final stats = snapshot.data ?? [];
            if (stats.isEmpty) {
              return const Center(child: Text('No stats available'));
            }
            final totalGoals = stats.fold<int>(0, (sum, s) => sum + s.goalsFor);
            final totalMatches = stats.fold<int>(0, (sum, s) => sum + s.played) ~/ 2;
            final topThree = stats.take(3).toList();

            return RefreshIndicator(
              onRefresh: _refreshStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummary(totalMatches, totalGoals, stats.length),
                  const SizedBox(height: 16),
                  _buildPodium(topThree),
                  const SizedBox(height: 16),
                  ...stats.map(_buildTeamCard).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(int matches, int goals, int teams) {
    return Row(
      children: [
        _SummaryCard(title: 'Matches', value: matches.toString()),
        const SizedBox(width: 12),
        _SummaryCard(title: 'Goals', value: goals.toString()),
        const SizedBox(width: 12),
        _SummaryCard(title: 'Teams', value: teams.toString()),
      ],
    );
  }

  Widget _buildPodium(List<_TeamStats> top) {
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.surface, colorScheme.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: top.map((team) {
          final primary = _colorFromValue(team.primaryColor);
          final secondary = _colorFromValue(team.secondaryColor);
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.95),
                        secondary.withOpacity(0.95),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${team.points} pts', style: TextStyle(color: onSurface.withOpacity(0.7))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamCard(_TeamStats team) {
    final primary = _colorFromValue(team.primaryColor);
    final secondary = _colorFromValue(team.secondaryColor);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(0.18),
            secondary.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 24,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 12,
                height: 24,
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatPill(label: 'Pts', value: team.points.toString()),
              const SizedBox(width: 8),
              _StatPill(label: 'GD', value: team.goalDifference.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: 'P', value: team.played.toString()),
              _MiniStat(label: 'W', value: team.wins.toString()),
              _MiniStat(label: 'D', value: team.draws.toString()),
              _MiniStat(label: 'L', value: team.losses.toString()),
              _MiniStat(label: 'GF', value: team.goalsFor.toString()),
              _MiniStat(label: 'GA', value: team.goalsAgainst.toString()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Form', style: TextStyle(color: onSurface.withOpacity(0.7))),
              const SizedBox(width: 8),
              ...team.form.take(5).map((entry) {
                final color = switch (entry.result) {
                  'W' => const Color(0xFF43A047),
                  'D' => const Color(0xFF9E9E9E),
                  _ => const Color(0xFFE53935),
                };
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.result,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: onSurface.withOpacity(0.7))),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TeamStats {
  final String name;
  String? primaryColor;
  String? secondaryColor;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;
  final List<_FormEntry> form = [];

  _TeamStats({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });

  int get goalDifference => goalsFor - goalsAgainst;
}

class _FormEntry {
  final String result;
  final DateTime? time;

  _FormEntry(this.result, this.time);
}
