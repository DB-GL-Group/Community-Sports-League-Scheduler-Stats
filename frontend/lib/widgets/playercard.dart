import 'package:flutter/material.dart';
import '../object_models.dart' as om;

class PlayerCard extends StatelessWidget {
  final om.Player player;
  final VoidCallback onDelete;

  const PlayerCard({super.key, required this.player, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('${player.firstName} ${player.lastName}'),
        subtitle: Text('Shirt Number: ${player.number}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
