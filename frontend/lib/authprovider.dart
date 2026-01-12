import 'package:community_sports_league_scheduler/object_models.dart';
import 'package:community_sports_league_scheduler/router.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => user != null;
  bool hasRole(String role) => (user != null && user!.roles.contains(role.toUpperCase()));

  Future<void> login(ApiRouter apiRouter, String access_token) async {
    if (user != null) return;

    isLoading = true;
    notifyListeners();

    try {
      final data = await apiRouter.fetchData("auth/me", token: access_token);
      user = User.fromJson(data, access_token);
    } catch (e) {
      throw Exception("Error loading user: $e");
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