import 'package:flutter/material.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class MatchCard extends StatelessWidget {
  final om.Match match;
  final Widget? actions;

  const MatchCard({super.key, required this.match, this.actions});

  @override
  Widget build(BuildContext context) {
    final bool homeLost = match.homeScore < match.awayScore;
    final bool awayLost = match.awayScore < match.homeScore;
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final onSurface = colorScheme.onSurface;
    final onSurfaceMuted = onSurface.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                  textColor: onSurface,
                ),
                const SizedBox(height: 10),
                _teamRow(
                  team: match.awayTeam,
                  score: match.awayScore,
                  faded: awayLost,
                  textColor: onSurface,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 48,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: dividerColor.withOpacity(0.35),
          ),

          // Status + Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                match.status,
                style: TextStyle(
                  color: _statusColor(match.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(match.startTime),
                style: TextStyle(
                  color: onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
              if (actions != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: actions!,
                ),
              ],
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
    required Color textColor,
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
              style: TextStyle(
                color: textColor,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Score
          Text(
            score.toString(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return '${_weekday(date.weekday)} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF90CAF9);
      case 'in_progress':
        return const Color(0xFFFFCC80);
      case 'finished':
        return const Color(0xFF81C784);
      case 'postponed':
        return const Color(0xFFE57373);
      case 'canceled':
        return const Color(0xFFD32F2F);
      case 'tbd':
        return const Color(0xFFB39DDB);
      default:
        return Colors.white70;
    }
  }

  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Color _hexToColor(String? value) {
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
}
