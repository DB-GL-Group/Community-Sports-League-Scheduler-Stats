class User {
  int id;
  String email;
  bool is_active;
  DateTime created_at;
  List<String> roles;
  int person_id;
  String first_name;
  String last_name;
  String access_token;

  User({
    required this.id,
    required this.email,
    required this.is_active,
    required this.created_at,
    required this.roles,
    required this.person_id,
    required this.first_name,
    required this.last_name,
    required this.access_token
  });

  factory User.fromJson(Map<String, dynamic> json, String access_token) {
    return User(
      id: json['user']['id'] as int,
      email: json['user']['email'] as String,
      is_active: json['user']['is_active'] as bool,
      created_at: DateTime.parse(json['user']['created_at'] as String),
      roles: List<String>.from(json['user']['roles']),
      person_id: json['person']['id'] as int,
      first_name: json['person']['first_name'] as String,
      last_name: json['person']['last_name'] as String,
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
      divisionName: json['division'].toString(),
      homeTeam: Team(
        name: json['home_team'],
        primaryColor: json['home_primary_color'],
        secondaryColor: json['home_secondary_color']
      ),
      awayTeam: Team(
        name: json['away_team'],
        primaryColor: json['away_primary_color'],
        secondaryColor: json['away_secondary_color']
      ),
      status: json['status'] as String,
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
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

  // factory Team.fromJson(Map<String, dynamic> json) {
  //   return Team(
  //     name: json['name'] as String,
  //     primaryColor: json['color_primary'] as String,
  //     secondaryColor: json['color_secondary'] as String,
  //   );
  // }
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


class Player {
  final int id;
  final String firstName;
  final String lastName;
  final int? number;

  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.number,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      number: json['number'] ? json['number'] as int : null,
    );
  }
}