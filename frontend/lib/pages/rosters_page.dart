import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/widgets/playercard.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RostersPage extends StatefulWidget {
  const RostersPage({super.key});

  @override
  State<StatefulWidget> createState() => _RostersPageState();
}

class _RostersPageState extends State<RostersPage> {
  late Future<List<om.Player>> _players;
  late Future<Map<String, dynamic>?> _team;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _team = _loadTeam(context.read<ApiRouter>());
      _players = _loadPlayers(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<Map<String, dynamic>?> _loadTeam(ApiRouter apiRouter) async {
    try {
      final token = context.read<AuthProvider>().user?.access_token ?? '';
      if (token.isEmpty) return null;
      final data = await apiRouter.fetchData("user/manager/team", token: token);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<om.Player>> _loadPlayers(ApiRouter apiRouter) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return [];
    try {
      final data = await apiRouter.fetchData("user/manager/team/players", token: token);
      final rows = data is List ? data : [];
      return rows.map<om.Player>((row) {
        final map = row as Map<String, dynamic>;
        final numberValue = map['number'];
        return om.Player(
          id: map['id'] as int,
          firstName: (map['first_name'] ?? map['firstName']) as String,
          lastName: (map['last_name'] ?? map['lastName']) as String,
          number: numberValue is int ? numberValue : int.tryParse(numberValue?.toString() ?? ''),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refreshPlayers() async {
    final team = await _loadTeam(context.read<ApiRouter>());
    final players = await _loadPlayers(context.read<ApiRouter>());
    setState(() {
      _team = Future.value(team);
      _players = Future.value(players);
    });
  }

  Future<void> _createTeam() async {
    final nameController = TextEditingController();
    final divisionController = TextEditingController();
    final shortNameController = TextEditingController();
    final primaryColorController = TextEditingController();
    final secondaryColorController = TextEditingController();
    final apiRouter = context.read<ApiRouter>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
              ),
              TextField(
                controller: divisionController,
                decoration: const InputDecoration(labelText: 'Division'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: shortNameController,
                decoration: const InputDecoration(labelText: 'Short Name'),
              ),
              TextField(
                controller: primaryColorController,
                decoration: const InputDecoration(labelText: 'Primary Color'),
              ),
              TextField(
                controller: secondaryColorController,
                decoration: const InputDecoration(labelText: 'Secondary Color'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final division = int.tryParse(divisionController.text.trim());
                if (nameController.text.trim().isEmpty || division == null) return;

                final token = context.read<AuthProvider>().user?.access_token ?? '';
                if (token.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("You must be logged in")),
                  );
                  return;
                }

                try {
                  final createdTeam = await apiRouter.fetchData(
                    "user/manager/team",
                    method: 'POST',
                    token: token,
                    body: {
                      'name': nameController.text.trim(),
                      'division': division,
                      'short_name': shortNameController.text.trim().isEmpty
                          ? null
                          : shortNameController.text.trim(),
                      'color_primary': primaryColorController.text.trim().isEmpty
                          ? null
                          : primaryColorController.text.trim(),
                      'color_secondary': secondaryColorController.text.trim().isEmpty
                          ? null
                          : secondaryColorController.text.trim(),
                    },
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _team = createdTeam is Map<String, dynamic>
                        ? Future.value(createdTeam)
                        : _loadTeam(apiRouter);
                    _players = _loadPlayers(apiRouter);
                  });
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Team created")),
                  );
                  return;
                } catch (_) {
                  final team = await _loadTeam(apiRouter);
                  if (!mounted) return;
                  if (team != null) {
                    Navigator.pop(context);
                    setState(() {
                      _team = Future.value(team);
                      _players = _loadPlayers(apiRouter);
                    });
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Team created")),
                    );
                    return;
                  }
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Failed to create team")),
                  );
                  return;
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlayer(int playerId) async {
    try {
      final token = context.read<AuthProvider>().user?.access_token ?? '';
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in")),
        );
        return;
      }
      await context.read<ApiRouter>().fetchData(
        "user/manager/team/players/$playerId",
        method: 'DELETE',
        token: token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player deleted")),
      );
      _refreshPlayers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete player")),
      );
    }
  }

  Future<void> _addPlayer() async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final numberController = TextEditingController();
    final apiRouter = context.read<ApiRouter>();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: 'Shirt Number'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final number = int.tryParse(numberController.text.trim());
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final teamPlayers = await _players;
                if (firstName.isEmpty || lastName.isEmpty) return;
                if (number == null || teamPlayers.any((p) => p.number == number)) return;

                try {
                  final token = context.read<AuthProvider>().user?.access_token ?? '';
                  if (token.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("You must be logged in")),
                    );
                    return;
                  }
                  final teamData = await apiRouter.fetchData(
                    "user/manager/team",
                    token: token,
                  );
                  final teamId = teamData['id'] as int?;
                  if (teamId == null) {
                    throw Exception("Team not found");
                  }
                  await apiRouter.fetchData(
                    "user/manager/team/players",
                    method: 'POST',
                    body: {
                      'first_name': firstName,
                      'last_name': lastName,
                      'number': number.toString(),
                      'team_id': teamId,
                    },
                    token: token,
                  );
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Player added")),
                  );
                  _refreshPlayers();
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Failed to add player")),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Team Roster',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              onPressed: _refreshPlayers,
              child: const Text('Refresh'),
            )
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _team,
          builder: (context, teamSnapshot) {
            if (teamSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (teamSnapshot.hasError) {
              return const Center(child: Text('Error loading team'));
            }
            final team = teamSnapshot.data;
            if (team == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No team yet'),
                    const SizedBox(height: 12),
                    FloatingActionButton.extended(
                      onPressed: _createTeam,
                      label: const Text('Create Team'),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              );
            }
            return FutureBuilder<List<om.Player>>(
              future: _players,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading players'));
                }

                final players = snapshot.data ?? [];

                if (players.isEmpty) {
                  return const Center(child: Text('No players in your team'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshPlayers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return PlayerCard(
                        player: player,
                        onDelete: () => _deletePlayer(player.id),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FutureBuilder<Map<String, dynamic>?>(
          future: _team,
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              onPressed: _addPlayer,
              label: const Text('Add Player'),
              icon: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
