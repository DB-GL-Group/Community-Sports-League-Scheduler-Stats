import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;

class SlotCard extends StatelessWidget {
  final om.Slot slot;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const SlotCard({
    super.key,
    required this.slot,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          enabled: !disabled,
          onTap: disabled ? null : onTap,
          leading: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? Colors.green : null),
          title: Text('${slot.court} — ${DateFormat.Hm().format(slot.startTime)}–${DateFormat.Hm().format(slot.endTime)}'),
          subtitle: Text(DateFormat.yMMMMd().format(slot.startTime)),
          trailing: disabled ? const Tooltip(message: 'Overlaps with another selected slot', child: Icon(Icons.lock)) : null,
        ),
      ),
    );
  }
}
