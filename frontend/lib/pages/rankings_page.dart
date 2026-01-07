import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';

class RankingsPage extends StatelessWidget {

  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: const Center(
        child: Text('Rankings Page')
      )
    );
  }
  
}
