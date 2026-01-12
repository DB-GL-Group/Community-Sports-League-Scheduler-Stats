import 'package:flutter/material.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class PlayersTab extends StatelessWidget {
  final om.MatchDetail match;

  const PlayersTab({required this.match});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _teamPlayers(match.homeTeam),
        _teamPlayers(match.awayTeam),
      ],
    );
  }

  Widget _teamPlayers(om.TeamDetail team) {
    return ExpansionTile(
      title: Text(
        team.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: team.players.map((player) {
        return ListTile(
          leading: Text(
            '#${player.number}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: Text('${player.firstName} ${player.lastName}'),
        );
      }).toList(),
    );
  }
}
