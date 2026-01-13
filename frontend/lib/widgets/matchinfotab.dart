import 'package:flutter/material.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class InfoTab extends StatelessWidget {
  final om.MatchDetail match;

  const InfoTab({required this.match});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.sports),
          title: const Text('Division'),
          subtitle: Text(match.division.toString()),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Referee'),
          subtitle: Text(match.mainReferee.isNotEmpty ? match.mainReferee : 'TBD'),
        ),
        ListTile(
          leading: const Icon(Icons.place),
          title: const Text('Place'),
          subtitle: Text(match.venue?.isNotEmpty == true ? match.venue! : 'TBD'),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Start time'),
          subtitle: Text(match.startTime != null ? match.startTime!.toLocal().toString() : 'TBD'),
        ),
        if (match.notes != null && match.notes!.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.notes),
            title: const Text('Notes'),
            subtitle: Text(match.notes!),
          ),
      ],
    );
  }
}
