import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/matchcard.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminSchedulerPage extends StatefulWidget {
  const AdminSchedulerPage({super.key});

  @override
  State<AdminSchedulerPage> createState() => _AdminSchedulerPageState();
}

class _AdminSchedulerPageState extends State<AdminSchedulerPage> {
  late Future<Map<String, dynamic>?> _statusFuture;
  late Future<List<om.Match>> _matchesFuture;
  bool _initialized = false;
  String _message = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _statusFuture = _loadStatus();
      _matchesFuture = _loadMatches(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<Map<String, dynamic>?> _loadStatus() async {
    try {
      final data = await context.read<ApiRouter>().fetchData('scheduler/status');
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<om.Match>> _loadMatches(ApiRouter apiRouter) async {
    final matches = <om.Match>[];
    try {
      final data = await apiRouter.fetchData("matches/previews");
      for (final matchJson in data) {
        matches.add(om.Match.fromJson(matchJson));
      }
    } catch (_) {}
    return matches;
  }

  Future<void> _refresh() async {
    final status = await _loadStatus();
    final matches = await _loadMatches(context.read<ApiRouter>());
    setState(() {
      _statusFuture = Future.value(status);
      _matchesFuture = Future.value(matches);
    });
  }

  Future<void> _runScheduler() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    setState(() => _message = 'Scheduler started...');
    try {
      await context.read<ApiRouter>().fetchData(
        'user/admin/scheduler/run',
        method: 'POST',
        token: token,
      );
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Failed to start scheduler');
    }
  }

  List<om.Match> _sortedMatches(List<om.Match> matches) {
    matches.sort(
      (a, b) {
        final aTime = a.startTime;
        final bTime = b.startTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      },
    );
    return matches;
  }

  String _formatStatus(Map<String, dynamic>? status) {
    if (status == null) return 'No scheduler job yet';
    final jobStatus = status['status']?.toString() ?? 'unknown';
    final started = status['started_at']?.toString();
    final ended = status['ended_at']?.toString();
    if (jobStatus == 'finished' && ended != null) {
      return 'Finished at $ended';
    }
    if (jobStatus == 'started' && started != null) {
      return 'Running since $started';
    }
    return 'Status: $jobStatus';
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Scheduler', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _statusFuture,
          builder: (context, statusSnapshot) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1E24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_formatStatus(statusSnapshot.data)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _runScheduler,
                          child: const Text('Run Scheduler'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<om.Match>>(
                    future: _matchesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final matches = _sortedMatches([...snapshot.data ?? []]);
                      if (matches.isEmpty) {
                        return const Center(child: Text('No scheduled matches yet'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          return MatchCard(match: matches[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
