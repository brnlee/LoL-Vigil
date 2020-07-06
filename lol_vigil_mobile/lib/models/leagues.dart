import 'dart:convert';

import 'package:lolvigilmobile/services/webservice.dart';
import 'package:lolvigilmobile/utils/constants.dart';

LeaguesResponse leaguesResponseFromJson(String str) =>
    LeaguesResponse.fromJson(json.decode(str));

String leaguesResponseToJson(LeaguesResponse data) =>
    json.encode(data.toJson());

class LeaguesResponse {
  LeaguesResponse({
    this.leagues,
  });

  List<League> leagues;

  factory LeaguesResponse.fromJson(Map<String, dynamic> json) {
    List<League> _leagues = List<League>.from(
        json["leagues"].map((x) => League.fromJson(x)));
    _leagues.sort((a, b) => a.priority.compareTo(b.priority));
    return LeaguesResponse(
      leagues: _leagues
    );
  }

  Map<String, dynamic> toJson() => {
        "leagues": List<dynamic>.from(leagues.map((x) => x.toJson())),
      };

  static Resource<List<League>> get all {
    return Resource(
        url: '${Constants.GET_LEAGUES_URL}',
        parse: (response) {
          final result = json.decode(response.body);
          return LeaguesResponse.fromJson(result).leagues;
        });
  }
}

class League {
  League({
    this.id,
    this.slug,
    this.name,
    this.region,
    this.image,
    this.priority,
  });

  String id;
  String slug;
  String name;
  String region;
  String image;
  int priority;

  factory League.fromJson(Map<String, dynamic> json) => League(
        id: json["id"],
        slug: json["slug"],
        name: json["name"],
        region: json["region"],
        image: json["image"],
        priority: json["priority"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "slug": slug,
        "name": name,
        "region": region,
        "image": image,
        "priority": priority,
      };
}
