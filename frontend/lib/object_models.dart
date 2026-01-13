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
  final int id;
  final String divisionName;
  final Team homeTeam;
  final Team awayTeam;
  final String status;
  final int homeScore;
  final int awayScore;
  final DateTime? startTime;

  Match({
    required this.id,
    required this.divisionName,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.startTime,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final startTimeRaw = json['start_time'];
    return Match(
      id: json['id'] as int,
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
      startTime: startTimeRaw == null ? null : DateTime.parse(startTimeRaw as String),
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
}


class Slot {
  final int id;
  final String venue;
  final DateTime startTime;
  final DateTime endTime;
  final String match;

  Slot({
    required this.id,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.match
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] as int,
      venue: json['venue'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      match: json['match'] as String
    );
  }
}


class RefMatch {
  final int id;
  final int division;
  final String status;
  final String home_team;
  final String away_team;
  final DateTime startTime;
  final DateTime endTime;
  final String venue;

  RefMatch({
    required this.id,
    required this.division,
    required this.status,
    required this.home_team,
    required this.away_team,
    required this.startTime,
    required this.endTime,
    required this.venue,
  });

  factory RefMatch.fromJson(Map<String, dynamic> json) {
    return RefMatch(
      id: json['id'] as int,
      division: json['division'] as int,
      status: json['status'] as String,
      home_team: json['home_team'] as String,
      away_team: json['away_team'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      venue: json['venue'] as String,
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
    final numberValue = json['number'];
    return Player(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? json['firstName'] ?? '') as String,
      lastName: (json['last_name'] ?? json['lastName'] ?? '') as String,
      number: numberValue is int ? numberValue : int.tryParse(numberValue?.toString() ?? ''),
    );
  }
}


class MatchDetail {
  final int id;
  final int division;
  final String status;
  final TeamDetail homeTeam;
  final TeamDetail awayTeam;
  final int homeScore;
  final int awayScore;
  final DateTime? startTime;
  final DateTime currentTime;
  final String mainReferee;
  final String? notes;
  final String? venue;

  MatchDetail({
    required this.id,
    required this.division,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.startTime,
    required this.currentTime,
    required this.mainReferee,
    this.notes,
    required this.venue,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    final startTimeRaw = json['start_time'];
    return MatchDetail(
      id: json['id'] as int,
      division: json['division'] as int,
      status: json['status'] as String,
      homeTeam: TeamDetail.fromJson(json['home_team']),
      awayTeam: TeamDetail.fromJson(json['away_team']),
      homeScore: json['home_score'] as int,
      awayScore: json['away_score'] as int,
      startTime: startTimeRaw == null ? null : DateTime.parse(startTimeRaw as String),
      currentTime: DateTime.parse(json['current_time'] as String),
      mainReferee: (json['main_referee'] ?? '') as String,
      notes: json['notes'] as String?,
      venue: json['venue'] as String?,
    );
  }
}


class TeamDetail {
  final int id;
  final int division;
  final String name;
  final int? managerId;
  final String? shortName;
  final String? primaryColor;
  final String? secondaryColor;
  final List<Player> players;

  TeamDetail({
    required this.id,
    required this.division,
    required this.name,
    required this.managerId,
    required this.shortName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.players,
  });

  factory TeamDetail.fromJson(Map<String, dynamic> json) {
    return TeamDetail(
      id: json['id'] as int,
      division: json['division'] as int,
      name: json['name'] as String,
      managerId: json['manager_id'] as int?,
      shortName: json['short_name'] as String?,
      primaryColor: json['color_primary'] as String?,
      secondaryColor: json['color_secondary'] as String?,
      players: (json['players'] as List? ?? []).map((p) => Player.fromJson(p)).toList(),
    );
  }
}


class RankingEntry {
  final int rank;
  final String team_name;
  final String team_primary_color;
  final String team_secondary_color;
  final int points;
  final int goal_difference;

  RankingEntry({
    required this.rank,
    required this.team_name,
    required this.team_primary_color,
    required this.team_secondary_color,
    required this.points,
    required this.goal_difference,
  });

  factory RankingEntry.fromJson(int rank, Map<String, dynamic> json) {
    return RankingEntry(
      rank: rank,
      team_name: json['team_name'] as String,
      team_primary_color: json['team_primary_color'] as String,
      team_secondary_color: json['team_secondary_color'] as String,
      points: json['points'] as int,
      goal_difference: json['goal_difference'] as int,
    );
  }
}
