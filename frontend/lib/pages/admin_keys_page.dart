import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminKeysPage extends StatefulWidget {
  const AdminKeysPage({super.key});

  @override
  State<AdminKeysPage> createState() => _AdminKeysPageState();
}

class _AdminKeysPageState extends State<AdminKeysPage> {
  String _selectedRole = 'MANAGER';
  String _generatedKey = '';
  String _message = '';
  bool _isLocked = false;

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Center(
        child: Column(
          children: [
            const Text(
              'Admin Role Keys',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 400,
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                  DropdownMenuItem(value: 'REFEREE', child: Text('Referee')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedRole = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Role',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLocked
                  ? null
                  : () async {
                      final token = context.read<AuthProvider>().user?.access_token ?? '';
                      if (token.isEmpty) {
                        setState(() {
                          _message = 'You must be logged in';
                        });
                        return;
                      }
                      setState(() {
                        _isLocked = true;
                        _message = 'Generating key...';
                      });
                      try {
                        final data = await context.read<ApiRouter>().fetchData(
                          'user/admin/role-keys',
                          method: 'POST',
                          token: token,
                          body: {'role': _selectedRole},
                        );
                        setState(() {
                          _generatedKey = data['key'] as String? ?? '';
                          _message = _generatedKey.isEmpty ? 'No key returned' : 'Key generated';
                        });
                      } catch (_) {
                        setState(() {
                          _message = 'Failed to generate key';
                        });
                      } finally {
                        setState(() {
                          _isLocked = false;
                        });
                      }
                    },
              child: const Text('Generate Key'),
            ),
            const SizedBox(height: 20),
            if (_generatedKey.isNotEmpty)
              SizedBox(
                width: 400,
                child: SelectableText(
                  _generatedKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 10),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
