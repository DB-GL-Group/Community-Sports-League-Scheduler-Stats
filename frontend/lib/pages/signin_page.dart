import 'package:community_sports_league_scheduler/authprovider.dart';
import 'package:community_sports_league_scheduler/object_classes.dart';
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
              onPressed: () {
                final user = User.create(
                  'Gabriel',
                  'Schönmann',
                  'schonmann.gabriel@gmail.com',
                  ['manager', 'referee']
                );
                // when login succeeds, we update the auth user
                context.read<AuthProvider>().signIn(user);
                context.go('/');
              },
              child: const Text('Sign In'))
          ],
        )
      )
    );
  }
  
}
