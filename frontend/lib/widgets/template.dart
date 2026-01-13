import 'package:community_sports_league_scheduler/widgets/navbar.dart';
import 'package:community_sports_league_scheduler/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Template extends StatelessWidget {
  final Widget pageBody;

  const Template({super.key, required this.pageBody});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        title: Text('Sports League Scheduler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: pageBody
    );
  }
}
