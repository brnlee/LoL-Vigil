import 'dart:convert';

class Message {
  Message({
    this.matchID,
    this.gameNumber,
    this.trigger,
    this.matchup,
  });

  String matchID;
  String gameNumber;
  String trigger;
  String matchup;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        matchID: json["matchID"],
        gameNumber: json["gameNumber"],
        trigger: json["trigger"],
        matchup: json["matchup"],
      );

  @override
  String toString() {
    return "MatchID: $matchID\tGame#: $gameNumber\tTrigger: $trigger\tMatchup: $matchup";
  }

  static Message parseFcmMessage(Map<String, dynamic> fcmMessage) {
    print(fcmMessage);

    if (fcmMessage.containsKey('data')) {
      dynamic data = fcmMessage['data'];
      try {
        return Message.fromJson(json.decode(data["message"]));
      } catch (e) {
        print("Error parsing FCM Message: $e");
      }
    }

    return null;
  }
}
