import 'package:community_sports_league_scheduler/object_models.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => user != null;
  bool hasRole(String role) => (user != null && user!.roles.contains(role.toUpperCase()));

  void login(User user) {
    this.user = user;
    notifyListeners();
  }

  Future<void> loadUser(ApiRouter apiRouter) async {
    if (user != null) return;

    isLoading = true;
    notifyListeners();

    try {
      final data = await apiRouter.fetchData("auth/me");
      user = User.fromJson(data['user'], data['access_token']);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    user = null;
    notifyListeners();
  }
}