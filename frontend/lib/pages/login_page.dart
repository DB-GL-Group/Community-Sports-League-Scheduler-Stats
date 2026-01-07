import 'package:community_sports_league_scheduler/router.dart' as api_router;
import 'package:community_sports_league_scheduler/widgets/template.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatelessWidget {

  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Template(
      pageBody: Center(
        child: Column(
          children: [
            const Text('Sign In Page'),
            ElevatedButton(
              onPressed: () async {
                await context.read<api_router.Router>().fetchData('login');
                context.go('/');
              },
              child: const Text('Sign In'))
          ],
        )
      )
    );
  }
  
}
