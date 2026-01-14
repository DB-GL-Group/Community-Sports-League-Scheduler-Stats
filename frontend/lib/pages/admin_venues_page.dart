import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminVenuesPage extends StatefulWidget {
  const AdminVenuesPage({super.key});

  @override
  State<AdminVenuesPage> createState() => _AdminVenuesPageState();
}

class _AdminVenuesPageState extends State<AdminVenuesPage> {
  late Future<List<Map<String, dynamic>>> _venuesFuture;
  bool _initialized = false;
  String _message = '';
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  int? _editingVenueId;
  int _courtsCount = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _venuesFuture = _loadVenues();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadVenues() async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return [];
    try {
      final data = await context.read<ApiRouter>().fetchData(
        'user/admin/venues',
        token: token,
      );
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _refresh() async {
    final venues = await _loadVenues();
    setState(() {
      _venuesFuture = Future.value(venues);
    });
  }

  Future<void> _addVenue() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _message = _editingVenueId == null ? 'Creating venue...' : 'Updating venue...';
    });
    try {
      if (_editingVenueId == null) {
        await context.read<ApiRouter>().fetchData(
          'user/admin/venues',
          method: 'POST',
          token: token,
          body: {
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'courts_count': _courtsCount,
          },
        );
      } else {
        await context.read<ApiRouter>().fetchData(
          'user/admin/venues/$_editingVenueId',
          method: 'PUT',
          token: token,
          body: {
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'courts_count': _courtsCount,
          },
        );
      }
      _nameController.clear();
      _addressController.clear();
      _courtsCount = 1;
      _editingVenueId = null;
      await _refresh();
      setState(() {
        _message = 'Venue saved.';
      });
    } catch (_) {
      setState(() {
        _message = 'Failed to save venue.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteVenue(int venueId) async {
    if (_isSubmitting) return;
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _message = 'Deleting venue...';
    });
    try {
      await context.read<ApiRouter>().fetchData(
        'user/admin/venues/$venueId',
        method: 'DELETE',
        token: token,
      );
      if (_editingVenueId == venueId) {
        _editingVenueId = null;
        _nameController.clear();
        _addressController.clear();
      }
      await _refresh();
      setState(() {
        _message = 'Venue deleted.';
      });
    } catch (_) {
      setState(() {
        _message = 'Failed to delete venue.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> venue) async {
    final token = context.read<AuthProvider>().user?.access_token ?? '';
    if (token.isEmpty) return;
    List<Map<String, dynamic>> matches = [];
    try {
      final data = await context.read<ApiRouter>().fetchData(
        'user/admin/venues/${venue['id']}/matches',
        token: token,
      );
      if (data is List) {
        matches = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete venue'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will cancel ${matches.length} match(es) linked to this venue.',
                ),
                const SizedBox(height: 8),
                if (matches.isEmpty)
                  const Text('No matches will be affected.'),
                if (matches.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        final start = match['start_time']?.toString() ?? 'TBD';
                        return ListTile(
                          dense: true,
                          title: Text('${match['home_team']} vs ${match['away_team']}'),
                          subtitle: Text(start),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await _deleteVenue(venue['id'] as int);
    }
  }

  void _startEdit(Map<String, dynamic> venue) {
    setState(() {
      _editingVenueId = venue['id'] as int?;
      _nameController.text = venue['name']?.toString() ?? '';
      _addressController.text = venue['address']?.toString() ?? '';
      _courtsCount = (venue['courts_count'] as int?) ?? 1;
      _message = 'Editing venue...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Venues', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _venuesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final venues = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Add venue',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(labelText: 'Address (optional)'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _courtsCount,
                            decoration: const InputDecoration(labelText: 'Courts'),
                            items: List.generate(12, (index) {
                              final value = index + 1;
                              return DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              );
                            }),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _courtsCount = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _addVenue,
                            child: Text(_editingVenueId == null ? 'Create' : 'Save'),
                          ),
                          if (_editingVenueId != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _editingVenueId = null;
                                        _nameController.clear();
                                        _addressController.clear();
                                        _courtsCount = 1;
                                        _message = '';
                                      });
                                    },
                              child: const Text('Cancel'),
                            ),
                          ],
                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _message,
                              style: TextStyle(
                                color: _message.startsWith('Failed')
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (venues.isEmpty)
                    const Center(child: Text('No venues yet')),
                  ...venues.map((venue) {
                    final address = (venue['address'] ?? '').toString();
                    final courtsCount = venue['courts_count'] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  venue['name']?.toString() ?? 'Unnamed',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isSubmitting ? null : () => _startEdit(venue),
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _confirmDelete(venue),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              address,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Courts: $courtsCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
