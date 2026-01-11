import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/slotcard.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<StatefulWidget> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  late Future<List<om.Slot>> _slots;
  bool _initialized = false;
  final Set<int> _selectedSlotIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _slots = _loadSlotsAndAvailability(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<om.Slot>> _loadSlotsAndAvailability(ApiRouter apiRouter) async {
    // List<om.Slot> slots = [];
    // List<om.Slot> existing = [];
    // try {
    //   final slotData = await apiRouter.fetchData("slots/available");
    //   final availabilityData = await apiRouter.fetchData("user/referee/availability");
    //   for (var slotJson in slotData['body']) {
    //     slots.add(om.Slot.fromJson(slotJson));
    //   }
    //   for (var slotJson in availabilityData['body']) {
    //     final slot = om.Slot.fromJson(slotJson);
    //     existing.add(slot);
    //     _selectedSlotIds.add(slot.id); // pre-select
    //   }
    // } catch (e) {
    //   print("Error loading slots: $e");
    // } finally {
    //   return Future.value([...slots, ...existing]);
    // }
    _selectedSlotIds.add(2);
    return [
      om.Slot(id: 1, court: "Stade de Tourbillon", startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-07T20:00:00.356518Z')),
      om.Slot(id: 2, court: "Stade de la Tuilière", startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-07T20:00:00.356518Z')),
      om.Slot(id: 3, court: "Stockhorn Arena", startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-06T20:00:00.356518Z')),
      om.Slot(id: 4, court: "Stadion Letzigrund", startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-06T20:00:00.356518Z')),
      om.Slot(id: 5, court: "Kybunpark", startTime: DateTime.parse('2025-12-06T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-06T20:00:00.356518Z')),
      om.Slot(id: 6, court: "Schützenwiese", startTime: DateTime.parse('2025-12-07T18:00:00.356518Z'), endTime: DateTime.parse('2025-12-07T20:00:00.356518Z')),
    ];
  }

  Future<void> _refreshSlots() async {
    final slots = await _loadSlotsAndAvailability(context.read<ApiRouter>());
    setState(() {
      _slots = Future.value(slots);
      _selectedSlotIds.clear(); // optional UX choice
    });
  }

  bool _overlaps(om.Slot a, om.Slot b) => a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);

  bool _isSelected(om.Slot slot) =>
      _selectedSlotIds.contains(slot.id);

  bool _isDisabled(om.Slot slot, List<om.Slot> allSlots) {
    return allSlots.any((selected) {
      if (!_isSelected(selected)) return false;
      return _overlaps(slot, selected);
    });
  }

  void _toggleSlot(om.Slot slot) {
    setState(() {
      if (_isSelected(slot)) {
        _selectedSlotIds.remove(slot.id);
      } else {
        _selectedSlotIds.add(slot.id);
      }
    });
  }

  List<om.Slot> _sortSlots(List<om.Slot> slots) {
    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Availability',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              onPressed: _refreshSlots,
              child: const Text('Refresh'),
            )
          ],
        ),
        body: FutureBuilder<List<om.Slot>>(
          future: _slots,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading slots'),
              );
            }

            final slots = _sortSlots([...snapshot.data!]);

            return RefreshIndicator(
              onRefresh: _refreshSlots,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final selected = _isSelected(slot);
                  final disabled = !selected && _isDisabled(slot, slots);

                  return SlotCard(slot: slot, selected: selected, disabled: disabled, onTap: () => _toggleSlot(slot));
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // Send _selectedSlotIds to backend
            // try {
            //   await context.read<ApiRouter>().fetchData(
            //     "user/referee/availability",
            //     method: 'PUT',
            //     body: {"slot_ids": _selectedSlotIds.toList()}
            //   );
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(content: Text("Availability updated")),
            //   );
            // } catch (e) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(content: Text("Failed to update availability")),
            //   );
            // }
          },
          label: const Text('Save'),
          icon: const Icon(Icons.save),
        ),
      ),
    );
  }
}
