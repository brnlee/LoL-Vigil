class Message {
  Message({
    this.trigger,
    this.matchup,
  });

  String trigger;
  String matchup;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    trigger: json["trigger"],
    matchup: json["matchup"],
  );

  Map<String, dynamic> toJson() => {
    "trigger": trigger,
    "matchup": matchup,
  };
}