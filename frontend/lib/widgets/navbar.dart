import 'package:community_sports_league_scheduler/authprovider.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    List<Widget> navbarElements = [
      UserAccountsDrawerHeader(
        accountName: Text(auth.isLoggedIn ? 'Unknown' : 'Anonymous'),
        accountEmail: Text(auth.isLoggedIn ? auth.user!.email : ''),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 50, 50, 50)
        ),
      ),
      ListTile(
        leading: Icon(Icons.sports_soccer),
        title: Text('Matches'),
        onTap: () => context.go('/'),
      ),
      ListTile(
        leading: Icon(Icons.view_list_rounded),
        title: Text('Rankings'),
        onTap: () => context.go('/rankings'),
      ),
      ListTile(
        leading: Icon(Icons.analytics_outlined),
        title: Text('Stats'),
        onTap: () => context.go('/stats'),
      )
    ];

    // Manager
    if (auth.hasRole('MANAGER')) {
      navbarElements.addAll([
        Divider(),
        ListTile(
          title: Text('Manager', style: TextStyle(fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.only(left: 8),
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Rosters'),
          onTap: () => context.go('/rosters'),
        ),
        ListTile(
          leading: Icon(Icons.send_outlined),
          title: Text('Requests'),
          onTap: () => context.go('/requests'),
        )
      ]);
    }

    // Referee
    if (auth.hasRole('REFEREE')) {
      navbarElements.addAll([
        Divider(),
        ListTile(
          title: Text('Referee', style: TextStyle(fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.only(left: 8),
        ),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Assignments'),
          trailing: Text('2'),
          onTap: () => context.go('/assignments'),
        ),
        ListTile(
          leading: Icon(Icons.calendar_month),
          title: Text('Availabilities'),
          onTap: () => context.go('/availabilities'),
        )
      ]);
    }

    // Admin
    if (auth.hasRole('ADMIN')) {
      navbarElements.addAll([
        Divider(),
        ListTile(
          title: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          contentPadding: EdgeInsets.only(left: 8),
        ),
        ListTile(
          leading: Icon(Icons.vpn_key),
          title: Text('Role Keys'),
          onTap: () => context.go('/admin/role-keys'),
        ),
      ]);
    }

    // Sign in / Sign out
    if (!auth.isLoggedIn) {
      navbarElements.addAll([
        Divider(),
        ListTile(
          leading: Icon(Icons.login),
          title: Text('Log in'),
          onTap: () => context.go('/login'),
        ),
        ListTile(
          leading: Icon(Icons.person_add),
          title: Text('Sign up'),
          onTap: () => context.go('/signup'),
        )
      ]);
    } else {
      navbarElements.addAll([
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Sign out'),
          onTap: () {
            auth.signOut();
            context.go('/');
          },
        )
      ]);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: navbarElements
      ),
    );
  }
}
