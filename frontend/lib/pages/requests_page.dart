import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';

class RequestsPage extends StatelessWidget {

  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Requests',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'No requests yet',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
  
}
