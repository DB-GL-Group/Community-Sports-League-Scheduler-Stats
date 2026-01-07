import 'package:community_sports_league_scheduler/widgets/navbar.dart';
import 'package:flutter/material.dart';

class Template extends StatelessWidget {
  final Widget pageBody;

  const Template({super.key, required this.pageBody});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        title: Text('Sports League Scheduler'),
        backgroundColor: Color.fromARGB(255, 50, 50, 50),
        foregroundColor: Colors.white,
      ),
      body: pageBody
    );
  }
}