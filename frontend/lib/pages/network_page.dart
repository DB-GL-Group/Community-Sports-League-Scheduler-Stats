import 'package:community_sports_league_scheduler/network_provider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final TextEditingController _controller = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final network = context.read<NetworkProvider>();
      final api = context.read<ApiRouter>();
      final current = network.baseUrl.isNotEmpty
          ? network.baseUrl
          : api.getBaseUrl();
      _controller.text = current;
      _initialized = true;
    }
  }

  Future<void> _connect() async {
    final network = context.read<NetworkProvider>();
    final api = context.read<ApiRouter>();
    final ok = await network.connect(api, _controller.text);
    if (ok && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Network setup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the backend address to continue.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'http://192.168.1.42:8000',
                  ),
                ),
                const SizedBox(height: 12),
                if (network.error != null) ...[
                  Text(
                    network.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton(
                  onPressed: network.isChecking ? null : _connect,
                  child: Text(network.isChecking ? 'Checking...' : 'Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
