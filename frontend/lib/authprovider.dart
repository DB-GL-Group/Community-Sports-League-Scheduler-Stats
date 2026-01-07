import 'package:community_sports_league_scheduler/object_classes.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User _user = User();

  User get user => _user;
  bool get isLoggedIn => !_user.anonymous;
  bool hasRole(String role) => user.roles.contains(role);

  void signIn(User user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    _user = User();
    notifyListeners();
  }
}
