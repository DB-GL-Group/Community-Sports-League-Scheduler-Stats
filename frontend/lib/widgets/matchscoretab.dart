import 'package:flutter/material.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class ScoreTab extends StatelessWidget {
  final om.MatchDetail match;

  const ScoreTab({
    super.key,
    required this.match,
  });

  Color _hexToColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home team
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _hexToColor(match.homeTeam.primaryColor),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 6,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _hexToColor(match.homeTeam.secondaryColor),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match.homeTeam.name,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Score
            Text(
              '${match.homeScore} - ${match.awayScore}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Away team
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.awayTeam.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _hexToColor(match.awayTeam.primaryColor),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 6,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _hexToColor(match.awayTeam.secondaryColor),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ],
                    ),
                  ]
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
