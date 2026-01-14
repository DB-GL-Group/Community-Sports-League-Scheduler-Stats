import 'package:community_sports_league_scheduler/widgets/navbar.dart';
import 'package:community_sports_league_scheduler/theme_provider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/network_provider.dart';
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
            tooltip: 'Backend address',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => _showBackendDialog(context),
          ),
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

  Future<void> _showBackendDialog(BuildContext context) async {
    final api = context.read<ApiRouter>();
    final controller = TextEditingController(text: api.getBaseUrl());
    final onSurface = Theme.of(context).colorScheme.onSurface;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backend address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: 'http://192.168.1.42/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              api.setBaseUrl(controller.text);
              context.read<NetworkProvider>().setBaseUrl(controller.text);
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Backend set to ${api.getBaseUrl()}',
                    style: TextStyle(color: onSurface),
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
