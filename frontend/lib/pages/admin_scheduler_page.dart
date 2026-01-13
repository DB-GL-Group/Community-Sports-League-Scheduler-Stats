import 'dart:async';

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
  static DateTime? _lastSeenSchedulerEndedAt;
  static DateTime? _lastSeenGenEndedAt;

  Future<Map<String, dynamic>?> _statusFuture = Future.value(null);
  Future<Map<String, dynamic>?> _genStatusFuture = Future.value(null);
  Future<List<om.Match>> _matchesFuture = Future.value(const <om.Match>[]);
  bool _initialized = false;
  String _message = '';
  Map<String, int> _tabCounts = {
    'all': 0,
    'scheduled': 0,
    'in_progress': 0,
    'finished': 0,
    'postponed': 0,
    'tbd': 0,
    'canceled': 0,
  };
  Timer? _poller;
  Map<String, dynamic>? _lastSchedulerStatus;
  Map<String, dynamic>? _lastGenStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  DateTime? _parseEndedAt(Map<String, dynamic>? status) {
    final raw = status?['ended_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isNewer(DateTime? candidate, DateTime? previous) {
    if (candidate == null) return false;
    if (previous == null) return true;
    return candidate.isAfter(previous);
  }

  void _trackEndedAt(Map<String, dynamic>? status, bool isScheduler) {
    final endedAt = _parseEndedAt(status);
    if (!_isTerminal(status) || endedAt == null) return;
    if (isScheduler) {
      _lastSeenSchedulerEndedAt = endedAt;
    } else {
      _lastSeenGenEndedAt = endedAt;
    }
  }

  Future<void> _bootstrap() async {
    final apiRouter = context.read<ApiRouter>();
    final status = await _loadStatus();
    final genStatus = await _loadGenStatus();
    final matches = await _loadMatches(apiRouter);

    if (!mounted) return;
    setState(() {
      _statusFuture = Future.value(status);
      _genStatusFuture = Future.value(genStatus);
      _matchesFuture = Future.value(matches);
      _tabCounts = _computeCounts(matches);
      _lastSchedulerStatus = status;
      _lastGenStatus = genStatus;
    });

    final schedulerEnded = _parseEndedAt(status);
    final genEnded = _parseEndedAt(genStatus);
    final shouldRefresh =
        _isNewer(schedulerEnded, _lastSeenSchedulerEndedAt) ||
        _isNewer(genEnded, _lastSeenGenEndedAt);

    if (shouldRefresh) {
      final refreshed = await _loadMatches(apiRouter);
      if (!mounted) return;
      setState(() {
        _matchesFuture = Future.value(refreshed);
        _tabCounts = _computeCounts(refreshed);
      });
    }

    _trackEndedAt(status, true);
    _trackEndedAt(genStatus, false);

    if (_isActive(status) || _isActive(genStatus)) {
      _startPolling();
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

  Future<Map<String, dynamic>?> _loadGenStatus() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return null;
    try {
      final data = await context.read<ApiRouter>().fetchData(
        'user/admin/matches/generate/status',
        token: token,
      );
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
    final genStatus = await _loadGenStatus();
    final matches = await _loadMatches(context.read<ApiRouter>());
    setState(() {
      _statusFuture = Future.value(status);
      _genStatusFuture = Future.value(genStatus);
      _matchesFuture = Future.value(matches);
      _tabCounts = _computeCounts(matches);
      _lastSchedulerStatus = status;
      _lastGenStatus = genStatus;
    });
    _trackEndedAt(status, true);
    _trackEndedAt(genStatus, false);
  }

  Future<void> _runScheduler() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    setState(() => _message = 'Scheduler started...');
    _startPolling();
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

  Future<void> _generateMatches() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    setState(() => _message = 'Generating matches...');
    _startPolling();
    try {
      await context.read<ApiRouter>().fetchData(
        'user/admin/matches/generate',
        method: 'POST',
        token: token,
      );
      await _refresh();
    } catch (_) {
      setState(() => _message = 'Failed to generate matches');
    }
  }

  Future<void> _cancelMatch(om.Match match) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel match'),
        content: Text('Cancel ${match.homeTeam.name} vs ${match.awayTeam.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ApiRouter>().fetchData(
        'user/admin/scheduler/matches/${match.id}/cancel',
        method: 'POST',
        token: token,
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Failed to cancel match');
    }
  }

  Future<void> _postponeMatch(om.Match match) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Postpone match'),
        content: Text('Postpone ${match.homeTeam.name} vs ${match.awayTeam.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Postpone'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ApiRouter>().fetchData(
        'user/admin/scheduler/matches/${match.id}/postpone',
        method: 'POST',
        token: token,
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Failed to postpone match');
    }
  }

  bool _isTerminal(Map<String, dynamic>? status) {
    if (status == null) return false;
    final state = status['status']?.toString();
    return state == 'finished' || state == 'failed';
  }

  bool _isActive(Map<String, dynamic>? status) {
    if (status == null) return false;
    final state = status['status']?.toString();
    return state == 'queued' || state == 'started' || state == 'deferred';
  }

  bool _isAnyJobActive() {
    return _isActive(_lastSchedulerStatus) || _isActive(_lastGenStatus);
  }

  bool _isBlockingStatus(Map<String, dynamic>? status) {
    if (status == null) return false;
    final state = status['status']?.toString();
    return state != 'finished' && state != 'failed';
  }

  bool _isAnyJobBlocking() {
    return _isBlockingStatus(_lastSchedulerStatus) || _isBlockingStatus(_lastGenStatus);
  }

  int? _resultCount(Map<String, dynamic>? status, String key) {
    final result = status?['result'];
    if (result is Map && result[key] is int) {
      return result[key] as int;
    }
    return null;
  }

  bool _transitionedToTerminal(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    if (after == null) return false;
    if (before == null) return _isTerminal(after);
    return before['status'] != after['status'] && _isTerminal(after);
  }

  Future<void> _pollStatuses() async {
    if (!mounted) return;
    final status = await _loadStatus();
    final genStatus = await _loadGenStatus();
    final refreshMatches =
        _transitionedToTerminal(_lastSchedulerStatus, status) ||
        _transitionedToTerminal(_lastGenStatus, genStatus);

    final schedulerChanged =
        status != null && _lastSchedulerStatus?['status'] != status['status'];
    final genChanged =
        genStatus != null && _lastGenStatus?['status'] != genStatus['status'];

    setState(() {
      _statusFuture = Future.value(status);
      _genStatusFuture = Future.value(genStatus);
      _lastSchedulerStatus = status;
      _lastGenStatus = genStatus;
      if (schedulerChanged) {
        final state = status?['status']?.toString();
        if (state == 'started' || state == 'queued') {
          _message = 'Scheduler running...';
        } else if (state == 'finished') {
          final scheduled = _resultCount(status, 'scheduled');
          _message = scheduled == null
              ? 'Scheduler finished.'
              : 'Scheduler finished. $scheduled match(es) planned.';
        } else if (state == 'failed') {
          _message = 'Scheduler failed.';
        }
      }
      if (genChanged) {
        final state = genStatus?['status']?.toString();
        if (state == 'started' || state == 'queued') {
          _message = 'Generating matches...';
        } else if (state == 'finished') {
          final created = _resultCount(genStatus, 'created');
          _message = created == null
              ? 'Match generation finished.'
              : 'Match generation finished. $created match(es) created.';
        } else if (state == 'failed') {
          _message = 'Match generation failed.';
        }
      }
    });

    if (refreshMatches) {
      final matches = await _loadMatches(context.read<ApiRouter>());
      if (!mounted) return;
      setState(() {
        _matchesFuture = Future.value(matches);
        _tabCounts = _computeCounts(matches);
      });
    }

    _trackEndedAt(status, true);
    _trackEndedAt(genStatus, false);

    if (!_isActive(status) && !_isActive(genStatus)) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatuses());
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
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

  List<om.Match> _filterByStatus(List<om.Match> matches, String status) {
    return matches.where((match) => match.status == status).toList();
  }

  Map<String, int> _computeCounts(List<om.Match> matches) {
    return {
      'all': matches.length,
      'scheduled': _filterByStatus(matches, 'scheduled').length,
      'in_progress': _filterByStatus(matches, 'in_progress').length,
      'finished': _filterByStatus(matches, 'finished').length,
      'postponed': _filterByStatus(matches, 'postponed').length,
      'tbd': _filterByStatus(matches, 'tbd').length,
      'canceled': _filterByStatus(matches, 'canceled').length,
    };
  }

  List<Widget> _buildTabs(Map<String, int> counts) {
    return [
      Tab(text: 'All (${counts['all'] ?? 0})'),
      Tab(text: 'Scheduled (${counts['scheduled'] ?? 0})'),
      Tab(text: 'In progress (${counts['in_progress'] ?? 0})'),
      Tab(text: 'Finished (${counts['finished'] ?? 0})'),
      Tab(text: 'Postponed (${counts['postponed'] ?? 0})'),
      Tab(text: 'TBD (${counts['tbd'] ?? 0})'),
      Tab(text: 'Canceled (${counts['canceled'] ?? 0})'),
    ];
  }

  Widget _buildMatchesList(List<om.Match> matches) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(matches[index]);
        },
      ),
    );
  }

  Widget _buildMatchCard(om.Match match) {
    final isTerminal = match.status == 'canceled' || match.status == 'finished';
    final isBlocked = _isAnyJobBlocking();
    final canEdit = !isTerminal && !isBlocked;
    final canPostpone = canEdit && match.status != 'postponed';
    return MatchCard(
      match: match,
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(
            icon: Icons.schedule,
            tooltip: 'Postpone',
            color: const Color(0xFFFBC02D),
            enabled: canPostpone,
            onPressed: () => _postponeMatch(match),
          ),
          const SizedBox(width: 8),
          _actionButton(
            icon: Icons.cancel,
            tooltip: 'Cancel',
            color: const Color(0xFFD32F2F),
            enabled: canEdit,
            onPressed: () => _cancelMatch(match),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withOpacity(0.35),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 18, color: enabled ? color : onSurface.withOpacity(0.35)),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          splashRadius: 18,
        ),
      ),
    );
  }

  String _formatStatus(Map<String, dynamic>? status) {
    if (status == null) return 'No scheduler job yet';
    final jobStatus = status['status']?.toString() ?? 'unknown';
    final started = status['started_at']?.toString();
    final ended = status['ended_at']?.toString();
    if (jobStatus == 'finished' && ended != null) {
      final result = status['result'];
      final scheduled = result is Map ? result['scheduled'] : null;
      if (scheduled is int) {
        return 'Finished at $ended · Scheduled $scheduled';
      }
      return 'Finished at $ended';
    }
    if (jobStatus == 'started' && started != null) {
      return 'Running since $started';
    }
    return 'Status: $jobStatus';
  }

  String _formatGenStatus(Map<String, dynamic>? status) {
    if (status == null) return 'No generation job yet';
    final jobStatus = status['status']?.toString() ?? 'unknown';
    final started = status['started_at']?.toString();
    final ended = status['ended_at']?.toString();
    if (jobStatus == 'finished' && ended != null) {
      final result = status['result'];
      final created = result is Map ? result['created'] : null;
      if (created is int) {
        return 'Generation finished at $ended · Created $created';
      }
      return 'Generation finished at $ended';
    }
    if (jobStatus == 'started' && started != null) {
      return 'Generation running since $started';
    }
    return 'Generation status: $jobStatus';
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: DefaultTabController(
        length: 7,
        child: Scaffold(
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
            bottom: TabBar(
              isScrollable: true,
              tabs: _buildTabs(_tabCounts),
            ),
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatStatus(statusSnapshot.data)),
                                const SizedBox(height: 6),
                                FutureBuilder<Map<String, dynamic>?>(
                                  future: _genStatusFuture,
                                  builder: (context, genSnapshot) {
                                    return Text(_formatGenStatus(genSnapshot.data));
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isAnyJobBlocking() ? null : _generateMatches,
                            child: const Text('Generate Matches'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isAnyJobBlocking() ? null : _runScheduler,
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
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
                        return TabBarView(
                          children: [
                            _buildMatchesList(matches),
                            _buildMatchesList(_filterByStatus(matches, 'scheduled')),
                            _buildMatchesList(_filterByStatus(matches, 'in_progress')),
                            _buildMatchesList(_filterByStatus(matches, 'finished')),
                            _buildMatchesList(_filterByStatus(matches, 'postponed')),
                            _buildMatchesList(_filterByStatus(matches, 'tbd')),
                            _buildMatchesList(_filterByStatus(matches, 'canceled')),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
