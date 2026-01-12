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
  final List<Map<String, String>> _colorOptions = const [
    {"name": "Red", "value": "#D32F2F"},
    {"name": "Blue", "value": "#1976D2"},
    {"name": "Green", "value": "#388E3C"},
    {"name": "Yellow", "value": "#FBC02D"},
    {"name": "Orange", "value": "#F57C00"},
    {"name": "Purple", "value": "#7B1FA2"},
    {"name": "Black", "value": "#212121"},
    {"name": "White", "value": "#FFFFFF"},
    {"name": "Gray", "value": "#616161"},
  ];

  Color _hexToColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

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

  Future<List<om.Player>> _loadFreePlayers(ApiRouter apiRouter) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return [];
    try {
      final data = await apiRouter.fetchData(
        "user/manager/team/players/available",
        token: token,
      );
      final rows = data is List ? data : [];
      return rows.map<om.Player>((row) {
        final map = row as Map<String, dynamic>;
        return om.Player(
          id: map['id'] as int,
          firstName: (map['first_name'] ?? map['firstName']) as String,
          lastName: (map['last_name'] ?? map['lastName']) as String,
          number: null,
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
    final apiRouter = context.read<ApiRouter>();
    final messenger = ScaffoldMessenger.of(context);
    String primaryColorValue = '';
    String secondaryColorValue = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  DropdownButtonFormField<String>(
                    value: primaryColorValue,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      for (final color in _colorOptions)
                        DropdownMenuItem<String>(
                          value: color['value'],
                          child: Text('${color['name']} (${color['value']})'),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        primaryColorValue = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Primary Color',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: secondaryColorValue,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      for (final color in _colorOptions)
                        DropdownMenuItem<String>(
                          value: color['value'],
                          child: Text('${color['name']} (${color['value']})'),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        secondaryColorValue = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Secondary Color',
                    ),
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
                          'color_primary': primaryColorValue.isEmpty ? null : primaryColorValue,
                          'color_secondary': secondaryColorValue.isEmpty ? null : secondaryColorValue,
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
      },
    );
  }

  Future<void> _editTeam(Map<String, dynamic> team) async {
    final nameController = TextEditingController(text: team['name']?.toString() ?? '');
    final divisionController = TextEditingController(text: team['division']?.toString() ?? '');
    final shortNameController = TextEditingController(text: team['short_name']?.toString() ?? '');
    final apiRouter = context.read<ApiRouter>();
    final messenger = ScaffoldMessenger.of(context);
    String primaryColorValue = team['color_primary']?.toString() ?? '';
    String secondaryColorValue = team['color_secondary']?.toString() ?? '';
    final colorValues = _colorOptions.map((c) => c['value']).whereType<String>().toSet();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Team'),
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
                  DropdownButtonFormField<String>(
                    value: primaryColorValue,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      if (primaryColorValue.isNotEmpty && !colorValues.contains(primaryColorValue))
                        DropdownMenuItem<String>(
                          value: primaryColorValue,
                          child: const Text('Current color'),
                        ),
                      for (final color in _colorOptions)
                        DropdownMenuItem<String>(
                          value: color['value'],
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _hexToColor(color['value']!),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${color['name']}'),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        primaryColorValue = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Primary Color',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: secondaryColorValue,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      if (secondaryColorValue.isNotEmpty && !colorValues.contains(secondaryColorValue))
                        DropdownMenuItem<String>(
                          value: secondaryColorValue,
                          child: const Text('Current color'),
                        ),
                      for (final color in _colorOptions)
                        DropdownMenuItem<String>(
                          value: color['value'],
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _hexToColor(color['value']!),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${color['name']}'),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        secondaryColorValue = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Secondary Color',
                    ),
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
                      final updatedTeam = await apiRouter.fetchData(
                        "user/manager/team",
                        method: 'PUT',
                        token: token,
                        body: {
                          'name': nameController.text.trim(),
                          'division': division,
                          'short_name': shortNameController.text.trim().isEmpty
                              ? null
                              : shortNameController.text.trim(),
                          'color_primary': primaryColorValue.isEmpty ? null : primaryColorValue,
                          'color_secondary': secondaryColorValue.isEmpty ? null : secondaryColorValue,
                        },
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      setState(() {
                        _team = updatedTeam is Map<String, dynamic>
                            ? Future.value(updatedTeam)
                            : _loadTeam(apiRouter);
                        _players = _loadPlayers(apiRouter);
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Team updated")),
                      );
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Failed to update team")),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
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
    final freePlayersFuture = _loadFreePlayers(apiRouter);
    bool useExisting = true;
    int? selectedPlayerId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Player'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Select existing player'),
                    value: true,
                    groupValue: useExisting,
                    onChanged: (value) {
                      setDialogState(() {
                        useExisting = value ?? true;
                      });
                    },
                  ),
                  if (useExisting)
                    FutureBuilder<List<om.Player>>(
                      future: freePlayersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error loading players'));
                        }
                        final players = snapshot.data ?? [];
                        if (players.isEmpty) {
                          return const Text('No available players');
                        }
                        selectedPlayerId ??= players.first.id;
                        return DropdownButton<int>(
                          value: selectedPlayerId,
                          items: [
                            for (var p in players)
                              DropdownMenuItem<int>(
                                value: p.id,
                                child: Text('${p.firstName} ${p.lastName}'),
                              )
                          ],
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            setDialogState(() {
                              selectedPlayerId = newValue;
                            });
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 10),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Create new player'),
                    value: false,
                    groupValue: useExisting,
                    onChanged: (value) {
                      setDialogState(() {
                        useExisting = value ?? false;
                      });
                    },
                  ),
                  if (!useExisting)
                    Column(
                      children: [
                        TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name'),
                        ),
                        TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                        ),
                      ],
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
                    final teamPlayers = await _players;
                    if (number == null || teamPlayers.any((p) => p.number == number)) return;

                    if (!useExisting) {
                      final firstName = firstNameController.text.trim();
                      final lastName = lastNameController.text.trim();
                      if (firstName.isEmpty || lastName.isEmpty) return;
                    }

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
                      final body = <String, dynamic>{
                        'number': number,
                        'team_id': teamId,
                      };
                      if (useExisting) {
                        body['player_id'] = selectedPlayerId;
                      } else {
                        body['first_name'] = firstNameController.text.trim();
                        body['last_name'] = lastNameController.text.trim();
                      }
                      await apiRouter.fetchData(
                        "user/manager/team/players",
                        method: 'POST',
                        body: body,
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  team['name']?.toString() ?? 'Team',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit team',
                                  onPressed: () => _editTeam(team),
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Division: ${team['division'] ?? '-'}'),
                            if ((team['short_name'] ?? '').toString().isNotEmpty)
                              Text('Short name: ${team['short_name']}'),
                            if ((team['color_primary'] ?? '').toString().isNotEmpty ||
                                (team['color_secondary'] ?? '').toString().isNotEmpty)
                              const Text('Colors:'),
                            if ((team['color_primary'] ?? '').toString().isNotEmpty ||
                                (team['color_secondary'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    if ((team['color_primary'] ?? '').toString().isNotEmpty)
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: _hexToColor(team['color_primary'].toString()),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                      ),
                                    if ((team['color_primary'] ?? '').toString().isNotEmpty)
                                      const SizedBox(width: 8),
                                    if ((team['color_primary'] ?? '').toString().isNotEmpty)
                                      const Text('Primary'),
                                    if ((team['color_primary'] ?? '').toString().isNotEmpty &&
                                        (team['color_secondary'] ?? '').toString().isNotEmpty)
                                      const SizedBox(width: 16),
                                    if ((team['color_secondary'] ?? '').toString().isNotEmpty)
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: _hexToColor(team['color_secondary'].toString()),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                      ),
                                    if ((team['color_secondary'] ?? '').toString().isNotEmpty)
                                      const SizedBox(width: 8),
                                    if ((team['color_secondary'] ?? '').toString().isNotEmpty)
                                      const Text('Secondary'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: players.isEmpty
                          ? const Center(child: Text('No players in your team'))
                          : RefreshIndicator(
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
                            ),
                    ),
                  ],
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
