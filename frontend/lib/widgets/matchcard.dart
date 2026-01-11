import 'package:flutter/material.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class MatchCard extends StatelessWidget {
  final om.Match match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final bool homeLost = match.homeScore < match.awayScore;
    final bool awayLost = match.awayScore < match.homeScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 62, 62, 62),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Teams
          Expanded(
            child: Column(
              children: [
                _teamRow(
                  team: match.homeTeam,
                  score: match.homeScore,
                  faded: homeLost,
                ),
                const SizedBox(height: 10),
                _teamRow(
                  team: match.awayTeam,
                  score: match.awayScore,
                  faded: awayLost,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 48,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white24,
          ),

          // Status + Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                match.status,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(match.startTime),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamRow({
    required om.Team team,
    required int score,
    required bool faded,
  }) {
    final double opacity = faded ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          // Primary color bar
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: _hexToColor(team.primaryColor),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(width: 2),

          // Secondary color bar
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: _hexToColor(team.secondaryColor),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(width: 8),

          // Team name
          Expanded(
            child: Text(
              team.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Score
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_weekday(date.weekday)} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Color _hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }
}
