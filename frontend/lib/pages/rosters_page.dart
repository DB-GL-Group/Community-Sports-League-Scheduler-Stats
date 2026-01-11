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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _players = _loadPlayers(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<om.Player>> _loadPlayers(ApiRouter apiRouter) async {
    // List<om.Player> players = [];
    // try {
    //   final data = await apiRouter.fetchData("manager/team/players");
    //   for (var playerJson in data['body']) {
    //     players.add(om.Player.fromJson(playerJson));
    //   }
    // } catch (e) {
    //   print("Error loading players: $e");
    // } finally {
    //   return players;
    // }
    return [
      om.Player(id: 1, firstName: "Anthony", lastName: "Racioppi", number: 1),
      om.Player(id: 2, firstName: "Rillind", lastName: "Nivokazi", number: 33)
    ];
  }

  Future<List<om.Player>> _loadFreePlayers(ApiRouter apiRouter) async {
    // List<om.Player> players = [];
    // try {
    //   final data = await apiRouter.fetchData("players/available");
    //   for (var playerJson in data['body']) {
    //     players.add(om.Player.fromJson(playerJson));
    //   }
    // } catch (e) {
    //   print("Error loading players: $e");
    // } finally {
    //   return players;
    // }
    return [
      om.Player(id: 3, firstName: "Gabriel", lastName: "Schönmann", number: null),
      om.Player(id: 4, firstName: "Alex", lastName: "Hall", number: null),
      om.Player(id: 4, firstName: "James", lastName: "Zeiger", number: null),
    ];
  }

  Future<void> _refreshPlayers() async {
    final players = await _loadPlayers(context.read<ApiRouter>());
    setState(() {
      _players = Future.value(players);
    });
  }

  Future<void> _deletePlayer(int playerId) async {
    try {
      await context.read<ApiRouter>().fetchData(
        "manager/team/players/$playerId",
        method: 'DELETE',
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
    final TextEditingController numberController = TextEditingController();
    int? selectedPlayerId;
    late Future<List<om.Player>> _freePlayers;
    _freePlayers = _loadFreePlayers(context.read<ApiRouter>());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<om.Player>>(
                future: _freePlayers,
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

                  return DropdownButton<int>(
                    value: selectedPlayerId ?? players.first.id,
                    items: [for (var p in players) DropdownMenuItem<int>(value: p.id, child: Text('${p.firstName} ${p.lastName}'))],
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      selectedPlayerId = newValue;
                    },
                  );
                }
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

                final team_players = await _players;

                if (selectedPlayerId == null || number == null || team_players.any((p) => p.number == number)) return;

                try {
                  await context.read<ApiRouter>().fetchData(
                    "manager/team/players",
                    method: 'POST',
                    body: {
                      'player_id': selectedPlayerId!,
                      // number should be in request
                      // 'number': number,
                    },
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Player added")),
                  );
                  _refreshPlayers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
        body: FutureBuilder<List<om.Player>>(
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPlayer,
          label: const Text('Add Player'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
