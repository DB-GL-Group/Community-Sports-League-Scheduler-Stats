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
      user = User.fromJson(data);
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

class User {
  int id;
  String email;
  bool is_active;
  DateTime created_at;
  List<String> roles;

  User({
    required this.id,
    required this.email,
    required this.is_active,
    required this.created_at,
    required this.roles
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      is_active: json['is_active'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
      roles: List<String>.from(json['roles'])
    );
  }
}