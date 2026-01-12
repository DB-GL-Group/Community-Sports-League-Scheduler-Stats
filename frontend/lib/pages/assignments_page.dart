import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:community_sports_league_scheduler/widgets/refmatchcard.dart';
import 'package:community_sports_league_scheduler/widgets/template.dart';
import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  late Future<List<om.RefMatch>> _refMatches;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _refMatches = _loadRefMatches(context.read<ApiRouter>());
      _initialized = true;
    }
  }

  Future<List<om.RefMatch>> _loadRefMatches(ApiRouter apiRouter) async {
    List<om.RefMatch> matches = [];
    try {
      final token = context.read<AuthProvider>().user?.access_token ?? '';
      final matchesData = await apiRouter.fetchData("user/referee/matches", token: token);
      for (var matchJson in matchesData) {
        matches.add(om.RefMatch.fromJson(matchJson));
      }
    } catch (e) {
      print("Error loading ref matches: $e");
    } finally {
      return Future.value(matches);
    }
  }

  Future<void> _refreshMatches() async {
    final refMatches = await _loadRefMatches(context.read<ApiRouter>());
    setState(() {
      _refMatches = Future.value(refMatches);
    });
  }

  List<om.RefMatch> _sortMatches(List<om.RefMatch> matches) {
    matches.sort((a, b) => a.startTime.compareTo(b.startTime));
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Assignments',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              onPressed: _refreshMatches,
              child: const Text('Refresh'),
            )
          ],
        ),
        body: FutureBuilder<List<om.RefMatch>>(
          future: _refMatches,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading ref matches'),
              );
            }

            final matches = _sortMatches([...snapshot.data!]);

            return RefreshIndicator(
              onRefresh: _refreshMatches,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];

                  return RefMatchCard(
                    match: match,
                    onAccept: () {
                      // update match status in db
                    },
                    onDecline: () {
                      // update match status in db
                    }
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
