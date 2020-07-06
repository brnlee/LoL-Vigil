// To parse this JSON data, do
//
//     final schedule = scheduleFromJson(jsonString);

import 'dart:convert';
import 'package:lolvigilmobile/services/webservice.dart';
import 'package:lolvigilmobile/utils/constants.dart';

Schedule scheduleFromJson(String str) => Schedule.fromJson(json.decode(str));

String scheduleToJson(Schedule data) => json.encode(data.toJson());

class Alarm {
  Alarm(this.matchID);

  String matchID;
  bool isSet = false;
}

class Schedule {
  Schedule({
    this.events,
    this.hasNextPage,
  });

  List<Event> events;
  bool hasNextPage;

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
        events: List<Event>.from(json["events"].map((x) => Event.fromJson(x)))
            .where((event) => event != null && event.state != 'completed')
            .toList(),
        hasNextPage: json["pages"]["newer"] != null);
  }

  Map<String, dynamic> toJson() => {
        "events": List<dynamic>.from(events.map((x) => x.toJson())),
      };

  static Resource<Schedule> get(int page) {
    return Resource(
        url: '${Constants.GET_SCHEDULE_URL}?page=$page',
        parse: (response) {
          final result = json.decode(response.body);
          return Schedule.fromJson(result);
        });
  }
}

class Event {
  Event({
    this.startTime,
    this.state,
    this.type,
    this.blockName,
    this.tournament,
    this.match,
  });

  DateTime startTime;
  String state;
  String type;
  String blockName;
  Tournament tournament;
  Match match;

  factory Event.fromJson(Map<String, dynamic> json) => json["type"] != "show"
      ? Event(
          startTime: DateTime.parse(json["startTime"]),
          state: json["state"],
          type: json["type"],
          blockName: json["blockName"],
          tournament: Tournament.fromJson(json["league"]),
          match: Match.fromJson(json["match"]),
        )
      : null;

  Map<String, dynamic> toJson() => {
        "startTime": startTime.toIso8601String(),
        "state": state,
        "type": type,
        "blockName": blockName,
        "league": tournament.toJson(),
        "match": match.toJson(),
      };
}

class Tournament {
  Tournament({
    this.name,
    this.slug,
  });

  String name;
  String slug;

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        name: json["name"],
        slug: json["slug"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "slug": slug,
      };
}

class Match {
  Match({
    this.id,
    this.flags,
    this.teams,
    this.strategy,
  });

  String id;
  List<dynamic> flags;
  List<Team> teams;
  Strategy strategy;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json["id"],
        flags: List<dynamic>.from(json["flags"].map((x) => x)),
        teams: List<Team>.from(json["teams"].map((x) => Team.fromJson(x))),
        strategy: Strategy.fromJson(json["strategy"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "flags": List<dynamic>.from(flags.map((x) => x)),
        "teams": List<dynamic>.from(teams.map((x) => x.toJson())),
        "strategy": strategy.toJson(),
      };
}

class Strategy {
  Strategy({
    this.type,
    this.count,
  });

  String type;
  int count;

  factory Strategy.fromJson(Map<String, dynamic> json) => Strategy(
        type: json["type"],
        count: json["count"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "count": count,
      };
}

class Team {
  Team({
    this.name,
    this.code,
    this.image,
    this.result,
    this.record,
  });

  String name;
  String code;
  String image;
  Result result;
  Record record;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        name: json["name"],
        code: json["code"],
        image: json["image"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
        record: json["record"] == null ? null : Record.fromJson(json["record"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "code": code,
        "image": image,
        "result": result == null ? null : result.toJson(),
        "record": record == null ? null : record.toJson(),
      };
}

class Record {
  Record({
    this.wins,
    this.losses,
  });

  int wins;
  int losses;

  factory Record.fromJson(Map<String, dynamic> json) => Record(
        wins: json["wins"],
        losses: json["losses"],
      );

  Map<String, dynamic> toJson() => {
        "wins": wins,
        "losses": losses,
      };
}

class Result {
  Result({
    this.outcome,
    this.gameWins,
  });

  dynamic outcome;
  int gameWins;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        outcome: json["outcome"],
        gameWins: json["gameWins"],
      );

  Map<String, dynamic> toJson() => {
        "outcome": outcome,
        "gameWins": gameWins,
      };
}
