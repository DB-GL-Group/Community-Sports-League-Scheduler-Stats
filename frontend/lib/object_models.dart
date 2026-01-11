class User {
  int id;
  String email;
  bool is_active;
  DateTime created_at;
  List<String> roles;
  String access_token;

  User({
    required this.id,
    required this.email,
    required this.is_active,
    required this.created_at,
    required this.roles,
    required this.access_token
  });

  factory User.fromJson(Map<String, dynamic> json, String access_token) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      is_active: json['is_active'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
      roles: List<String>.from(json['roles']),
      access_token: access_token
    );
  }
}


class Match {
  final String divisionName;
  final Team homeTeam;
  final Team awayTeam;
  final String status;
  final int homeScore;
  final int awayScore;
  final DateTime startTime;

  Match({
    required this.divisionName,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.startTime,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      divisionName: json['division_name'] as String,
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),
      status: json['status'] as String,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      startTime: DateTime.parse(json['slot_start_time'] as String),
    );
  }
}


class Team {
  final String name;
  final String primaryColor;
  final String secondaryColor;

  Team({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] as String,
      primaryColor: json['color_primary'] as String,
      secondaryColor: json['color_secondary'] as String,
    );
  }
}


class Slot {
  final int id;
  final String court;
  final DateTime startTime;
  final DateTime endTime;

  Slot({
    required this.id,
    required this.court,
    required this.startTime,
    required this.endTime,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] as int,
      court: json['court'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );
  }
}
