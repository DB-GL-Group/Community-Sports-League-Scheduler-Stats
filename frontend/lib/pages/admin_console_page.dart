import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminConsolePage extends StatefulWidget {
  const AdminConsolePage({super.key});

  @override
  State<AdminConsolePage> createState() => _AdminConsolePageState();
}

class _AdminConsolePageState extends State<AdminConsolePage> {
  late Future<List<Map<String, dynamic>>> _matches;
  Map<String, dynamic>? _selectedMatch;
  bool _initialized = false;
  int? _eventTeamId;
  late Future<List<Map<String, dynamic>>> _teamPlayers;
  int? _goalPlayerId;
  int? _cardPlayerId;
  int? _subPlayerOutId;
  int? _subPlayerInId;

  final _goalMinuteController = TextEditingController();
  bool _goalOwnGoal = false;

  final _cardMinuteController = TextEditingController();
  String _cardType = 'Y';
  final _cardReasonController = TextEditingController();

  final _subMinuteController = TextEditingController();


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _matches = _loadMatches();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _goalMinuteController.dispose();
    _cardMinuteController.dispose();
    _cardReasonController.dispose();
    _subMinuteController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMatches() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return [];
    try {
      final data = await context.read<ApiRouter>().fetchData(
        'user/admin/console/matches',
        token: token,
      );
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _refreshMatches() async {
    final matches = await _loadMatches();
    setState(() {
      _matches = Future.value(matches);
      if (_selectedMatch != null) {
        final updated = matches.where((m) => m['id'] == _selectedMatch!['id']).toList();
        _selectedMatch = updated.isNotEmpty ? updated.first : null;
        _eventTeamId = _selectedMatch == null ? null : _selectedMatch!['home_team_id'] as int;
        if (_eventTeamId != null) {
          _teamPlayers = _loadTeamPlayers(_eventTeamId!);
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> _loadTeamPlayers(int teamId) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return [];
    try {
      final data = await context.read<ApiRouter>().fetchData(
        'user/admin/console/teams/$teamId/players',
        token: token,
      );
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Widget _playerDropdown({
    required String label,
    required int? value,
    required void Function(int?) onChanged,
    required Future<List<Map<String, dynamic>>> playersFuture,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: playersFuture,
      builder: (context, snapshot) {
        final players = snapshot.data ?? [];
        return DropdownButtonFormField<int>(
          value: value,
          items: [
            for (final player in players)
              DropdownMenuItem<int>(
                value: player['id'] as int,
                child: Text('${player['first_name']} ${player['last_name']}'),
              ),
          ],
          onChanged: players.isEmpty ? null : onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
          ),
        );
      },
    );
  }

  int? _parseOptionalInt(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> _submitGoal() async {
    if (_selectedMatch == null) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    final teamId = _eventTeamId ?? (_selectedMatch!['home_team_id'] as int);
    final ownGoal = _goalOwnGoal;
    final playerId = _goalPlayerId;
    if (playerId == null) return;
    final minute = _parseOptionalInt(_goalMinuteController);

    await context.read<ApiRouter>().fetchData(
      'user/admin/console/matches/${_selectedMatch!['id']}/goal',
      method: 'POST',
      token: token,
      body: {
        'team_id': teamId,
        'player_id': playerId,
        'minute': minute,
        'is_own_goal': ownGoal,
      },
    );
    _goalPlayerId = null;
    _goalMinuteController.clear();
    await _refreshMatches();
  }

  Future<void> _submitCard() async {
    if (_selectedMatch == null) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    final teamId = _eventTeamId ?? (_selectedMatch!['home_team_id'] as int);
    final playerId = _cardPlayerId;
    if (playerId == null) return;
    final minute = _parseOptionalInt(_cardMinuteController);

    await context.read<ApiRouter>().fetchData(
      'user/admin/console/matches/${_selectedMatch!['id']}/card',
      method: 'POST',
      token: token,
      body: {
        'team_id': teamId,
        'player_id': playerId,
        'minute': minute,
        'card_type': _cardType,
        'reason': _cardReasonController.text.trim().isEmpty
            ? null
            : _cardReasonController.text.trim(),
      },
    );
    _cardPlayerId = null;
    _cardMinuteController.clear();
    _cardReasonController.clear();
    await _refreshMatches();
  }

  Future<void> _submitSubstitution() async {
    if (_selectedMatch == null) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    final teamId = _eventTeamId ?? (_selectedMatch!['home_team_id'] as int);
    final playerOut = _subPlayerOutId;
    final playerIn = _subPlayerInId;
    if (playerOut == null || playerIn == null) return;
    final minute = _parseOptionalInt(_subMinuteController);

    await context.read<ApiRouter>().fetchData(
      'user/admin/console/matches/${_selectedMatch!['id']}/substitution',
      method: 'POST',
      token: token,
      body: {
        'team_id': teamId,
        'player_out_id': playerOut,
        'player_in_id': playerIn,
        'minute': minute,
      },
    );
    _subPlayerOutId = null;
    _subPlayerInId = null;
    _subMinuteController.clear();
    await _refreshMatches();
  }

  Future<void> _finalizeMatch() async {
    if (_selectedMatch == null) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    await context.read<ApiRouter>().fetchData(
      'user/admin/console/matches/${_selectedMatch!['id']}/finalize',
      method: 'POST',
      token: token,
    );
    await _refreshMatches();
  }

  Widget _sectionTitle(String title) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: onSurface,
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required List<Widget> children,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Admin Console', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(onPressed: _refreshMatches, child: const Text('Refresh')),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _matches,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final matches = snapshot.data ?? [];
            if (matches.isEmpty) {
              return const Center(child: Text('No matches in progress'));
            }
            _selectedMatch ??= matches.first;
            _eventTeamId ??= _selectedMatch!['home_team_id'] as int;
            _teamPlayers = _loadTeamPlayers(_eventTeamId!);
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _panel(
                  title: 'Match Control',
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedMatch?['id'] as int?,
                      items: [
                        for (final match in matches)
                          DropdownMenuItem<int>(
                            value: match['id'] as int,
                            child: Text('${match['home_team']} vs ${match['away_team']} (#${match['id']})'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedMatch = matches.firstWhere((m) => m['id'] == value);
                          _eventTeamId = _selectedMatch!['home_team_id'] as int;
                          _teamPlayers = _loadTeamPlayers(_eventTeamId!);
                          _goalPlayerId = null;
                          _cardPlayerId = null;
                          _subPlayerOutId = null;
                          _subPlayerInId = null;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Select match',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMatch != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedMatch!['home_team']} ${_selectedMatch!['home_score']} - '
                                '${_selectedMatch!['away_score']} ${_selectedMatch!['away_team']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _finalizeMatch,
                              child: const Text('Finalize'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _eventTeamId,
                      items: [
                        DropdownMenuItem(
                          value: _selectedMatch!['home_team_id'] as int,
                          child: Text(_selectedMatch!['home_team'] as String),
                        ),
                        DropdownMenuItem(
                          value: _selectedMatch!['away_team_id'] as int,
                          child: Text(_selectedMatch!['away_team'] as String),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _eventTeamId = value;
                          _teamPlayers = _loadTeamPlayers(value);
                          _goalPlayerId = null;
                          _cardPlayerId = null;
                          _subPlayerOutId = null;
                          _subPlayerInId = null;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Event team',
                      ),
                    ),
                  ],
                ),
              ],
            );

            final goalPanel = _panel(
              title: 'Goal',
              children: [
                _playerDropdown(
                  label: 'Scorer',
                  value: _goalPlayerId,
                  onChanged: (value) {
                    setState(() {
                      _goalPlayerId = value;
                    });
                  },
                  playersFuture: _teamPlayers,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _goalMinuteController,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  keyboardType: TextInputType.number,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Own goal'),
                  value: _goalOwnGoal,
                  onChanged: (value) {
                    setState(() {
                      _goalOwnGoal = value ?? false;
                    });
                  },
                ),
                ElevatedButton(onPressed: _submitGoal, child: const Text('Add Goal')),
              ],
            );

            final cardPanel = _panel(
              title: 'Card',
              children: [
                _playerDropdown(
                  label: 'Player',
                  value: _cardPlayerId,
                  onChanged: (value) {
                    setState(() {
                      _cardPlayerId = value;
                    });
                  },
                  playersFuture: _teamPlayers,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardMinuteController,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _cardType,
                  items: const [
                    DropdownMenuItem(value: 'Y', child: Text('Yellow')),
                    DropdownMenuItem(value: 'Y2R', child: Text('Second Yellow')),
                    DropdownMenuItem(value: 'R', child: Text('Red')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _cardType = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Card type',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardReasonController,
                  decoration: const InputDecoration(labelText: 'Reason (optional)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _submitCard, child: const Text('Add Card')),
              ],
            );

            final subPanel = _panel(
              title: 'Substitution',
              children: [
                _playerDropdown(
                  label: 'Player Out',
                  value: _subPlayerOutId,
                  onChanged: (value) {
                    setState(() {
                      _subPlayerOutId = value;
                    });
                  },
                  playersFuture: _teamPlayers,
                ),
                const SizedBox(height: 8),
                _playerDropdown(
                  label: 'Player In',
                  value: _subPlayerInId,
                  onChanged: (value) {
                    setState(() {
                      _subPlayerInId = value;
                    });
                  },
                  playersFuture: _teamPlayers,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subMinuteController,
                  decoration: const InputDecoration(labelText: 'Minute'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _submitSubstitution, child: const Text('Add Substitution')),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: 16),
                        goalPanel,
                        const SizedBox(height: 16),
                        cardPanel,
                        const SizedBox(height: 16),
                        subPanel,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: goalPanel),
                          const SizedBox(width: 16),
                          Expanded(child: cardPanel),
                          const SizedBox(width: 16),
                          Expanded(child: subPanel),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
