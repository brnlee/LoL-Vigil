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
}
